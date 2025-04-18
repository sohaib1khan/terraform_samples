# S3 Static Website Hosting - Verification Guide

This README provides instructions for verifying your S3 static website deployment created with Terraform.

## Prerequisites

- AWS CLI installed and configured
- Terraform deployment completed successfully

## Verification Steps

### 1. Check Terraform Outputs

After running `terraform apply`, you should see outputs similar to:

```
Outputs:
bucket_arn = "arn:aws:s3:::your-unique-bucket-name-1234511"
bucket_name = "your-unique-bucket-name-1234511"
website_endpoint = "your-unique-bucket-name-1234511.s3-website-us-west-2.amazonaws.com"
website_url = "http://your-unique-bucket-name-1234511.s3-website-us-west-2.amazonaws.com"
```

Save the `website_url` value as you'll need it to access your site.

### 2. Verify Bucket Creation

```
# Run this command to list your S3 buckets
aws s3 ls

# You should see your bucket in the list:
# YYYY-MM-DD HH:MM:SS your-unique-bucket-name-1234511
```

### 3. Check Bucket Contents

```
# List the files in your bucket
aws s3 ls s3://your-unique-bucket-name-1234511/

# You should see:
# YYYY-MM-DD HH:MM:SS       SIZE error.html
# YYYY-MM-DD HH:MM:SS       SIZE index.html
```

### 4. Check Website Configuration

```
# Get the website configuration of your bucket
aws s3api get-bucket-website --bucket your-unique-bucket-name-1234511

# You should see output similar to:
# {
#     "IndexDocument": {
#         "Suffix": "index.html"
#     },
#     "ErrorDocument": {
#         "Key": "error.html"
#     }
# }
```

###  5. Check Bucket Policy

```
# Get the bucket policy
aws s3api get-bucket-policy --bucket your-unique-bucket-name-1234511

# You should see a policy that allows public read access
```

### 6. Access the Website in Browser

1.  Open a web browser
2.  Navigate to the website URL (from Terraform outputs)
    - Example: `http://your-unique-bucket-name-1234511.s3-website-us-west-2.amazonaws.com`
3.  You should see the "Hello from S3!" webpage

### 7. Test Error Page

1.  Add an invalid path to your website URL
    - Example: `http://your-unique-bucket-name-1234511.s3-website-us-west-2.amazonaws.com/nonexistent`
2.  You should see the custom error page with "Error: Page Not Found"

## Troubleshooting

### Website Not Accessible

1.  Check bucket policy allows public read access
2.  Verify website configuration is enabled
3.  Ensure bucket name matches the URL you're using
4.  Check that public access settings are not blocking access

### Index/Error Pages Not Displaying Correctly

1.  Verify the files were uploaded with correct content-type (`text/html`)
2.  Make sure the file names match the configuration

## Next Steps

- Upload additional content to your bucket:

```
aws s3 cp your-local-file.html s3://your-unique-bucket-name-1234511/
```

- Set up custom domain and HTTPS (requires additional configuration)
- Implement versioning and logging

## Cleaning Up

When you're done testing, you can destroy the resources:

```
terraform destroy
```

&nbsp;