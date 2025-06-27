resource "aws_security_group" "rds_sg" {
  name        = "rds-access"
  description = "Allow MySql access from my ip"
  vpc_id      = aws_vpc.main.id 

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
  from_port       = 3306
  to_port         = 3306
  protocol        = "tcp"
  security_groups = [aws_security_group.ecs_sg.id]
  description     = "Allow ECS to access DB"
  }
  tags = {
    Name = "RDS Security Group"
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ECS Security Group"
  }
}