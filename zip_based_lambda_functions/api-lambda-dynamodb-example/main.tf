# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.19"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
    region = "<AWS region>" # eg. us-east-1
}


resource "aws_lambda_function" "publish_book_review" {
    filename = "${local.building_path}/${local.lambda_code_filename}"
    handler = "index.lambda_handler"
    runtime = "python3.8"
    function_name = "publish-book-review"
    role = aws_iam_role.iam_for_lambda.arn
    timeout = 30
    depends_on = [
        null_resource.build_lambda_function
    ]

    environment {
        variables = {
            DYNAMODB_TABLE_NAME = "${aws_dynamodb_table.book-reviews-ddb-table.id}"
        }
  }
}

resource "null_resource" "sam_metadata_aws_lambda_function_publish_book_review" {
    triggers = {
        resource_name = "aws_lambda_function.publish_book_review"
        resource_type = "ZIP_LAMBDA_FUNCTION"
        original_source_code = "${local.lambda_src_path}"
        built_output_path = "${local.building_path}/${local.lambda_code_filename}"
    }
    depends_on = [
        null_resource.build_lambda_function
    ]
}

resource "null_resource" "build_lambda_function" {
    triggers = {
        build_number = "${timestamp()}" # TODO: calculate hash of lambda function. Mo will have a look at this part
    }

    provisioner "local-exec" {
        command =  substr(pathexpand("~"), 0, 1) == "/"? "./py_build.sh \"${local.lambda_src_path}\" \"${local.building_path}\" \"${local.lambda_code_filename}\" Function" : "powershell.exe -File .\\PyBuild.ps1 ${local.lambda_src_path} ${local.building_path} ${local.lambda_code_filename} Function"
    }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
    }
    EOF

  inline_policy {
    name = "dynamodb_access"

    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
            "Action": [
                "dynamodb:List*",
                "dynamodb:DescribeReservedCapacity*",
                "dynamodb:DescribeLimits",
                "dynamodb:DescribeTimeToLive"
            ],
            "Resource": "*",
            "Effect": "Allow"
            },
            {
            "Action": [
                "dynamodb:BatchGet*",
                "dynamodb:DescribeStream",
                "dynamodb:DescribeTable",
                "dynamodb:Get*",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:BatchWrite*",
                "dynamodb:CreateTable",
                "dynamodb:Delete*",
                "dynamodb:Update*",
                "dynamodb:PutItem"
            ],
            "Resource": [
                "${aws_dynamodb_table.book-reviews-ddb-table.arn}"
            ],
            "Effect": "Allow"
            }
        ]
    })
  }

}

resource "aws_dynamodb_table" "book-reviews-ddb-table" {
  name           = "BookReviews"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "ReviewId"
  range_key      = "BookTitle"

  attribute {
    name = "ReviewId"
    type = "S"
  }

  attribute {
    name = "BookTitle"
    type = "S"
  }

  attribute {
    name = "ReviewScore"
    type = "N"
  }

  global_secondary_index {
    name               = "BookTitleIndex"
    hash_key           = "BookTitle"
    range_key          = "ReviewScore"
    write_capacity     = 1
    read_capacity      = 1
    projection_type    = "INCLUDE"
    non_key_attributes = ["ReviewId"]
  }

  tags = {
    Name        = "book-reviews-table"
  }
}


## API Gateway

resource "aws_apigatewayv2_api" "lambda" {
  name          = "book_reviews_service"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "publish_book_review_api" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.publish_book_review.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "publish_book_review_route" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /book-review"
  target    = "integrations/${aws_apigatewayv2_integration.publish_book_review_api.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.publish_book_review.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
