variable "allocated_storage" {
  type    = number
  default = 20
}
variable "storage_type" {
  type    = string
  default = "gp2"
}
variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "username" {
  type    = string
  default = "postgres"
}
variable "password" {
  type = string
}

variable "vpc_id" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "subnet_ids" {
  description = "List of subnet IDs for the RDS cluster"
  type = list(string)
}

resource "aws_db_instance" "rds_postgres" {
  allocated_storage    = var.allocated_storage
  storage_type         = var.storage_type
  engine               = "postgres"
  engine_version       = "16.2"
  instance_class       = var.instance_class
  identifier           = "hasura-rds-instance" # Name for the RDS instance
  db_name              = "hasuradb" # Name for the database within the RDS instance
  username             = var.username
  password             = var.password
  parameter_group_name = "default.postgres16"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
  publicly_accessible = false
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow internal access to RDS PostgreSQL within VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}

output "rds_username" {
  value = var.username
}
output "rds_endpoint" {
  value = aws_db_instance.rds_postgres.endpoint
}
output "rds_db_name" {
  value = aws_db_instance.rds_postgres.db_name
}
