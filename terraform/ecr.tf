resource "aws_ecr_repository" "flask-app" {
  name                 = "flask-app"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "flask-app"
  }
}
#