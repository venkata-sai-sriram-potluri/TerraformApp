terraform {
  backend "s3" {
    bucket = "my-pyterraform-app-state-bucket"
    key    = "ecs/terraform.tfstate"
    region = "us-east-2"
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "random_password" "db_password" {
  length          = 16
  special         = true
  override_special = "!#$%&'()*+,-.:;<=>?[]^_`{|}~"
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
  username                = "User1"
  password                = random_password.db_password.result
  publicly_accessible     = true
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name

  tags = {
    Name = "MyPythonAppDB"
  }
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "myapp-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    host     = aws_db_instance.mydb.address,
    username = "User1",
    password = random_password.db_password.result,
    database = "myappdb"
  })
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "db_secret_access" {
  statement {
    effect = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:us-east-2:${data.aws_caller_identity.current.account_id}:secret:myapp-db-credentials*"
    ]
  }
}

resource "aws_iam_policy" "db_secret_access_policy" {
  name   = "MyAppDBSecretAccess"
  policy = data.aws_iam_policy_document.db_secret_access.json
}
