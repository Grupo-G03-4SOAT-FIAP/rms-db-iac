provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "rms-prod-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

resource "aws_db_subnet_group" "rms" {
  name       = "rms-prod-subnetgroup"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

resource "aws_security_group" "rds" {
  name   = "rms-prod-securitygroup"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

resource "aws_db_parameter_group" "rms" {
  name   = "rms-prod-paramgroup"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "0" # Desativa o SSL obrigatório
  }
}

resource "aws_db_instance" "rms" {
  identifier             = "rms-prod-postgres-standalone"
  instance_class         = "db.t3.micro" # A instance_class do Free Tier é db.t3.micro
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "16.1"
  username               = "postgres"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rms.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.rms.name
  publicly_accessible    = true
  skip_final_snapshot    = true

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
