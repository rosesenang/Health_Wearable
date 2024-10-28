# modules/event_bus/main.tf

# Create EventBridge Event Bus
resource "aws_cloudwatch_event_bus" "health_iot_event_bus" {
  name = "${var.project_name}-event-bus"
}

# Create EventBridge Rule for Abnormal Heart Rate Detection
resource "aws_cloudwatch_event_rule" "abnormal_heart_rate_rule" {
  name           = "${var.project_name}-abnormal-heart-rate-rule"
  description    = "Rule to detect abnormal heart rate and trigger notification"
  event_bus_name = aws_cloudwatch_event_bus.health_iot_event_bus.name
  event_pattern = jsonencode({
    "source" : ["health.iot.device"],
    "detail-type" : ["Heart Rate Alert"],
    "detail" : {
      "heartRate" : [{ "numeric" : [">", var.heart_rate_threshold] }]
    }
  })
}

# IAM Role for EventBridge to invoke targets
resource "aws_iam_role" "event_invoke_role" {
  name = "${var.project_name}-event-invoke-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : [
            "events.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        },
        "Effect" : "Allow"
      }
    ]
  })
}


# Policy to allow EventBridge rule to trigger actions
resource "aws_iam_policy" "event_invoke_policy" {
  name        = "${var.project_name}-event-invoke-policy"
  description = "Policy for EventBridge to invoke targets"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish", # For notifications
          "lambda:InvokeFunction",
          "kinesis:PutRecord"
        ],
        "Resource" : [
          aws_sns_topic.abnormal_heart_rate_topic.arn,
          aws_lambda_function.abnormal_heart_rate_handler.arn,
          aws_kinesis_stream.health_data_stream.arn
        ]
      }
    ]
  })
}

# Attach policy to the role
resource "aws_iam_role_policy_attachment" "event_invoke_policy_attachment" {
  role       = aws_iam_role.event_invoke_role.name
  policy_arn = aws_iam_policy.event_invoke_policy.arn
}

# SNS Topic for notifications
resource "aws_sns_topic" "abnormal_heart_rate_topic" {
  name = "${var.project_name}-abnormal-heart-rate-topic"
}

# EventBridge Target to send alerts to SNS
resource "aws_cloudwatch_event_target" "sns_target" {
  rule           = aws_cloudwatch_event_rule.abnormal_heart_rate_rule.name
  event_bus_name = aws_cloudwatch_event_bus.health_iot_event_bus.name
  arn            = aws_sns_topic.abnormal_heart_rate_topic.arn
  depends_on     = [aws_cloudwatch_event_rule.abnormal_heart_rate_rule]
}


# Email Subscription to SNS Topic
resource "aws_sns_topic_subscription" "caregiver_email_subscription" {
  topic_arn = aws_sns_topic.abnormal_heart_rate_topic.arn
  protocol  = "email"
  endpoint  = var.caregiver_email # Pass caregiver email from variable
}

# Lambda Function for custom processing
resource "aws_lambda_function" "abnormal_heart_rate_handler" {
  filename         = "function.zip"
  function_name    = "${var.project_name}-abnormal-heart-rate-handler"
  role             = aws_iam_role.event_invoke_role.arn
  handler          = "index.handler"
  runtime          = "python3.8" # Adjust runtime based on Lambda code
  source_code_hash = filebase64sha256(var.lambda_zip_file)

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.abnormal_heart_rate_topic.arn
    }
  }
}

# Grant Lambda access to publish to SNS
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.abnormal_heart_rate_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.abnormal_heart_rate_rule.arn
}

# EventBridge Target to trigger Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule           = aws_cloudwatch_event_rule.abnormal_heart_rate_rule.name
  event_bus_name = aws_cloudwatch_event_bus.health_iot_event_bus.name
  arn            = aws_lambda_function.abnormal_heart_rate_handler.arn
  depends_on     = [aws_cloudwatch_event_rule.abnormal_heart_rate_rule]
}


# EventBridge Rule for Device Connectivity Monitoring
resource "aws_cloudwatch_event_rule" "device_connectivity_rule" {
  name           = "${var.project_name}-device-connectivity-rule"
  description    = "Rule to monitor device connectivity and trigger alerts"
  event_bus_name = aws_cloudwatch_event_bus.health_iot_event_bus.name
  event_pattern = jsonencode({
    "source" : ["health.iot.device"],
    "detail-type" : ["Device Status Change"],
    "detail" : {
      "status" : ["disconnected"]
    }
  })
}

# Target SNS for device connectivity alerts
resource "aws_cloudwatch_event_target" "device_connectivity_sns_target" {
  rule           = aws_cloudwatch_event_rule.device_connectivity_rule.name
  event_bus_name = aws_cloudwatch_event_bus.health_iot_event_bus.name
  arn            = aws_sns_topic.abnormal_heart_rate_topic.arn
  depends_on     = [aws_cloudwatch_event_rule.device_connectivity_rule]
}


# EventBridge Rule to Trigger Blood Pressure Reading
resource "aws_cloudwatch_event_rule" "trigger_blood_pressure_rule" {
  name           = "${var.project_name}-trigger-blood-pressure-rule"
  description    = "Rule to trigger blood pressure reading after abnormal heart rate"
  event_bus_name = aws_cloudwatch_event_bus.health_iot_event_bus.name
  event_pattern = jsonencode({
    "source" : ["health.iot.device"],
    "detail-type" : ["Heart Rate Alert"],
    "detail" : {
      "heartRate" : [{ "numeric" : [">", var.heart_rate_threshold] }]
    }
  })
}

# Target Lambda for blood pressure trigger
resource "aws_cloudwatch_event_target" "trigger_blood_pressure_lambda_target" {
  rule           = aws_cloudwatch_event_rule.trigger_blood_pressure_rule.name
  event_bus_name = aws_cloudwatch_event_bus.health_iot_event_bus.name
  arn            = aws_lambda_function.abnormal_heart_rate_handler.arn
  depends_on     = [aws_cloudwatch_event_rule.trigger_blood_pressure_rule]
}


# EventBridge Rule for Real-Time Data Streaming
resource "aws_cloudwatch_event_rule" "real_time_data_streaming_rule" {
  name           = "${var.project_name}-real-time-data-streaming-rule"
  description    = "Rule to stream real-time health data for visualization"
  event_bus_name = aws_cloudwatch_event_bus.health_iot_event_bus.name
  event_pattern = jsonencode({
    "source" : ["health.iot.device"],
    "detail-type" : ["Health Data"]
  })
}

# Target for Kinesis Data Stream or Firehose (example using Kinesis)
resource "aws_kinesis_stream" "health_data_stream" {
  name             = "${var.project_name}-health-data-stream"
  shard_count      = 1
  retention_period = 24 # Data retention period in hours
}

# EventBridge Target for data streaming
resource "aws_cloudwatch_event_target" "kinesis_data_stream_target" {
  rule           = aws_cloudwatch_event_rule.real_time_data_streaming_rule.name
  event_bus_name = aws_cloudwatch_event_bus.health_iot_event_bus.name
  arn            = aws_kinesis_stream.health_data_stream.arn
  role_arn       = aws_iam_role.event_invoke_role.arn

  depends_on = [aws_cloudwatch_event_rule.real_time_data_streaming_rule]
}


# IAM Role for EventBridge to invoke SNS, Lambda, and Kinesis
resource "aws_iam_role" "eventbridge_invoke_role" {
  name = "${var.project_name}-eventbridge-invoke-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "events.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policy to allow SNS, Lambda, and Kinesis invocation
resource "aws_iam_role_policy" "eventbridge_invoke_policy" {
  name = "${var.project_name}-eventbridge-invoke-policy"
  role = aws_iam_role.eventbridge_invoke_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish",
          "lambda:InvokeFunction",
          "kinesis:PutRecord"
        ],
        "Resource" : [
          aws_sns_topic.abnormal_heart_rate_topic.arn,
          aws_lambda_function.abnormal_heart_rate_handler.arn,
          aws_kinesis_stream.health_data_stream.arn
        ]
      }
    ]
  })
}


# CloudWatch Log Group for Lambda Function Logs
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.abnormal_heart_rate_handler.function_name}"
  retention_in_days = 7 # Retain logs for 7 days (adjust as needed)
}

# CloudWatch Alarm for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "${var.project_name}-LambdaErrors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm if Lambda function has errors"
  alarm_actions       = [aws_sns_topic.abnormal_heart_rate_topic.arn] # Send alarm notification
  dimensions = {
    FunctionName = aws_lambda_function.abnormal_heart_rate_handler.function_name
  }
}

# CloudWatch Alarm for Failed EventBridge Invocations
resource "aws_cloudwatch_metric_alarm" "eventbridge_failure_alarm" {
  alarm_name          = "${var.project_name}-EventBridgeFailures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm if EventBridge fails to invoke targets"
  alarm_actions       = [aws_sns_topic.abnormal_heart_rate_topic.arn]
  dimensions = {
    RuleName = aws_cloudwatch_event_rule.abnormal_heart_rate_rule.name
  }
}

# CloudWatch Alarm for Kinesis Data Stream Throttling
resource "aws_cloudwatch_metric_alarm" "kinesis_throttling_alarm" {
  alarm_name          = "${var.project_name}-KinesisThrottling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm if Kinesis data stream is throttled"
  alarm_actions       = [aws_sns_topic.abnormal_heart_rate_topic.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.health_data_stream.name
  }
}

# CloudWatch Dashboard for Health Wearables IoT System
resource "aws_cloudwatch_dashboard" "iot_dashboard" {
  dashboard_name = "${var.project_name}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 6,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.abnormal_heart_rate_handler.function_name],
            ["AWS/Events", "FailedInvocations", "RuleName", aws_cloudwatch_event_rule.abnormal_heart_rate_rule.name],
            ["AWS/Kinesis", "ReadProvisionedThroughputExceeded", "StreamName", aws_kinesis_stream.health_data_stream.name]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "us-east-1",
          "title" : "System Health Metrics"
        }
      }
    ]
  })
}

# terraform/lambda/main.tf

resource "aws_iam_role" "lambda_kinesis_role" {
  name = "lambda_kinesis_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_kinesis_policy" {
  name        = "lambda_kinesis_policy"
  description = "Policy for Lambda to access Kinesis and CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:ListShards",
          "kinesis:ListStreams"
        ],
        Resource = "arn:aws:kinesis:us-east-1:${data.aws_caller_identity.current.account_id}:stream/*",
        Effect   = "Allow"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*",
        Effect   = "Allow"
      }
    ]
  })
}
resource "aws_dynamodb_table" "processed_data" {
  name         = "ProcessedData"   
  billing_mode = "PAY_PER_REQUEST" 
  hash_key     = "id"              

  attribute {
    name = "id"
    type = "S" 
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE" 

  tags = {
    Name        = "ProcessedDataTable"
    Environment = "dev" 
  }
}

resource "aws_iam_role" "lambda_dynamodb_role" {
  name               = "lambda_dynamodb_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  # Attach policies for accessing DynamoDB
  inline_policy {
    name = "dynamodb_access_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:GetItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem",
            "dynamodb:Scan",
            "dynamodb:Query"
          ]
          Resource = aws_dynamodb_table.processed_data.arn
        }
      ]
    })
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

