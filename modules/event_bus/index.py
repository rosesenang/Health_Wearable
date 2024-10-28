import os
import json
import boto3

sns_client = boto3.client("sns")

def handler(event, context):
    sns_topic_arn = os.getenv("SNS_TOPIC_ARN")
    
    # Parse event detail
    heart_rate = event["detail"].get("heartRate")
    
    if heart_rate and heart_rate > 100:  # Threshold is customizable
        message = f"Alert: Abnormal heart rate detected - {heart_rate} bpm."
        
        # Publish to SNS topic
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Message=message,
            Subject="Abnormal Heart Rate Alert"
        )
        
    return {
        "statusCode": 200,
        "body": json.dumps("Event processed successfully.")
    }

