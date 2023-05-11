# Create an ECS cluster
resource "aws_ecs_cluster" "demo_cluster" {
  name = "demo_cluster"
}

# Create an EC2 launch template with required properties
resource "aws_launch_template" "demo_launch_template" {
  name_prefix   = "demo_launch_template"
  image_id      = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = ["sg-0ffb7f7ab882aa8d2"]
  }
}

# Create an IAM role for ECS task execution
resource "aws_iam_role" "task_execution_role" {
  name = "task_execution_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Action"    : "sts:AssumeRole",
      "Effect"    : "Allow",
      "Principal" : {
        "Service" : "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach the necessary policies to the task execution role
resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create an ECS task definition with Apache2 as a container image
resource "aws_ecs_task_definition" "demo_task_definition" {
  family                   = "demo_task_definition"
  container_definitions    = jsonencode([{
    name            = "apache2"
    image           = "httpd:latest"
    essential       = true
    portMappings    = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
  memory                    = 512
  cpu                       = 256
  requires_compatibilities  = ["EC2"]
  network_mode              = "bridge"
  execution_role_arn        = aws_iam_role.task_execution_role.arn
}

# Create an ECS service
resource "aws_ecs_service" "demo_service" {
  name            = "demo_service"
  cluster         = aws_ecs_cluster.demo_cluster.id
  task_definition = aws_ecs_task_definition.demo_task_definition.arn
  desired_count   = 1
  launch_type     = "EC2"
  network_configuration {
    subnets         = ["subnet-00f4982af504e9ec1", "subnet-0884158df4fabe73b"]
    security_groups = ["sg-0ffb7f7ab882aa8d2"]

    launch_template {
      id      = aws_launch_template.demo_launch_template.id
      version = "$Latest"
    }
  }

  # Use the EC2 launch template to launch tasks on EC2 instances
  platform_version = "LATEST"
}
