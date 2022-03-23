# ECS CLUSTER
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "diag-upload-svc"
}

# ECR REPO
resource "aws_ecr_repository" "ecr_repo" {
    name = "diag-svc-repo"
}

# ECS TASK DEFINITION
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "HTTPserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name   = "diag-upload-svc-container"
      image  = "${var.uri_repo}:latest" #URI
      cpu    = 256
      memory = 512
      portMappings = [
        {
          containerPort = 8000
        }
      ]
    }
  ])
}

# ECS SERVICE CONFIGS
resource "aws_ecs_service" "svc" {
  name            = "diag-upload-svc"
  cluster         = "${aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.ecs_task.id}"
  desired_count   = 2
  launch_type     = "FARGATE"


  network_configuration {
    subnets          = ["${aws_subnet.public_subnets[0].id}", "${aws_subnet.public_subnets[1].id}"]
    security_groups  = ["${aws_security_group.sg1.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.alb_tg.arn}"
    container_name   = "diag-upload-svc-container"
    container_port   = "8000"
  }
}

