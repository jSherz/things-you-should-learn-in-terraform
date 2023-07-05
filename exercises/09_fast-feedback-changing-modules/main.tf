module "user_avatars_bucket" {
  source = "git@github.com:jSherz/things-you-should-learn-in-terraform.git?ref=terraform-module-s3"

  name = "user-avatars-${data.aws_caller_identity.this.account_id}-${data.aws_region.this.name}"
}

module "user_avatars_bucket_cloudtrail" {
  source = "git@github.com:jSherz/things-you-should-learn-in-terraform.git?ref=terraform-module-cloudtrail"

  bucket_name = module.user_avatars_bucket.name
}
