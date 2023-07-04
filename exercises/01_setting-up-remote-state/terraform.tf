terraform {
  required_version = "~> 1.5"

  # Follow the tutorial in README.md
  #
  # backend "s3" {
  #   bucket         = "my-tf-state-<account ID>-<region>"
  #   key            = "things-you-should-learn-in-terraform/01_setting-up-remote-state/terraform.tfstate"
  #   region         = "<region>"
  #   dynamodb_table = "my-tf-state-locks"
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.6.2"
    }
  }
}
