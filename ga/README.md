# Terraform and SAM example applications

This repository contains sample applications showing how to use the AWS SAM CLI with Hashicorp's Terraform. It accompanies the blog [blog title](https://aws.amazon.com).

## Requirements
* [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-getting-started.html]) (Be sure to follow the instructions for the SAM CLI requirements)
* [Docker](docker.com) or Docker equivelant
* [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) by HashiCorp

## Local testing
The following instructions work for the Amazon API Gateway REST (v1) and HTTP (v2) APIs.

Choose the api you would like to test and change to that directory:
* REST (v1)
    ```
    cd api_gateway_v1
    ```
* HTTP (v2)
    ```
    cd api_gateway_v2
    ```
### Preparing the application
To ensure all Terraform dependencies are installed run the following:
```
terraform init
```

### Function invocation
Each example contains two Lambda functions. One function is a simple application responder that returns a simple `hello TF World` message, the other is an authorizer Lambda function used by API Gateway to authorize a user.

1. Test the responder function:
    ```
    sam local invoke 'module.lambda_function_responder.aws_lambda_function.this[0]'
    ```
2. Test the authorizer function
    ```
    sam local invoke 'module.lambda_function_auth.aws_lambda_function.this[0]' -e events/auth.json 
    ```
### Function invocation through *start-api*
Each project has two endpoints. One is an open endpoint and the other is secured by a Lambda authorizer for API Gateway. To test the endpoints start the local API with the following command:
```
sam local start-api
```

**To test the open endpoint:**
```
curl --location 'http://localhost:3000/open'
```
**To test the secure endpoint as authorized:**
```
curl --location 'http://localhost:3000/secure' --header 'myheader: 123456789'
```
**To test the secure endpoint as unauthorized:**
```
curl --location 'http://localhost:3000/secure' --header 'myheader: 123'
```
## Deploy the application
1. Create a file in the folder of the version you would like to deploy called *terraform.tfvars* and add the following items if needed.
    ```
    aws_region = "us-west-2"
    ```
    Optionally add the following if needed:
    ```
    profile             = "your AWS profile"  (defaults to 'default')
    config_location     = "location of your AWS config file" (defaults to '~/.aws/config')
    creds_location      = "location of your AWS creds file" (defaults to '~/.aws/credentials')
    ```
2. Run the following to see what it will do:
    ```
    terraform plan
    ```
3. Run the following to deploy:
    ```
    terraform apply
    ```

## Tear down
To destroy the application run the following command:
```
terraform destroy
```