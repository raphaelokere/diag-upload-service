resource "aws_vpc" "ecs_vpc" {
  cidr_block = "${var.cidr}"

  tags = {
    Name = "ecs-vpc"
  }
}

# PUBLIC SUBNETS
resource "aws_subnet" "public_subnets" {
  count                   = length(var.azs)
  vpc_id                  = "${aws_vpc.ecs_vpc.id}"
  availability_zone       = "${var.azs[count.index]}"
  cidr_block              = "${var.subnets[count.index]}"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnets"
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.ecs_vpc.id}"

  tags = {
    Name = "ecs-internet-gateway"
  }
}

# TABLE FOR PUBLIC SUBNETS
resource "aws_route_table" "public_table" {
  vpc_id = "${aws_vpc.ecs_vpc.id}"
}

resource "aws_route" "public_route" {
  route_table_id         = "${aws_route_table.public_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.internet_gateway.id}"
}

resource "aws_route_table_association" "route_table_association" {
  count          = length(var.azs)
  route_table_id = "${aws_route_table.public_table.id}"
  subnet_id      = "${aws_subnet.public_subnets[count.index].id}"
}

# SG FOR ECS SERVICE
resource "aws_security_group" "sg1" {
  name        = "ecs_sg"
  description = "Port 5000"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description      = "Allow Port 8000"
    from_port        = 8000
    to_port          = 8000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG FOR ALB
resource "aws_security_group" "sg2" {
  name        = "golang-server-alb"
  description = "Port 80"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description      = "Allow Port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# THE ALB
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg2.id]
  subnets            = ["${aws_subnet.public_subnets[0].id}", "${aws_subnet.public_subnets[1].id}"]

}

# ALB TARGET GROUP
resource "aws_lb_target_group" "alb_tg" {
  name        = "alb-tg"
  port        = "8000"
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.ecs_vpc.id}"
  target_type = "ip"

}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = "${aws_lb.app_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.alb_tg.arn}"
  }
}
