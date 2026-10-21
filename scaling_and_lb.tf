# ---------------------------------------------------------------------------
# Security groups for the load balancers and the ASG instances
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "hw-alb-sg"
  description = "HTTP into the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "hw-alb-sg" }
}

resource "aws_security_group" "asg" {
  name        = "hw-asg-sg"
  description = "HTTP into the ASG instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from the ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # The NLB (instance targets) has no security group and preserves the client
  # IP, so traffic arrives from the original client address. Port 80 must
  # therefore be open to the world. The instances are still private (no public
  # IP), so they are only reachable through the load balancers.
  ingress {
    description = "HTTP from NLB (client IP preserved)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "hw-asg-sg" }
}

# ---------------------------------------------------------------------------
# Launch template + Auto Scaling Group (in the private subnets, 2 AZs)
# ---------------------------------------------------------------------------

resource "aws_launch_template" "web" {
  name_prefix   = "hw-web-"
  image_id      =  data.aws_ami.al2023.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.asg.id]

  # Installs a tiny web server; needs the NAT Gateway to reach the internet.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd
    echo "Hello from $(hostname -f)" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "hw-asg-instance" }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "hw-asg"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # Registers instances with BOTH target groups
  target_group_arns = [
    aws_lb_target_group.alb.arn,
    aws_lb_target_group.nlb.arn,
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Make sure the NAT route exists before instances boot and run user_data
  depends_on = [aws_route_table_association.private_a, aws_route_table_association.private_b]
}

# ---------------------------------------------------------------------------
# Application Load Balancer (HTTP, layer 7)
# ---------------------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "hw-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = { Name = "hw-alb" }
}

resource "aws_lb_target_group" "alb" {
  name     = "hw-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}

# ---------------------------------------------------------------------------
# Network Load Balancer (TCP, layer 4)
# ---------------------------------------------------------------------------

resource "aws_lb" "nlb" {
  name               = "hw-nlb"
  load_balancer_type = "network"
  internal           = false
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = { Name = "hw-nlb" }
}

resource "aws_lb_target_group" "nlb" {
  name     = "hw-nlb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "nlb_tcp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb.arn
  }
}