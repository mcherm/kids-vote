# Command runner for kids-vote. Run `just` to list recipes.

bucket          := "kids-vote.org-402673111584-us-east-1-an"
distribution_id := "E21PWJQQ8T7T6F"
site_dir        := "web"
chrome          := "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
deploy_profile  := "kids-vote-deploy"    # AWS CLI profile for the kids-vote-deployer IAM user

# List recipes
default:
    @just --list

# Serve web/ locally and reload the browser automatically when a file changes
serve port="8000":
    npx --yes browser-sync start --server {{site_dir}} --files "{{site_dir}}/**/*" --port {{port}} --no-notify

# Make the printable ballot PDF (3 per page) from print/ballot-sheet.html
ballot-pdf:
    "{{chrome}}" --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf=print/2026-ballot.pdf "file://{{justfile_directory()}}/print/ballot-sheet.html"

# Make the printable save-the-date PDF (4 per page) from print/save-the-date.html
save-the-date-pdf:
    "{{chrome}}" --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf=print/2026-save-the-date.pdf "file://{{justfile_directory()}}/print/save-the-date.html"

# Upload web/ to S3 and invalidate the CloudFront cache
deploy:
    AWS_PROFILE={{deploy_profile}} aws s3 sync {{site_dir}}/ s3://{{bucket}}/ --delete --exclude ".DS_Store"
    AWS_PROFILE={{deploy_profile}} aws cloudfront create-invalidation --distribution-id {{distribution_id}} --paths "/*"
