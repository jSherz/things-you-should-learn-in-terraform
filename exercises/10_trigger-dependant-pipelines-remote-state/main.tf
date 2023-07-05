data "terraform_remote_state" "fast_feedback_changing_modules" {
  backend = "s3"

  config = {
    bucket = "my-tf-state-<account ID>-<region>"
    key    = "things-you-should-learn-in-terraform/09_fast-feedback-changing-modules/terraform.tfstate"
    region = "<region>"
  }
}

data "aws_iam_policy_document" "example_assume" {
  statement {
    sid     = "AllowLambdaToAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

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

resource "aws_iam_role" "example" {
  name               = "user-avatar-lister"
  assume_role_policy = data.aws_iam_policy_document.example_assume.json
}

resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.example.json
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/user-avatar-lister"
  retention_in_days = 30
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
