terraform {
  backend "s3" {
    bucket = "my-pyterraform-app-state-bucket"
    key    = "ecs/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}




resource "aws_db_subnet_group" "default" {
  name       = "my-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "mydb" {
  identifier              = "my-python-db"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  engine_version          = "8.0.32"
  allocated_storage       = 20
  db_name                 = "myappdb"
  username                = var.db_username
  password                = var.db_password
  publicly_accessible     = true
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name

  tags = {
    Name = "MyPythonAppDB"
  }
}

data "aws_secretsmanager_secret" "db_secret" {
  name = "myapp-db-credentials"
}

data "aws_iam_policy_document" "db_secret_access" {
  statement {
    effect = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.db_secret.arn]
  }
}

resource "aws_iam_policy" "db_secret_access_policy" {
  name   = "MyAppDBSecretAccess"
  policy = data.aws_iam_policy_document.db_secret_access.json
}
