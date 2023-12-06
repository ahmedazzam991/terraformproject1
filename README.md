# Terraform AWS Apache Web Server Deployment

## Goal

The goal of this project is to use Terraform Infrastructure as Code (IaC) to deploy an Apache web server on the AWS cloud. The project covers the creation of various AWS resources, including S3 buckets, DynamoDB, VPC networks, IAM roles, Golden AMI, Auto Scaling Groups, and more.

## Pre-Requisites

### Create Terraform Infrastructure for State Management

1. **S3 Bucket for Terraform State Files:**
   - Create an S3 bucket to store Terraform state files securely.

2. **DynamoDB:**
   - Create a DynamoDB table for state locking.

3. **VPC Network Deployment:**
   - Deploy a VPC network using Terraform IaC and keep the state file in the S3 backend.

### Create Resources for Web Server Configuration

1. **S3 Bucket for Web Server Configuration:**
   - Create an S3 bucket to store web server configuration files, including `index.html` and Ansible Playbook.

2. **SNS Topic for Notifications:**
   - Create an SNS topic for receiving notifications.

3. **IAM Role:**
   - Set up an IAM role for necessary permissions.

4. **Golden AMI:**
   - Create a Golden Amazon Machine Image for deployment.

5. **Ansible Playbook:**
   - Prepare an Ansible Playbook to configure the Apache web server.

## Deployment

1. **IAM Role Configuration for Access:**
   - Write Terraform IaC to create an IAM role granting PUT/GET access to the S3 bucket and Session Manager access.

2. **Launch Configuration with User Data:**
   - Create a launch configuration with a user data script to pull the `index.html` file from S3, attach the IAM role, and configure the web server. Optionally, run the Ansible Playbook.

3. **Auto Scaling Group:**
   - Deploy an Auto Scaling Group with Min: 1, Max: 1, Desired: 1 in a private subnet.

4. **Target Group:**
   - Create a Target Group with health checks and attach it to the Auto Scaling Group.

5. **Application Load Balancer:**
   - Set up an Application Load Balancer in a public subnet and configure a listener port to route traffic to the Target Group.

6. **Alias Record in Hosted Zone:**
   - Create an alias record in the hosted zone to route traffic to the Load Balancer from the public network.

7. **CloudWatch Alarms:**
   - Implement CloudWatch Alarms to send notifications when the Auto Scaling Group state changes.

8. **Scaling Policies:**
   - Configure Scaling Policies to scale out/scale in when average CPU utilization is greater than 80%.

9. **Deploy Terraform IaC:**
   - Run Terraform IaC to create the resources in the VPC, keeping the state file in the S3 backend with state locking support.

## Validation

1. **AWS Console Login:**
   - Log in to the AWS Console and verify that all resources have been successfully deployed.

2. **Web Application Access:**
   - Access the web application from a public internet browser using the provided domain name.

## Destroy

1. **Destroy Resources:**
   - Once testing is complete, run Terraform IaC with `terraform destroy` for each set of Terraform files to destroy the resources and save on billing.


Project reference : https://devopsrealtime.com/deploy-apache-web-server-using-terraform-iac/


