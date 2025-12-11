Setup and Execution
Save the Code: Save the code block above as a file named main.tf.

Initialize Terraform:

Bash

terraform init
Review the Plan:

Bash

terraform plan
(Verify that it shows resources for an S3 Bucket, VPC Flow Log, IAM Policy Documents, and related S3 controls will be added.)

Apply the Configuration:

Bash

terraform apply


Testing/Verification
Once terraform apply is complete:

Check the VPC Console:

Go to the AWS VPC Console.

Select the VPC ID shown in the Terraform output (monitored_vpc_id).

Navigate to the Flow Logs tab.

You should see the new Flow Log ID (vpc_flow_log_id) listed with a destination type of Amazon S3 and a Status of Active.

Check the S3 Bucket:

Go to the AWS S3 Console.

Find the bucket name from the Terraform output (s3_flow_log_bucket_name).

Wait approximately 10 to 15 minutes (VPC Flow Logs are batched and delivered at an interval).

You should eventually see log objects appear in a path structure inside the bucket, similar to AWSLogs/account_id/vpcflowlogs/region/year/month/day/...

The presence of these files confirms that the flow log is successfully capturing and delivering data to S3.