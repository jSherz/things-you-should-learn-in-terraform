terraform {
  required_version = "~> 1.5"

  backend "s3" {
    bucket               = "my-tf-state-<account ID>-<region>"
    key                  = "terraform.tfstate"
    region               = "<region>"
    dynamodb_table       = "my-tf-state-locks"
    workspace_key_prefix = "things-you-should-learn-in-terraform/06_set-variables-based-on-the-current-workspace"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.6.2"
    }
  }
}
