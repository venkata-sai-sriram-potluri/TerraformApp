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

terraform {
  backend "s3" {
    bucket         = "my-pyterraform-app-state-bucket"
    key            = "ecs/terraform.tfstate"
    region         = "us-east-2"
  }
}
