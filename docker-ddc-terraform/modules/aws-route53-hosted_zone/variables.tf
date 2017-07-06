variable "aws_route53_environment_name" {
  description = "The environment for which this zone is being created."
}

variable "aws_route53_zone_name" {
  description = <<EOF
    The root DNS zone name, i.e. example.com.
    Don't put your environment name here; use aws_route53_environment_name
    instead.
    EOF
}

variable "aws_route53_zone_comment" {
  description = "A comment to add to this zone."
  default = <<EOF
    This zone is managed by Terraform. Any manual changes to it will
    be reverted at any time.
}
