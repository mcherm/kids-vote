# kids-vote
A simple website for managing a community event, served at https://kids-vote.org.

## Layout
- `web/` — the site itself: plain HTML and CSS, no build step. Its contents are uploaded to S3 as-is.
- `web/doc/` — printable materials (ballots etc.); `2026-ballot.svg` and `2026-save-the-date.svg` are the artwork (the ballot is also shown on the page).
- `print/` — print-layout pages that turn artwork into PDFs for the print shop (not deployed).
- `docs/aws-setup.md` — how the AWS infrastructure (S3, CloudFront, ACM, Route 53) was set up by hand.
- `docs/favicon.md` — what the favicon files are and how to regenerate them from the SVG.
- `justfile` — project commands.

## Commands
Requires [`just`](https://github.com/casey/just), Node (for `npx`), the AWS CLI, and Google Chrome (for PDFs).

- `just serve` — run the site locally at http://localhost:8000 with live reload.
- `just deploy` — upload `web/` to S3 and invalidate the CloudFront cache.
- `just ballot-pdf` — build `print/2026-ballot.pdf` (three ballots per letter page) from `print/ballot-sheet.html`.
- `just save-the-date-pdf` — build `print/2026-save-the-date.pdf` (four cards per letter page) from `print/save-the-date.html`.
