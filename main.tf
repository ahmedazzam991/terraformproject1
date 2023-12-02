# Provider Configuration
provider "aws" {
  region = "eu-north-1"
}

# Resource Configuration
resource "aws_s3_bucket" "terraform_state" {
  bucket = "azzamterraform991"
  acl    = "private"

  versioning {
    enabled = true
  }

  # Add other configurations as needed
}
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "azzam991991"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}


# vpc.tf

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}



resource "aws_sns_topic" "web_server_notifications" {
  name = "WebServerNotificationsTopic"
  display_name = "Web Server Notifications Topic"
}


resource "aws_iam_role" "web_server_role" {
  name = "WebServerIAMRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "web_server_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  # Adjust the policy as needed
  role       = aws_iam_role.web_server_role.name
}





