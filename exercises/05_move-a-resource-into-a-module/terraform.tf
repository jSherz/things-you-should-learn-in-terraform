terraform {
  required_version = "~> 1.5"

  backend "s3" {
    bucket         = "my-tf-state-<account ID>-<region>"
    key            = "things-you-should-learn-in-terraform/05_move-a-resource-into-a-module/terraform.tfstate"
    region         = "<region>"
    dynamodb_table = "my-tf-state-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.6.2"
    }
  }
}
