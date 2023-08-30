module "lambda_function_responder" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "~> 6.0"
  timeout       = 300
  source_path   = "../src/responder/"
  function_name = "responder"
  handler       = "app.open_handler"
  runtime       = "python3.9"
  create_sam_metadata = true
  publish       = true
  allowed_triggers = {
    APIGatewayAny = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
    }
  }
}

module "lambda_function_auth" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "~> 6.0"
  timeout       = 300
  source_path   = "../src/auth/"
  function_name = "authorizer"
  handler       = "app.handler"
  runtime       = "python3.9"
  create_sam_metadata = true
}
