provider "aws" {
  profile = "ctl-dev"
}

locals {
  vpc_cidr = "10.0.0.0/16"
}
module "vpc" {
  source    = "./modules/vpc"
  region    = "us-east-1"
  vpc_cidr  = local.vpc_cidr
}

data "aws_secretsmanager_secret" "hasura_secrets" {
  name = "test/Hasura/AdminSecret"
}

data "aws_secretsmanager_secret_version" "hasura_secrets_latest" {
  secret_id = data.aws_secretsmanager_secret.hasura_secrets.id
}

locals {
  rds_password = jsondecode(data.aws_secretsmanager_secret_version.hasura_secrets_latest.secret_string)["HASURA_MAIN_POSTGRES_DB_PASSWORD"]
}

module "rds_cluster" {
  source     = "./modules/rds"
  password   = local.rds_password
  vpc_id     = module.vpc.main_vpc_id
  vpc_cidr   = local.vpc_cidr
  subnet_ids = [module.vpc.subnet1_id, module.vpc.subnet2_id]
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
      environment = [
        {
          name  = "HASURA_MAIN_POSTGRES_DB_ENDPOINT"
          value = module.rds_cluster.rds_endpoint
        },
        {
          name  = "HASURA_MAIN_POSTGRES_DB_NAME"
          value = module.rds_cluster.rds_db_name
        },
        {
          name  = "HASURA_MAIN_POSTGRES_DB_USERNAME"
          value = module.rds_cluster.rds_username
        },
      ]
      secrets = [
        {
          name      = "HASURA_GRAPHQL_ADMIN_SECRET"
          valueFrom = data.aws_secretsmanager_secret.hasura_secrets.arn
        },
        {
          name      = "HASURA_MAIN_POSTGRES_DB_PASSWORD"
          valueFrom = data.aws_secretsmanager_secret.hasura_secrets.arn
        },
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
