# backend.tf
terraform {
  backend "s3" {
    bucket         = "iot-proj-terraform-state-bucket"    # S3 bucket name
    key            = "health-wearables-iot/terraform.tfstate"
    region         = "eu-west-2"                      # Region
    dynamodb_table = "terraform-state-lock"           # DynamoDB table for state locking
    encrypt        = true                             # Encrypts the state file at rest
  }
}

