module "lambda_function_responder" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "~> 6.0"
  timeout       = 300
  local_existing_package = "./src/responder/function.zip"
  function_name = "http_responder"
  handler       = "app.open_handler"
  runtime       = "python3.9"
  create_package = false
  publish       = true
  allowed_triggers = {
    APIGatewayAny = {
      service    = "apigateway"
      source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
    }
  }
}

module "lambda_function_auth" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "~> 6.0"
  timeout       = 300
  local_existing_package  = "./src/auth/function.zip"
  create_package = false
  function_name = "http_authorizer"
  handler       = "app.handler"
  runtime       = "python3.9"
}
