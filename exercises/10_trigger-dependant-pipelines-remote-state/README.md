[Previous Exercise] | [Home]

[Previous Exercise]: ../09_fast-feedback-changing-modules/README.md
[Home]: ../../README.md

---

![Things you should learn in Terraform](../../assets/logo.png)

# Exercise 10 - triggering dependant pipelines when using remote state

⚠️ **This exercise requires that you've completed exercises 1 and 9** ⚠️

At the very start of this series, we set up a Terraform state bucket to store
state files from many projects. We've been using it with each scenario,
choosing a different folder to avoid conflicts. If you've been following along
for the whole time, your state bucket probably looks like this:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
REGION=$(aws configure get region)

aws s3 ls --recursive s3://my-tf-state-${ACCOUNT_ID}-${REGION}
```

```
things-you-should-learn-in-terraform/01_setting-up-remote-state/terraform.tfstate
things-you-should-learn-in-terraform/03_recovering-the-state-after-bad-changes/terraform.tfstate
things-you-should-learn-in-terraform/04_keep-a-resource/terraform.tfstate
things-you-should-learn-in-terraform/05_move-a-resource-into-a-module/terraform.tfstate
things-you-should-learn-in-terraform/06_set-variables-based-on-the-current-workspace/production/terraform.tfstate
things-you-should-learn-in-terraform/06_set-variables-based-on-the-current-workspace/staging/terraform.tfstate
things-you-should-learn-in-terraform/07_expand-contract-migrations/terraform.tfstate
things-you-should-learn-in-terraform/08_import-existing-resources-no-disruption/terraform.tfstate
things-you-should-learn-in-terraform/09_fast-feedback-changing-modules/terraform.tfstate
```

It's a common pattern in more complex Terraform projects to read the state file
of another project. We do this with a data source:

```terraform
data "terraform_remote_state" "fast_feedback_changing_modules" {
  backend = "s3"

  config = {
    bucket = "my-tf-state-<account ID>-<region>"
    key    = "things-you-should-learn-in-terraform/09_fast-feedback-changing-modules/terraform.tfstate"
    region = "<region>"
  }
}
```

In this example, we're reading information about the previous exercise in which
we have two outputs: `user_avatars_bucket_arn` and `user_avatars_bucket_name`.
We can use those in the formation of an IAM policy and Lambda function:

```terraform
data "aws_iam_policy_document" "example" {
  statement {
    sid     = "AllowReadingAvatars"
    effect  = "Allow"
    actions = ["s3:ListBucket", "s3:GetObject"]

    resources = [
      data.terraform_remote_state.fast_feedback_changing_modules.outputs.user_avatars_bucket_arn,
      "${data.terraform_remote_state.fast_feedback_changing_modules.outputs.user_avatars_bucket_arn}/*",
    ]
  }
}

resource "aws_lambda_function" "example" {
  function_name    = "user-avatar-lister"
  role             = aws_iam_role.example.arn
  memory_size      = 128
  filename         = "user-avatar-lister.zip"
  handler          = "index.handler"
  source_code_hash = filebase64sha256("user-avatar-lister.zip")
  runtime          = "nodejs18.x"

  environment {
    variables = {
      BUCKET = data.terraform_remote_state.fast_feedback_changing_modules.outputs.user_avatars_bucket_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.example]
}
```

We can use those two values on the `outputs` key of the data source because
they're defined in exercise nine. Here they are in the `outputs.tf` file:

```terraform
output "user_avatars_bucket_arn" {
  value = module.user_avatars_bucket.arn
}

output "user_avatars_bucket_name" {
  value = module.user_avatars_bucket.name
}
```

But what happens if we change those outputs, for example if we accidentally
remove one that we didn't think was used? You might only find out some weeks
later, when the downstream project is re-run and then suddenly fails with a
mysterious error:

```
Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Unsupported attribute
│ 
│   on main.tf line 66, in resource "aws_lambda_function" "example":
│   66:       BUCKET = data.terraform_remote_state.fast_feedback_changing_modules.outputs.user_avatars_bucket_name
│     ├────────────────
│     │ data.terraform_remote_state.fast_feedback_changing_modules.outputs is object with 1 attribute "user_avatars_bucket_arn"
│ 
│ This object does not have an attribute named "user_avatars_bucket_name".
```

My recommendation is to have your project's CI/CD pipeline trigger the CI/CD
pipeline of any project that uses outputs from your state. For example, we can
do this in GitHub Actions as follows:

```yaml
jobs:
  trigger_dependant_project:
    runs-on: ubuntu-latest
    steps:
      - env:
          GITHUB_TOKEN: ${{ secrets.MY_TOKEN }}
        run: |
          curl -L \
            -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${GITHUB_TOKEN}"\
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/OWNER/REPO/actions/workflows/WORKFLOW_ID/dispatches \
            -d '{"ref":"main","inputs":{}}'
```

You can read more about this API call in "[Create a workflow dispatch event]"
in the GitHub docs.

[Create a workflow dispatch event]: https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28#create-a-workflow-dispatch-event

The `main.tf` file in this project demonstrates the full setup, in which a
Lambda function is created to read the avatars contained in the bucket created
in exercise nine. Give it a try in the CI/CD system you're most familiar with!

## 🍎 What did we learn?

* Remote state storage lets us access Terraform state across projects.

    * We do this with the `terraform_remote_state` data source.

* The `terraform_remote_state` data source relies on outputs configured on the
  project whose source file you're reading.

* We can avoid repos being left broken and unnoticed by triggering downstream
  CI pipelines of projects that depend on our project's state.

## Further reading

* [The terraform_remote_state Data Source](https://developer.hashicorp.com/terraform/language/state/remote-state-data)
* [Create a workflow dispatch event]

---

[Previous Exercise] | [Home] | [Next Exercise]
