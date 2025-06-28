output "ecs_task_ips" {
  value = aws_ecs_service.flask.network_configuration[0].assign_public_ip
}