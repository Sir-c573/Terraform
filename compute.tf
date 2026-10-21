# Latest Amazon Linux 2023 AMI (looked up via the EC2 API)
#template used to create an EC2 instance. It contains the operating system and other software needed to launch the machine.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ---------------------------------------------------------------------------
# Security groups
# ---------------------------------------------------------------------------

# Public EC2 (bastion-style): SSH only.
# Hardcoded to anywhere for the homework - restrict to your own IP/32 in real use.
resource "aws_security_group" "public_ec2" {
  name        = "hw-public-ec2-sg"
  description = "SSH to the public instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "hw-public-ec2-sg" }
}

# Private EC2: SSH only from the public instance's security group
resource "aws_security_group" "private_ec2" {
  name        = "hw-private-ec2-sg"
  description = "SSH from the public instance only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from public instance"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "hw-private-ec2-sg" }
}

# ---------------------------------------------------------------------------
# One EC2 instance per subnet
# ---------------------------------------------------------------------------

resource "aws_instance" "public" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.public_ec2.id]

  tags = { Name = "hw-public-instance" }
}

resource "aws_instance" "private" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.private_ec2.id]

  tags = { Name = "hw-private-instance" }
}