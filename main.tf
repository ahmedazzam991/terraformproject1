# main.tf

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



