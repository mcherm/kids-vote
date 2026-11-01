# AWS setup for kids-vote.org (one-time, manual)

These steps create the hosting for the static site: a private S3 bucket that only CloudFront can read, served
over HTTPS at `kids-vote.org` and `www.kids-vote.org`. The domain is already registered in Route 53.

Record the IDs you get as you go in the [Resource IDs](#resource-ids) table at the bottom.

## 1. TLS certificate (ACM)

CloudFront only uses certificates from **us-east-1**, so switch the console to that region first.

1. ACM → **Request certificate** → *Request a public certificate*.
2. Domain names: `kids-vote.org` and `www.kids-vote.org`.
3. Validation method: **DNS validation**.
4. When the certificate shows as *Pending validation*, open it and click **Create records in Route 53**. That
   adds the CNAME validation records for you.
5. Wait for the status to change to **Issued**. This usually takes a few minutes.

## 2. S3 bucket

Any region works. us-east-1 is simplest.

1. S3 → **Create bucket**, named `kids-vote.org`.
2. Object Ownership: **ACLs disabled** (the default).
3. **Block all public access**: leave this **on**. CloudFront reads the bucket through Origin Access Control, so
   the bucket never has to be public.
4. Leave *Static website hosting* **off** (it's under Properties). CloudFront serves the files directly.

## 3. CloudFront distribution

1. CloudFront → **Create distribution**.
2. Origin domain: pick the bucket (`kids-vote.org.s3.<region>.amazonaws.com`). Don't use the "website
   endpoint" form.
3. Origin access: **Origin access control settings (recommended)**, then **Create new OAC** with the defaults.
5. Settings:
   - Alternate domain names (CNAMEs): `kids-vote.org` and `www.kids-vote.org`
   - Custom SSL certificate: the certificate from step 1
   - Default root object: `index.html`
   - Price class: *Use only North America and Europe* is the cheapest option and fine for this site
7. Create the distribution. A banner will offer a bucket policy. Click **Copy policy**, then go to S3 →
   `kids-vote.org` → Permissions → **Bucket policy** and paste it. It looks like this:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowCloudFrontServicePrincipal",
         "Effect": "Allow",
         "Principal": { "Service": "cloudfront.amazonaws.com" },
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::kids-vote.org/*",
         "Condition": {
           "StringEquals": {
             "AWS:SourceArn": "arn:aws:cloudfront::<ACCOUNT_ID>:distribution/<DISTRIBUTION_ID>"
           }
         }
       }
     ]
   }
   ```

8. Distribution → **Error pages** → create two custom error responses:

   | HTTP error code | Response page path | HTTP response code |
   |-----------------|--------------------|--------------------|
   | 403             | `/404.html`        | 404                |
   | 404             | `/404.html`        | 404                |

   The bucket is private and CloudFront has no `s3:ListBucket` permission, so a missing file comes back from S3
   as a 403, not a 404. Mapping both to the 404 page covers it.

9. Copy the distribution ID (it starts with `E`) into `distribution_id` in the `justfile`.

## 4. DNS (Route 53)

In Route 53 → Hosted zones → `kids-vote.org`, create four records. Each one points at the CloudFront
distribution:

| Record name         | Type | Alias | Route traffic to                        |
|---------------------|------|-------|-----------------------------------------|
| `kids-vote.org`     | A    | Yes   | Alias to CloudFront distribution → (it) |
| `kids-vote.org`     | AAAA | Yes   | Alias to CloudFront distribution → (it) |
| `www.kids-vote.org` | A    | Yes   | Alias to CloudFront distribution → (it) |
| `www.kids-vote.org` | AAAA | Yes   | Alias to CloudFront distribution → (it) |

Both names serve the same content. If you'd rather have `www` redirect to the apex domain, a small CloudFront
Function can do that later.

## 5. Deploy credentials

`just deploy` runs as a dedicated IAM user, `kids-vote-deployer`, that can do nothing except upload to the bucket
and invalidate the distribution. Its access key lives in a local AWS CLI profile named `kids-vote-deploy`, which
the justfile selects explicitly (`deploy_profile`), so a deploy never uses your admin credentials.

1. IAM → Users → **Create user** `kids-vote-deployer` (no console access), and attach the policy below.
2. On the user's **Security credentials** tab, **Create access key** (use case: *Command Line Interface*).
3. Store the key locally. Run this in a terminal and paste the key pair when asked:

   ```sh
   aws configure --profile kids-vote-deploy    # region: the bucket's region; output format: leave blank
   ```

   This writes to `~/.aws/credentials` and `~/.aws/config`. Never put the key in the repo.
4. Check it works: `aws sts get-caller-identity --profile kids-vote-deploy` should show the `kids-vote-deployer` user.

The least-privilege policy for deploying looks like this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::kids-vote.org"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::kids-vote.org/*"
    },
    {
      "Effect": "Allow",
      "Action": "cloudfront:CreateInvalidation",
      "Resource": "arn:aws:cloudfront::<ACCOUNT_ID>:distribution/<DISTRIBUTION_ID>"
    }
  ]
}
```

## 6. Verify

```sh
just deploy
curl -sI https://kids-vote.org/           # expect 200
curl -sI http://kids-vote.org/            # expect 301 redirect to https
curl -sI https://kids-vote.org/nope       # expect 404, serving 404.html
curl -sI https://www.kids-vote.org/       # expect 200
```

DNS and a new distribution can take 10–20 minutes to become fully active.

## Notes for later

- **Subdirectory pages:** the default root object only applies at `/`, so `/about/` will not serve
  `/about/index.html`. Either link to `about.html` directly, or attach a CloudFront Function (viewer request)
  that adds `index.html` to URLs ending in `/`.
- **Backend:** if the site gets server-side features, add an API Gateway (or Lambda function URL) as a second
  origin on this same distribution, with a cache behavior for `/api/*`. The code would go in `backend/`.

## Resource IDs

| Resource                    | ID / ARN                                                                            |
|-----------------------------|-------------------------------------------------------------------------------------|
| AWS account ID              | 4026-7311-1584                                                                      |
| ACM certificate ARN         | arn:aws:acm:us-east-1:402673111584:certificate/8dd43d2a-d295-40b9-a1e6-b57e2d1ffa89 |
| S3 bucket                   | `kids-vote.org`                                                                     |
| CloudFront distribution ID  | E21PWJQQ8T7T6F                                                                      |
| CloudFront domain           | djm3eou14kqvj.cloudfront.net                                                        |
| Route 53 hosted zone ID     | Z04974403BQCO6VXNUXAM                                                               |
