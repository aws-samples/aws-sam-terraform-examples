resource "aws_apigatewayv2_api" "api" {
  name          = "Terraform HTTP API Example"
  protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/aws/vendedlogs/tf_http_logs"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  auto_deploy = true
  name        = "$default"
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.logs.arn
    format = jsonencode({"requestId":"$context.requestId", "ip":"$context.identity.sourceIp", "requestTime":"$context.requestTime", "httpMethod":"$context.httpMethod","routeKey":"$context.routeKey", "status":"$context.status","protocol":"$context.protocol", "responseLength":"$context.responseLength", "integrationError":"$context.integrationErrorMessage" })
  }
}

# #######################################
# ## Open endpoint                     ##
# #######################################

resource "aws_apigatewayv2_integration" "open_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = module.lambda_function_responder.lambda_function_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_open" {
  api_id             = aws_apigatewayv2_api.api.id
  target             = "integrations/${aws_apigatewayv2_integration.open_integration.id}"
  route_key          = "GET /open"
  operation_name     = "get_open_operation"
  authorization_type = "NONE"
}

# #######################################
# ## Secure endpoint                   ##
# #######################################

resource "aws_apigatewayv2_integration" "secure_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = module.lambda_function_responder.lambda_function_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_secure" {
  api_id             = aws_apigatewayv2_api.api.id
  target             = "integrations/${aws_apigatewayv2_integration.secure_integration.id}"
  route_key          = "GET /secure"
  operation_name     = "get_secure_operation"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.request_authorizer.id
}

resource "aws_apigatewayv2_authorizer" "request_authorizer" {
  api_id                            = aws_apigatewayv2_api.api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = module.lambda_function_auth.lambda_function_invoke_arn
  authorizer_credentials_arn        = aws_iam_role.invocation_role.arn
  authorizer_payload_format_version = "2.0"
  identity_sources                  = ["$request.header.myheader"]
  name                              = "header_authorizer"
  enable_simple_responses           = true
  authorizer_result_ttl_in_seconds  = 0 # for testing only, caching should be added for production
}

data "aws_iam_policy_document" "invocation_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "invocation_role" {
  name               = "api_gateway_auth_http_invocation"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.invocation_assume_role.json
}

data "aws_iam_policy_document" "invocation_policy" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.lambda_function_auth.lambda_function_arn]
  }
}

resource "aws_iam_role_policy" "invocation_policy" {
  name   = "default"
  role   = aws_iam_role.invocation_role.id
  policy = data.aws_iam_policy_document.invocation_policy.json
}
