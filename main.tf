provider "aws" {
  profile = "ctl-dev"
}

module "vpc" {
  source    = "./modules/vpc"
  region    = "us-east-1"
  vpc_cidr  = "10.0.0.0/16"
}

# module "rds_cluster" {
#   source = "./modules/rds"

# }

data "aws_secretsmanager_secret" "hasura_admin_secret" {
  name = "test/Hasura/AdminSecret"
}

data "aws_secretsmanager_secret_version" "hasura_admin_secret_latest" {
  secret_id = data.aws_secretsmanager_secret.hasura_admin_secret.id
}

resource "aws_ecs_cluster" "hasura_cluster" {
  name = "hasura-cluster"
}

resource "aws_ecs_task_definition" "hasura" {
  family                   = "hasura"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "hasura"
      image = "538208764089.dkr.ecr.us-east-1.amazonaws.com/docker-hasura:latest"
      ports = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      secrets = [
        {
          name      = "HASURA_GRAPHQL_ADMIN_SECRET"
          valueFrom = "arn:aws:secretsmanager:us-east-1:538208764089:secret:test/Hasura/AdminSecret-Acog7B"
        }
      ]
    }
  ])
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}
