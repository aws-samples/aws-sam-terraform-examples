terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  cloud {
    organization = ""

    workspaces {
      name = ""
    }
  }
}

provider "aws" {
  region                   = var.aws_region
  shared_config_files      = [var.config_location]
  shared_credentials_files = [var.creds_location]
  profile                  = var.profile
}

###################################
## Outputs                       ##
###################################

output "api_endpoint" {
  description = "Base url for api"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "http_api_logs_command" {
  description = "Command to view http api logs with sam"
  value       = "sam logs --cw-log-group ${aws_cloudwatch_log_group.logs.name} -t"
}

output "authorizer_logs_command" {
  description = "Command to view authorizer function logs with sam"
  value       = "sam logs --cw-log-group ${module.lambda_function_auth.lambda_cloudwatch_log_group_name} -t"
}

output "responder_logs_command" {
  description = "Command to view responder function logs with sam"
  value       = "sam logs --cw-log-group ${module.lambda_function_responder.lambda_cloudwatch_log_group_name} -t"
}

output "all_logs" {
  description = "Command to view an aggragate of all logs with sam"
  value = "sam logs --cw-log-group ${aws_cloudwatch_log_group.logs.name} --cw-log-group ${module.lambda_function_auth.lambda_cloudwatch_log_group_name} --cw-log-group ${module.lambda_function_responder.lambda_cloudwatch_log_group_name} -t"
}
