# Provider Configuration
provider "aws" {
  region = "eu-north-1"
}

# Resource Configuration - Create S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "azzamterraform991"
  acl    = "private"

  versioning {
    enabled = true
  }
}

# DynamoDB Configuration
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

# VPC Configuration
resource "aws_vpc" "my_vpc" {
  cidr_block          = "10.0.0.0/16"
  enable_dns_support  = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

# SNS Configuration
resource "aws_sns_topic" "web_server_notifications" {
  name        = "WebServerNotificationsTopic"
  display_name = "Web Server Notifications Topic"
}

# IAM Role Configuration for Web Server
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

# IAM Policy Attachment for Web Server Role
resource "aws_iam_role_policy_attachment" "web_server_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.web_server_role.name
}

# IAM Role and Policy Configuration for S3 and Session Manager
resource "aws_iam_role" "s3_and_session_manager_role" {
  name = "S3AndSessionManagerRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "s3_and_session_manager_policy" {
 
}

resource "aws_iam_role_policy" "s3_and_session_manager_policy" {
  name   = "s3_and_session_manager_policy"
  role   = aws_iam_role.s3_and_session_manager_role.name
  policy = data.aws_iam_policy_document.s3_and_session_manager_policy.json
}

# S3 Bucket Configuration for Web Server
resource "aws_s3_bucket" "webserver_config" {
  bucket = "webserver-config-bucket"
  acl    = "private"
}







# EC2 Instance Configuration
resource "aws_instance" "golden_instance" {
  ami           = "ami-0416c18e75bd69567"
  instance_type = "t2.micro"

  tags = {
    Name = "GoldenInstance"
  }
}

# Volume Attachment Configuration for Snapshot
resource "aws_volume_attachment" "golden_instance_volume_attachment" {
  device_name = "/dev/sda1"
  volume_id   = aws_instance.golden_instance.root_block_device[0].volume_id
  instance_id = aws_instance.golden_instance.id
}

# Snapshot Configuration
resource "aws_ami" "golden_ami" {
  name               = "GoldenAMI"
  description        = "Golden Amazon Machine Image"
  virtualization_type = "hvm"
  root_device_name   = "/dev/sda1"

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 8
  }

  tags = aws_instance.golden_instance.tags
}

# Cleanup Configuration
resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.golden_instance.id}"
  }

  depends_on = [aws_ami.golden_ami]
}

