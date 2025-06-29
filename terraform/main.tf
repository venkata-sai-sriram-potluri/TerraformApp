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
  username                = "User1"
  password                = "Admin123"
  publicly_accessible     = true
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name

  tags = {
    Name = "MyPythonAppDB"
  }
}

# ✅ Add Secrets Manager Secret
resource "aws_secretsmanager_secret" "db_secret" {
  name = "myapp-db-credentials"
}

# ✅ Populate the Secret with DB credentials and endpoint
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    host     = aws_db_instance.mydb.address,
    username = "User1",
    password = "Admin123",
    database = "myappdb"
  })
}

# ✅ IAM policy document to allow reading the secret (attach this to EC2 or ECS role separately)
data "aws_iam_policy_document" "db_secret_access" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.db_secret.arn]
  }
}

resource "aws_iam_policy" "db_secret_access_policy" {
  name   = "MyAppDBSecretAccess"
  policy = data.aws_iam_policy_document.db_secret_access.json
}


terraform {
  backend "s3" {
    bucket         = "my-pyterraform-app-state-bucket"
    key            = "ecs/terraform.tfstate"
    region         = "us-east-2"
  }
}
