terraform {
  required_version = "~> 1.5"

  backend "s3" {
    bucket         = "my-tf-state-247940857651-eu-west-1" # "my-tf-state-<account ID>-<region>"
    region         = "eu-west-1" # "<region>"
#    bucket         = "my-tf-state-<account ID>-<region>"
    key            = "things-you-should-learn-in-terraform/09_fast-feedback-changing-modules/terraform.tfstate"
#    region         = "<region>"
    dynamodb_table = "my-tf-state-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.6.2"
    }
  }
}
