resource "aws_security_group" "rds_sg" {
  name        = "rds-access"
  description = "Allow MySql access from my ip"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["47.188.229.229/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "RDS Security Group"
  }
}