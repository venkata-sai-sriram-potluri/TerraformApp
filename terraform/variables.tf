variable "region" {
  default = "us-east-2"
}

variable "aws_account_id" {}
variable "ecr_repo" {}
variable "ecs_cluster_name" {
  default = "flask-cluster"
}
variable "ecs_task_family" {
  default = "flask-task"
}
variable "ecs_service_name" {
  default = "flask-service"
}
variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}