resource "aws_vpc" "main" {
  cidr_block           = "11.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 1)
  availability_zone       = element(["us-east-2a", "us-east-2b"], count.index)
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role - for app container to access Secrets Manager
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_secrets_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.db_secret_access_policy.arn
}

# Attach the Secrets Manager policy to execution role too, in case you want to fetch secrets during startup
resource "aws_iam_role_policy_attachment" "ecs_secret_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.db_secret_access_policy.arn
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/flask-app"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "flask" {
  family                   = var.ecs_task_family
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "flask-app",
      image     = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repo}:latest",
      portMappings = [
        {
          containerPort = 5000,
          hostPort      = 5000,
          protocol      = "tcp"
        }
      ],
       secrets = [
        {
          name      = "DB_SECRET"
          valueFrom = "arn:aws:secretsmanager:us-east-2:418272754287:secret:myapp-db-credentials-z2by6s"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      },
      essential = true
    }
  ])
}

resource "aws_ecs_service" "flask" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.flask.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.public[*].id
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }
}


# You (root user) can create a house (RDS + Secret), but the person (ECS task) who moves in needs a key (IAM permissions) to open the door (Secrets Manager).