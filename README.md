🛠️ Prerequisites
Before you begin, ensure you have the following tools installed and configured:

Terraform (>= 1.0.0 recommended)

AWS CLI (Configured with appropriate credentials)

An AWS Account

git

AWS Authentication
Ensure your AWS credentials are configured. The examples use the default provider configuration, which typically relies on the following in order of preference:

Environment Variables: (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)

Shared Credentials File: (~/.aws/credentials)

IAM Roles (if running on an EC2 instance or in a CI/CD pipeline)

⚠️ Security Note: Never hardcode secrets or access keys directly into your Terraform configuration files.

🚀 Getting Started
Follow these general steps to deploy any of the examples:

Clone the Repository

Bash

git clone [your-repo-url]
cd [your-repo-name]
Navigate to an Example

Bash

cd examples/01-single-ec2-web
Initialize Terraform

Bash

terraform init
(This command downloads the necessary AWS provider plugins and initializes the backend.)

Review the Plan

Bash

terraform plan
(Inspect the plan output to see exactly what resources Terraform will create.)

Apply the Configuration

Bash

terraform apply
(Confirm the prompt by typing yes to provision the infrastructure.)

View Outputs After a successful apply, Terraform will display any output variables, such as public IP addresses or DNS names.

Clean Up To avoid incurring AWS costs, always destroy the resources when you are finished.

Bash

terraform destroy
