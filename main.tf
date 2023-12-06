# Provider Configuration
provider "aws" {
  region = "eu-north-1"
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  # other subnet attributes...
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



# Security Group Configuration for EC2 Instances
resource "aws_security_group" "web_server_sg" {
  name        = "web_server_sg"
  description = "Security Group for Web Server"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "web_server_instance_profile" {
  name = "web_server_instance_profile"
  role = aws_iam_role.web_server_role.name
}


# Launch Configuration with user data
resource "aws_launch_configuration" "web_server_launch_config" {
  name = "web_server_launch_config"

  image_id = "ami-0416c18e75bd69567"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.web_server_instance_profile.name

  user_data = <<-EOF
                #!/bin/bash
                apt-get update
                apt-get install -y awscli ansible
              # Download index.html from S3
                aws s3 cp s3://${aws_s3_bucket.webserver_config.bucket}/index.html /var/www/html/index.html

                # Run Ansible playbook to configure web server
                ansible-playbook /path/to/your/ansible/playbook.yml
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_server_asg" {
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  launch_configuration = aws_launch_configuration.web_server_launch_config.name
  vpc_zone_identifier  = ["vpc-00347d84e9692227a"]  # Assuming you have a private subnet
}

# Target Group
resource "aws_lb_target_group" "web_server_target_group" {
  name        = "web-server-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id
  health_check {
    path = "/"
  }
}

# Application Load Balancer
resource "aws_lb" "web_server_lb" {
  name               = "web-server-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_server_sg.id]
  subnets            = [aws_subnet.public_subnet.id]  # Assuming you have a public subnet
}

# Listener for the Load Balancer
resource "aws_lb_listener" "web_server_listener" {
  load_balancer_arn = aws_lb.web_server_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "OK"
    }
  }
}

# Attach Target Group to Auto Scaling Group
resource "aws_autoscaling_attachment" "web_server_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web_server_asg.name
  lb_target_group_arn   = aws_lb_target_group.web_server_target_group.arn
}




# Create Alias Record in Hosted Zone
resource "aws_route53_record" "web_server_dns" {
  name    = "webserver.example.com"
  type    = "A"
  zone_id = "YOUR_HOSTED_ZONE_ID"

  alias {
    name                   = aws_lb.web_server_lb.dns_name
    zone_id                = aws_lb.web_server_lb.zone_id
    evaluate_target_health = true
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "web_server_alarm" {
  alarm_name          = "web_server_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Scale out when CPU > 80% for 10 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_server_asg.name
  }

  alarm_actions = [aws_sns_topic.web_server_notifications.arn]
}

# Scaling Policies
resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale_out_policy"
  scaling_adjustment    = 1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 300
  estimated_instance_warmup = 300
  autoscaling_group_name = aws_autoscaling_group.web_server_asg.name
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "scale_in_policy"
  scaling_adjustment    = -1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 300
  estimated_instance_warmup = 300
  autoscaling_group_name = aws_autoscaling_group.web_server_asg.name
}

resource "aws_autoscaling_policy" "scale_in_cooldown_policy" {
  name                   = "scale_in_cooldown_policy"
  scaling_adjustment    = -1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 900
  estimated_instance_warmup = 900
  autoscaling_group_name = aws_autoscaling_group.web_server_asg.name
}


