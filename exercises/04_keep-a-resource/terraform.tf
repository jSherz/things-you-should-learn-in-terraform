terraform {
  required_version = "~> 1.5"

  backend "s3" {
    bucket         = "my-tf-state-<account ID>-<region>"
    key            = "things-you-should-learn-in-terraform/04_keep-a-resource/terraform.tfstate"
    region         = "<region>"
    dynamodb_table = "my-tf-state-locks"
  }
}
