# Command runner for kids-vote. Run `just` to list recipes.

bucket          := "kids-vote.org-402673111584-us-east-1-an"
distribution_id := "E21PWJQQ8T7T6F"
site_dir        := "web"
deploy_profile  := "kids-vote-deploy"    # AWS CLI profile for the kids-vote-deployer IAM user

# List recipes
default:
    @just --list

# Serve web/ locally and reload the browser automatically when a file changes
serve port="8000":
    npx --yes browser-sync start --server {{site_dir}} --files "{{site_dir}}/**/*" --port {{port}} --no-notify

# Upload web/ to S3 and invalidate the CloudFront cache
deploy:
    AWS_PROFILE={{deploy_profile}} aws s3 sync {{site_dir}}/ s3://{{bucket}}/ --delete --exclude ".DS_Store"
    AWS_PROFILE={{deploy_profile}} aws cloudfront create-invalidation --distribution-id {{distribution_id}} --paths "/*"
