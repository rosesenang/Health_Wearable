# Health_Wearable
Launchpad project

## Project Overview
The Health Wearables IoT System is an MVP for a scalable, resilient IoT platform designed to monitor health metrics, such as heart rate, using wearables. The project integrates AWS cloud services to create a real-time monitoring and alerting system. It includes use cases like abnormal heart rate detection, device connectivity monitoring, and data visualization. This system is optimized for modularity, allowing easy future expansion with additional health-related IoT devices.

## Key Features
- **Abnormal Heart Rate Detection and Notification**: Monitors heart rate and triggers alerts on abnormal values.
- **Device Connectivity Monitoring**: Ensures reliable device connectivity and generates alerts for any disruptions.
- **Real-Time Data Streaming and Visualization**: Streams and displays live health metrics for real-time analysis.

## Technologies Used
- **Backend**: Python (for Lambda functions)
- **Infrastructure**: AWS Cloud (Kinesis, Lambda, DynamoDB, CloudWatch, SNS, VPC, S3)
- **Infrastructure as Code**: Terraform
- **Database**: DynamoDB
- **Event Processing**: Kinesis Streams and AWS Lambda

## Architecture
The project architecture includes:
- **Event Bus**: Kinesis Data Stream for real-time event streaming.
- **Compute**: Lambda functions for data processing and alerting.
- **Database**: DynamoDB for storing device data and health information.
- **Monitoring and Logging**: CloudWatch for logs, metrics, and alarms.

## Project Structure
```plaintext
├── terraform/                  
│   ├── backend.tf              
│   ├── providers.tf            
├── modules/
│   ├── vpc/                    
│        ├──── main.tf
│        ├──── variables.tf
│        ├──── outputs.tf
│   ├── event_bus/
│        ├──── main.tf
│        ├──── variables.tf
│        ├──── outputs.tf              
└── README.md                   
