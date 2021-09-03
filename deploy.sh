#!/bin/zsh
set -euo pipefail

branch=$(git symbolic-ref --short -q HEAD)

if [[ $branch != 'master' ]]
then
	echo "not on 'master' - so not deployed"
	exit 1
fi

echo "Deploying Living by the water"

source _cloudfront-distribution-id
# build site
bundle exec jekyll build --config _config.yml,_config_build.yml
mkdir -p _deploy/_admin

# upload to s3
echo "sync content..."
# s3cmd sync --guess-mime-type --no-mime-magic --delete-removed --exclude '.sass-cache' --exclude 's3cfg*' --exclude 'database/*' _deploy/ s3://www.fullofwishes.co.uk
aws s3 sync --size-only --delete --exclude '.sass-cache' _deploy/ s3://www.grange85.co.uk/living-by-the-water/

# update the routing rules
# echo "update routing rules..."
# aws s3api put-bucket-website --bucket www.fullofwishes.co.uk --website-configuration file://config/routing-rules.json

# upload media
echo "uploading media..."
aws s3 sync --size-only --delete --exclude '.sass-cache' /home/andy/repos/grange85-media-cdn/ s3://cdn.grange85.co.uk

# invalidate cloudfront
echo "invalidate cloudfont distribution..."
aws cloudfront create-invalidation --distribution-id $CDN_DISTRIBUTION_ID_WWW --paths "/living-by-the-water/*"
aws cloudfront create-invalidation --distribution-id $CDN_DISTRIBUTION_ID_CDN --paths "/*"

# ping feedburner
curl --write-out 'pinged feedburner\n' --silent --output /dev/null "https://www.feedburner.com/fb/a/pingSubmit?bloglink=https%3A%2F%2Fwww.grange85.co.uk/"


echo "Living by the water successfully deployed."	
