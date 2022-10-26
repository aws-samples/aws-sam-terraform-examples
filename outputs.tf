output "api_url" {
  description = "Deployment invoke url"
  value       = aws_apigatewayv2_stage.lambda.invoke_url
}

output "publish_book_url" {
  description = "Deployment invoke url"
  value     = "${aws_apigatewayv2_stage.lambda.invoke_url}/book-review"
}