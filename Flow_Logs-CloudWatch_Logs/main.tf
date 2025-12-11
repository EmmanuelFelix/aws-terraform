# --- 1. Get an existing VPC to attach the flow log to ---
data "aws_vpc" "selected" {
  default = true
}

# --- 2. Create the CloudWatch Log Group Destination ---
resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name              = "vpc-flow-logs-example"
  retention_in_days = 7
}

# --- 3. Create IAM Role and Policy for Flow Logs to publish to CloudWatch ---

# 3a. IAM Role for VPC Flow Logs service to assume
data "aws_iam_policy_document" "flow_log_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_log_role" {
  name               = "vpc-flow-log-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume_role.json
}

# 3b. IAM Policy defining the permissions to write to CloudWatch Logs
data "aws_iam_policy_document" "flow_log_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    # Resource: "*" is used because the service needs permission to create new log streams 
    # within the specific log group defined by the CloudWatch Log Group ARN.
    resources = ["*"] 
  }
}

resource "aws_iam_policy" "flow_log_policy" {
  name   = "vpc-flow-log-cloudwatch-policy"
  policy = data.aws_iam_policy_document.flow_log_policy.json
}

# 3c. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "flow_log_policy_attach" {
  role       = aws_iam_role.flow_log_role.name
  policy_arn = aws_iam_policy.flow_log_policy.arn
}

# --- 4. Create the VPC Flow Log resource and attach it to the VPC ---
resource "aws_flow_log" "cloudwatch_flow_log" {
  vpc_id                = data.aws_vpc.selected.id
  traffic_type          = "ALL" # Can be ACCEPT, REJECT, or ALL
  log_destination       = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  log_destination_type  = "cloud-watch-logs"
  iam_role_arn          = aws_iam_role.flow_log_role.arn
  max_aggregation_interval = 60 # Aggregation interval in seconds (60 or 600)
}