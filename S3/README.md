Terraform 1.6+ includes a built-in testing framework. You do not need extra tools like Go or Terratest for basic validation.

Create a file named tests/s3.tftest.hcl

Initialize:

Bash

terraform init
Run the Tests: (This runs the .tftest.hcl assertions against a plan, without creating resources yet)

Bash

terraform test
Output should say: Success! 3 passed, 0 failed.

Apply to AWS:

Bash

terraform apply



# List all buckets
aws s3 ls

# List files in a specific bucket
aws s3 ls s3://my-company-backups

# Download a file (Copy from S3 to local)
aws s3 cp s3://my-company-backups/database.sql ./local-folder/

# Sync a local folder to S3 (Upload changes only)
aws s3 sync ./local-website s3://my-static-site

# copy file into S3
aws s3 cp local_file.txt s3://your-bucket-name/path/to/destination/



Python / Boto3 (Best for Applications)
If you are building an app, use the AWS SDK. In Python, this library is called boto3.


Setup:

Bash

pip install boto3
Code Example:

Python

import boto3

# 1. Connect (Uses credentials from ~/.aws/credentials automatically)
s3 = boto3.client('s3')

# 2. List Buckets
response = s3.list_buckets()
print("Connected! Found buckets:")
for bucket in response['Buckets']:
    print(f"  - {bucket['Name']}")

# 3. Upload a file
s3.upload_file('test.txt', 'my-bucket-name', 'uploaded-test.txt')
print("Upload successful.")


Mount as a Local Disk (Best for Legacy Apps)
You can "mount" an S3 bucket so it looks like a regular folder on your computer.

Tool: Mountpoint for Amazon S3 (Official AWS tool, faster) or s3fs-fuse (Open source, feature-rich).

Using Mountpoint (Linux):

Bash

# 1. Install (Amazon Linux example)
sudo yum install mount-s3

# 2. Create a folder to act as the mount point
mkdir ~/my-bucket-data

# 3. Connect/Mount
mount-s3 my-company-backups ~/my-bucket-data

# 4. Access files normally
ls ~/my-bucket-data

Pre-signed URLs (Best for Temporary Sharing)
If you need to give someone access to one file without creating a user account for them, generate a temporary link.

CLI Command:

Bash

# Generate a link valid for 1 hour (3600 seconds)
aws s3 presign s3://my-company-backups/report.pdf --expires-in 3600
Output: https://my-bucket...signed-url... (Anyone with this link can download the file).

5. Private VPC Endpoint (Best for Security)
If you are inside AWS (e.g., on an EC2 instance) and want to connect to S3 without going over the public internet, use a VPC Gateway Endpoint.

Go to VPC Dashboard > Endpoints > Create Endpoint.

Select Service: com.amazonaws.[region].s3 (Type: Gateway).

Select your VPC and the Route Table associated with your EC2 instances.

Result: Your EC2 instances can now reach S3 privately. No Internet Gateway or NAT Gateway is required.

| Method,Best For...                                                                                                                                               |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AWS CLI,Admins performing quick tasks or automated scripts.                                                                                                      |
| Boto3 (SDK),Developers building applications (Python, Node, Java, etc.)."<br/>Mountpoint,"Applications that only understand local file paths (e.g., legacy CMS). |
| Pre-signed URL,Sending a large file to a client securely.                                                                                                        |
| VPC Endpoint,Enterprise security; keeping traffic off the public internet.                                                                                       |