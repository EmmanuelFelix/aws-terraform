# variables.tf
variable "existing_key_name" {
  description = "The name of the pre-existing AWS Key Pair to use."
  type        = string
  default     = "aws_key_1" 
}
