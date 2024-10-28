# modules/event_bus/outputs.tf

output "event_bus_name" {
  value       = aws_cloudwatch_event_bus.health_iot_event_bus.name
  description = "The name of the EventBridge event bus"
}

output "abnormal_heart_rate_rule_arn" {
  value       = aws_cloudwatch_event_rule.abnormal_heart_rate_rule.arn
  description = "The ARN of the abnormal heart rate detection rule"
}

output "sns_topic_arn" {
  value = aws_sns_topic.abnormal_heart_rate_topic.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.abnormal_heart_rate_handler.arn
}

output "kinesis_stream_arn" {
  value = aws_kinesis_stream.health_data_stream.arn
}

output "eventbridge_invoke_role_arn" {
  value = aws_iam_role.eventbridge_invoke_role.arn
}

# terraform/streams/outputs.tf

output "kinesis_stream_name" {
  value = aws_kinesis_stream.health_data_stream.name
}

# terraform/lambda/outputs.tf

output "abnormal_heart_rate_handler_function_name" {
  value = aws_lambda_function.abnormal_heart_rate_handler.function_name
}

# Output the table name
output "dynamodb_table_name" {
  value = aws_dynamodb_table.processed_data.name
}
