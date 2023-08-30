resource "aws_api_gateway_rest_api" "api" {
  name = "Terraform REST Example"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.open_resource.id,
      aws_api_gateway_method.open_get_method.id,
      aws_api_gateway_integration.open_integration.id,
      aws_api_gateway_resource.secure_resource.id,
      aws_api_gateway_method.secure_get_method.id,
      aws_api_gateway_integration.secure_integration.id
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/aws/vendedlogs/tf_rest_logs"
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.logs.arn
    format = jsonencode({"requestId":"$context.requestId", "ip":"$context.identity.sourceIp", "requestTime":"$context.requestTime", "httpMethod":"$context.httpMethod","routeKey":"$context.routeKey", "status":"$context.status","protocol":"$context.protocol", "responseLength":"$context.responseLength", "integrationError":"$context.integrationErrorMessage" })
  }
}

#######################################
## Open endpoint                     ##
#######################################

resource "aws_api_gateway_resource" "open_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "open"
}

resource "aws_api_gateway_method" "open_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.open_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "open_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.open_resource.id
  http_method             = aws_api_gateway_method.open_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = module.lambda_function_responder.lambda_function_invoke_arn
}

#######################################
## Secure endpoint                   ##
#######################################

resource "aws_api_gateway_resource" "secure_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "secure"
}

resource "aws_api_gateway_method" "secure_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.secure_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.token_authorizer.id
}

resource "aws_api_gateway_integration" "secure_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.secure_resource.id
  http_method             = aws_api_gateway_method.secure_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = module.lambda_function_responder.lambda_function_invoke_arn
}

resource "aws_api_gateway_authorizer" "token_authorizer" {
  name                             = "token_authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api.id
  authorizer_uri                   = module.lambda_function_auth.lambda_function_invoke_arn
  authorizer_credentials           = aws_iam_role.invocation_role.arn
  identity_source                  = "method.request.header.myheader"
  authorizer_result_ttl_in_seconds = 0 # for testing only, caching should be added for production
  identity_validation_expression   = "^[0-9]+$"
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
  name               = "api_gateway_auth_invocation"
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
