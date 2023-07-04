[Previous Exercise] | [Home] | [Next Exercise]

[Previous Exercise]: ../06_set-variables-based-on-the-current-workspace/README.md

[Home]: ../../README.md

[Next Exercise]: ../07_expand-contract-migrations/README.md

---

![Things you should learn in Terraform](../../assets/logo.png)

# Exercise 6 - set variables based on the current workspace

⚠️ **This exercise requires that you've completed exercise 1** ⚠️

Terraform workspaces are a way of managing multiple sets of state for the same
codebase. For example, you might use the same Terraform code to deploy to both
a `staging` and a `production` environment. Staging and product might have
different sizes of EC2 instances, containers, or Lambda functions. Let's
explore some ways we can have different settings in different environments.

Our `terraform.tf` file looks a little different for this project as we're
using `workspace_key_prefix` and a much smaller `key` value:

```terraform
terraform {
  required_version = "~> 1.5"

  backend "s3" {
    bucket               = "my-tf-state-<account ID>-<region>"
    key                  = "terraform.tfstate"
    region               = "<region>"
    dynamodb_table       = "my-tf-state-locks"
    workspace_key_prefix = "things-you-should-learn-in-terraform/06_set-variables-based-on-the-current-workspace"
  }
}
```

Terraform will form the full S3 object key with this pattern:

```
things-you-should-learn-in-terraform/06_set-variables-based-on-the-current-workspace/<workspace>/terraform.tfstate
```

For example, the `staging` workspace would be:

```
things-you-should-learn-in-terraform/06_set-variables-based-on-the-current-workspace/staging/terraform.tfstate
```

Update the `terraform.tf` to have your account ID and region, then run an init:

```bash
# Only if you haven't done this already
git clone git@github.com:jSherz/things-you-should-learn-in-terraform.git
cd exercises/06_set-variables-based-on-the-current-workspace

# Download any required provider(s)
terraform init
```

Let's create our two workspaces, one for each environment:

```bash
terraform workspace new staging
terraform workspace new production
```

Switch back to the staging environment/workspace:

```bash
terraform workspace select staging
```

We're going to create a CloudWatch Log Group. In staging we want to retain logs
for 30 days, and in production we want to retain them for 90 days. Add this to
`main.tf`:

```terraform
resource "aws_cloudwatch_log_group" "super_important_logs" {
  name = "super-important-logs-${terraform.workspace}"

  retention_in_days = 30
}
```

Apply the changes:

```bash
terraform apply
```

Switch over to production:

```bash
terraform workspace select production
```

Now we have a problem! How can we set the `retention_in_days` to a different
value?

## First approach - locals

One option is to move the `retention_in_days` value to a local, and choose the
right value based on the current workspace. Update your `main.tf` to be as
follows:

```terraform
locals {
  super_important_log_retention = {
    staging    = 30
    production = 90
  }
}

resource "aws_cloudwatch_log_group" "super_important_logs" {
  name = "super-important-logs-${terraform.workspace}"

  retention_in_days = local.super_important_log_retention[terraform.workspace]
}
```

Run an apply - you should see that the log group is created with 90 days of log
retention:

```bash
terraform apply
```

## Second approach - variable files

You may instead prefer to have separate files, one per workspace/environment.
You'll see we have two files in this project with a `tfvars` extension:
`staging.tfvars` and `production.tfvars`. We can adapt our usage of Terraform
commands to include one of those. For example a plan:

```bash
terraform plan -var-file staging.tfvars
```

It's a bit of a pain to have to keep switching the name of the file, so instead
we can fetch the current workspace name and use that:

```bash
terraform plan -var-file $(terraform workspace show).tfvars
```

We can even create a wrapper scripts, e.g. `plan.sh`, `apply.sh`, `import.sh`
to save you some typing.

Change the contents of `main.tf` to the following:

```terraform
variable "super_important_log_retention" {
  type        = string
  description = "Log retention in days for our super important log group."
}

resource "aws_cloudwatch_log_group" "super_important_logs" {
  name = "super-important-logs-${terraform.workspace}"

  retention_in_days = var.super_important_log_retention
}
```

Try a plan without any extra flags:

```bash
terraform plan
```

Note that you're asked to specify the value:

```
var.super_important_log_retention
  Log retention in days for our super important log group.

  Enter a value: 
```

Use `Ctrl` + `C` to cancel that operation, and set the variable values in
`staging.tfvars` and `production.tfvars`:

_staging.tfvars_

```terraform
super_important_log_retention = 30
```

_production.tfvars_

```terraform
super_important_log_retention = 90
```

Try a plan with the `-var-file` flag from above:

```bash
terraform plan -var-file $(terraform workspace show).tfvars
```

You'll get the following clean plan:

```
aws_cloudwatch_log_group.super_important_logs: Refreshing state... [id=super-important-logs-production]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

## ⚠️ Warning about modules and logic

It can be really tempting to include logic in your modules that caters for
particular environments, for example something that looks like this:

_module/my-lambda-function/main.tf_

```terraform
variable "environment" {
  type        = string
  description = "Environment we're deploying infrastructure into."
}

resource "aws_lambda_function" "example" {
  function_name = "example"

  memory_size = var.environment == "staging" ? 128 : 256
}
```

This works really well until you have an edge case that needs an override. For
example, we might create a new User Acceptance Testing (UAT) environment that
is very similar to staging, with some small differences. If we want _most_ of
the values for staging, but not all, we can easily end up with a mess of
ternary statements. This is far worse if you've got nested modules - unpicking
that can be a real challenge!

My recommendation is to keep logic out of modules - instead of switching the
`memory_size` like above, we'd have our calling code just input the raw value:

```terraform
module "my_function_1" {
  source = "./module/my-lambda-function"

  memory_size = var.environment == "staging" ? 128 : 256
}
```

## 🍎 What did we learn?

* Workspaces let us deploy the same Terraform code multiple times with some
  changes, for example to different environments.

* With the S3 state backend, we use a key prefix to set where each workspaces'
  state file is stored.

* We can use the `terraform.workspace` value in our code to see the current
  workspace name.

* We can use variable files and the `-var-file` flag to choose which one to
  load.

    * The `terraform workspace show` CLI command gets the current workspace
      name. It can be useful to use in scripts that wrap Terraform operations.

* Keeping logic out of modules makes them easier to use as edge-cases arise.

## Further reading

* [Input Variables in the Terraform docs](https://developer.hashicorp.com/terraform/language/values/variables)
* [Workspaces in the Terraform docs](https://developer.hashicorp.com/terraform/language/state/workspaces) 

---

[Previous Exercise] | [Home] | [Next Exercise]
