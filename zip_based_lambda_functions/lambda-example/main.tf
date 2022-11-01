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
  
 backend "s3" {
    # Update the remote backend below to support your environment
    bucket         = "<your-s3-bucket-name>"
    key            = "sample/terraform.tfstate"
    region         = "<AWS region>" # eg. us-east-1
    encrypt        = true
  }
  
  provider "aws" {
    region = "<AWS region>" # eg. us-east-1
 }


resource "aws_lambda_function" "hello-terraform" {
    filename = "${local.building_path}/${local.lambda_code_filename}"
    handler = "index.lambda_handler"
    runtime = "python3.8"
    function_name = "hello-terraform"
    role = aws_iam_role.iam_for_lambda.arn
    timeout = 30
    depends_on = [
        null_resource.build_lambda_function
    ]
}

resource "null_resource" "sam_metadata_aws_lambda_function_hello_terraform" {
    triggers = {
        resource_name = "aws_lambda_function.hello-terraform"
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
        command = "./py_build.sh \"${local.lambda_src_path}\" \"${local.building_path}\" \"${local.lambda_code_filename}\" Function"
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

}