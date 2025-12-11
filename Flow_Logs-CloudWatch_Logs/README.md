| Step                | Terraform Resource              | Purpose                                                                                           |
|---------------------|---------------------------------|---------------------------------------------------------------------------------------------------|
| 1. Get VPC ID       | data "aws_vpc" "selected"       | Retrieves the ID of an existing VPC to specify where the flow logs should be captured.            |
| 2. S3 Bucket        | resource "aws_s3_bucket"        | Creates the S3 bucket. Crucially, it must have the                                                |
|                     |                                 | acl = "log-delivery-write"                                                                        |
|                     |                                 | setting to allow the logs service to write to it. The bucket name must be globally unique.        |
| 3. S3 Bucket Policy | resource "aws_s3_bucket_policy" | Defines the bucket policy that explicitly allows the AWS service principal                        |
|                     |                                 | delivery.logs.amazonaws.com                                                                       |
|                     |                                 | to perform                                                                                        |
|                     |                                 | s3:PutObject                                                                                      |
|                     |                                 | and                                                                                               |
|                     |                                 | s3:GetBucketAcl                                                                                   |
|                     |                                 | actions. This is necessary for the logs to be delivered.                                          |
| 4. Enable Flow Log  | resource "aws_flow_log"         | Specifies the VPC ID to monitor, the traffic type, the S3 Bucket ARN as the destination, and sets |
|                     |                                 | log_destination_type                                                                              |
|                     |                                 | to                                                                                                |
|                     |                                 | "s3"                                                                                              |
|                     |                                 | . You can also define a custom                                                                    |
|                     |                                 | log_format                                                                                        |
|                     |                                 | for added fields.                                                                                 |




. Execute Terraform
Initialize: Run terraform init in the directory containing your .tf files.

Plan: Run terraform plan to see the resources that will be created.

Apply: Run terraform apply and confirm with yes.

Verification Steps
A. AWS Console Check (VPC)
Navigate to the VPC service in the AWS Console.

Select your target VPC (e.g., the default VPC).

In the details pane, select the Flow Logs tab.

You should see a new Flow Log entry with the status Active. The Destination should show the name of your CloudWatch Log Group or S3 Bucket.

B. Destination Check (CloudWatch Logs)
Navigate to the CloudWatch service.

In the left navigation panel, select Log Groups.

Find the Log Group you created (e.g., vpc-flow-logs-example).

Wait a few minutes (logs are typically aggregated every 1-10 minutes). You should eventually see Log Streams created within the Log Group, containing the traffic data.