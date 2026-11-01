# kids-vote
A simple website for managing a community event, served at https://kids-vote.org.

## Layout
- `web/` — the site itself: plain HTML and CSS, no build step. Its contents are uploaded to S3 as-is.
- `docs/aws-setup.md` — how the AWS infrastructure (S3, CloudFront, ACM, Route 53) was set up by hand.
- `justfile` — project commands.

## Commands
Requires [`just`](https://github.com/casey/just), Node (for `npx`), and the AWS CLI.

- `just serve` — run the site locally at http://localhost:8000 with live reload.
- `just deploy` — upload `web/` to S3 and invalidate the CloudFront cache.
