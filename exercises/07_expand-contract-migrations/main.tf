data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

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
    sid       = "AllowUseOfECR"
    effect    = "Allow"
    actions   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "example" {
  name               = "expand-contract-example"
  assume_role_policy = data.aws_iam_policy_document.example_assume.json
}

resource "aws_iam_role_policy_attachment" "example_basic_exec" {
  role       = aws_iam_role.example.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "example_ecr" {
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.example.json
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/expand-contract-example"
  retention_in_days = 30
}

resource "aws_ecr_repository" "example" {
  name = "expand-contract-example"
}

resource "aws_lambda_function" "example" {
  function_name = "expand-contract-example"
  role          = aws_iam_role.example.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.example.repository_url}:latest"
  memory_size   = 128

  depends_on = [aws_cloudwatch_log_group.example]
}

###
resource "aws_cloudwatch_log_group" "example_new" {
  name              = "/aws/lambda/expand-contract-example-new"
  retention_in_days = 30
}

resource "aws_lambda_function" "example_new" {
  function_name    = "expand-contract-example-new"
  role             = aws_iam_role.example.arn
  memory_size      = 128
  filename         = "hello-world-lambda.zip"
  handler          = "index.handler"
  source_code_hash = filebase64sha256("hello-world-lambda.zip")
  runtime          = "nodejs18.x"

  depends_on = [aws_cloudwatch_log_group.example_new]
}

resource "aws_lambda_permission" "example_new" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_new.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:${aws_api_gateway_rest_api.example.id}/*/${aws_api_gateway_method.example.http_method}${aws_api_gateway_resource.hello_world.path}"
}
###

resource "aws_api_gateway_rest_api" "example" {
  name = "expand-contract-example"
}

resource "aws_api_gateway_resource" "hello_world" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  parent_id = aws_api_gateway_rest_api.example.root_resource_id
  path_part = "hello-world"
}

resource "aws_api_gateway_method" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.hello_world.id
}

resource "aws_api_gateway_integration" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  http_method             = "GET"
  resource_id             = aws_api_gateway_resource.hello_world.id
  uri                     = aws_lambda_function.example_new.invoke_arn
}

resource "aws_lambda_permission" "example" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:${aws_api_gateway_rest_api.example.id}/*/${aws_api_gateway_method.example.http_method}${aws_api_gateway_resource.hello_world.path}"
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.example.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_resource.hello_world,
    aws_api_gateway_method.example,
    aws_api_gateway_integration.example,
  ]
}

resource "aws_api_gateway_stage" "demo" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
  stage_name    = "demo"
}

output "api_endpoint_url" {
  value = "${aws_api_gateway_stage.demo.invoke_url}${aws_api_gateway_resource.hello_world.path}"
}

output "container_repo_url" {
  value = aws_ecr_repository.example.repository_url
}
