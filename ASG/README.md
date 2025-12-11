Data Sources (data "aws_vpc", data "aws_ami"):

Instead of hardcoding IDs (which change per region), we ask AWS for the "Default VPC" and the "Latest Amazon Linux 2" image. This makes the code portable.

Launch Template (aws_launch_template):

This is the blueprint for your instances.

User Data: We injected a bash script that installs a web server (httpd) and the stress tool. The stress tool is critical for testing the auto-scaling later.

Auto Scaling Group (aws_autoscaling_group):

Capacity: We set min=1, max=3, desired=1. This means it starts with 1 server but can grow to 3 if needed.

VPC Zone Identifier: This tells the ASG to distribute instances across all subnets in your default VPC (ensuring high availability).

Scaling Policy (aws_autoscaling_policy):

We used a Target Tracking policy.

Logic: "Keep the average CPU of my fleet at 50%."

If CPU spikes > 50%, AWS adds an instance. If CPU drops, AWS removes an instance.



Initialize: Downloads the AWS provider plugins.

Bash

terraform init
Plan: Shows you what will be created (sanity check).

Bash

terraform plan
Apply: Deploys the infrastructure. Type yes when prompted.

Bash

terraform apply

How to Test It (The Fun Part)
To verify the "Auto Scaling" actually works, we need to simulate a crash or high traffic.

Step A: Connect to the instance
Go to the AWS Console > EC2 Dashboard.

Select the instance created by the ASG (it will be named ASG-Instance).

Click Connect > EC2 Instance Connect > Connect (this opens a browser-based SSH terminal).

Step B: Generate Artificial Load
We installed the stress tool in the user data. Run this command to max out the CPU:

Bash

# This forces the CPU to work at 100% load
stress --cpu 1 --timeout 300
Step C: Watch the Magic
Leave the stress command running.

Go back to the EC2 Dashboard.

Watch the Auto Scaling Groups tab (under the "Activity" tab) or just the Instances list.

Result: Within 2-4 minutes, AWS CloudWatch will detect the CPU spike (average > 50%). The ASG will trigger a "Scale Out" event and automatically launch a second instance.

Step D: Clean Up
Once you are done testing, destroy the resources to avoid costs:

Bash

terraform destroy