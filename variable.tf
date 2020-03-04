#Remote state


variable "region" {
  default = "ap-southeast-1"
}

variable "app_name" {
  default = "testapi"
}


locals {
  common_tags = {
    Environment = "Development"
    Application = "${var.app_name}"
  }
}

data "aws_caller_identity" "current" {}

