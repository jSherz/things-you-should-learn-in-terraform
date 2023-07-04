[Home] | [Next Exercise]

[Home]: ../../README.md
[Next Exercise]: ../02_pull-and-inspect-state/README.md

---

![Things you should learn in Terraform](../../assets/logo.png)

# Exercise 1 - setting up remote state

When you're collaborating with others as part of a team, you'll have to set up
a method of sharing Terraform state. I recommend using remote state even when
you're working on a side-project or learning exercise alone - it's good
practice!

## What remote state option should I choose?

The exercises in this project are written for AWS, so we'll choose S3 to store
our state files. Once you've completed this exercise, try an alternative
backend (I recommend Terraform Cloud) so you can compare the two.

## Creating our state storage bucket

To store state files in S3 we're going to need a bucket. Let's start off with
the simplest configuration for an S3 bucket:

```terraform
resource "aws_s3_bucket" "state" {
}
```

Job done? Far from it!

We're going to be referencing the bucket with a name that's hardcoded into our
Terraform projects. It'll be a long-lived resource, so let's give it a friendly
name:

```terraform
data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

resource "aws_s3_bucket" "state" {
  bucket = "my-tf-state-${data.aws_caller_identity.this.account_id}-${data.aws_region.this.name}"
}
```

We use the account ID and region suffix to have our Terraform code work
wherever we deploy it. S3 bucket names are shared between all customers /
accounts in all regions.

Next up: blocking public access. S3 has tonnes of configuration options, and we
definitely do not want our state files to be public. Let's guard against a
mistake in Access Control Lists (ACLs) or bucket policies and block public
access:

```terraform
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

We're going to be learning how to manually edit the state later in this series,
and so we want to be able to undo any mistakes we make. To do this, we'll
enable versioning:

```terraform
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

Let's have our state files be encrypted by default:

```terraform
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

And for a belt-and-braces approach, let's also enforce encryption when files
are uploaded:

```terraform
data "aws_iam_policy_document" "enforce_https" {
  statement {
    sid       = "Enforce HTTPS"
    actions   = ["s3:PutObject"]
    effect    = "Deny"
    resources = ["${aws_s3_bucket.state.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id

  policy = data.aws_iam_policy_document.enforce_https.json
}
```

### Which came first? The state bucket 🐔 or the 🥚 state file?

You might be wondering how we're supposed to create this state bucket when
we're hopefully going to be using it to store our state files. One option is to
create the bucket with local state, and then transfer it across. I'd generally
recommend creating a project (e.g. a GitHub repo) just for your state bucket,
and then referencing it in other projects.

Let's start by creating the state bucket:

```bash
# Only if you haven't done this already
git clone git@github.com:jSherz/things-you-should-learn-in-terraform.git
cd exercises/01_setting-up-remote-state

# Download any required provider(s)
terraform init

# Create the bucket
terraform apply
```

Modify the terraform.tf file to use your new bucket:

```terraform
terraform {
  required_version = "~> 1.5"

  backend "s3" {
    bucket = "my-tf-state-<account ID>-<region>" # TODO! Replace with your values
    key    = "things-you-should-learn-in-terraform/01_setting-up-remote-state/terraform.tfstate"
    region = "<region>" # TODO! Replace with your region
  }
}
```

Transfer the state into your bucket (answer "yes" when prompted):

```bash
terraform init -migrate-state
```

🎉 Congratulations 🎉 you've setup remote state.

### ⁉️ why all the resources?

If you've been working with Terraform and AWS for long enough you'll know that
many of the things we've just configured are also properties on the
`aws_s3_bucket` resource. These properties have been deprecated in favour of
the separate resources you can see above.

### 🤯 how am I supposed to remember all of these options?

It can be really challenging to know how to configure AWS resources to follow
best practices, especially with how frequently they evolve. Check out my blog
post on [shifting security left with AWS Config] to see how you can check your
work against common best practices and get near-instant feedback!

[shifting security left with AWS Config]: https://jsherz.com/aws/security/terraform/lambda/2023/05/27/shift-security-left-aws-config.html

## One last thing - a locking DynamoDB table

In software engineering, locks prevent conflicting operations from happening.
For example, you don't want two people to run a `terraform apply` at the same
time. Let's create a DynamoDB table that Terraform can use to lock the state
file:

```terraform
resource "aws_dynamodb_table" "state_locks" {
  name = "my-tf-state-locks"

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

Deploy the table:

```bash
terraform apply
```

Update the `terraform.tf` file to include the DynamoDB table:

```terraform
terraform {
  required_version = "~> 1.5"

  backend "s3" {
    bucket = "my-tf-state-<account ID>-<region>" # TODO! Replace with your values
    key    = "things-you-should-learn-in-terraform/01_setting-up-remote-state/terraform.tfstate"
    region = "<region>" # TODO! Replace with your region
    
    ## NEW

    dynamodb_table = "my-tf-state-locks"
    
    ## END NEW
  }
}
```

Re-initialise with the `-reconfigure` option to tell Terraform that it doesn't
need to migrate our state:

```bash
terraform init -reconfigure
```

And you're done!

## Further reading

Congratulations on getting this far! Try setting up alternative state backend,
for example Terraform Cloud. How does the experience differ?

---

[Home] | [Next Exercise]
