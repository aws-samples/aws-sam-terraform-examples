## Deploying the example application
This Lambda function interacts with DynamoDB. For the example to work, it requires an existing DynamoDB table in an AWS account. Deploying this creates all the required resources for local testing and debugging of the Lambda function.

To deploy:

1- Initialize a working directory containing Terraform configuration files:
```
terraform init
```
2- Deploy the application using Terraform CLI. 
```
terraform apply -auto-approve
```
## Local testing
With the backend services now deployed, run local tests to see if everything is working. The locally running sample Lambda function interacts with the services deployed in the AWS account. Run the sam build to reflect the local sam testing environment with changes after each code update.

1- Local Build: To create a local build of the Lambda function for testing, use the sam build command:
```
sam build --hook-name terraform --beta-features
```

2- Local invoke: The first test is to invoke the Lambda function with a mocked event payload from the API Gateway. These events are in the events directory. Run this command, passing in a mocked event:
```
AWS_DEFAULT_REGION=<Your Region Name>
sam local invoke module.publish_book_review.aws_lambda_function.this[0] -e events/new-review.json --beta-features
```