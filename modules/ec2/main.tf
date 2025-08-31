data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "sonarqube" {
  ami                       = data.aws_ami.ubuntu.id
  instance_type             = var.instance_type
  subnet_id                 = var.public_subnet_ids[0]
  key_name                  = var.key_name
  vpc_security_group_ids    = [aws_security_group.rahulverse_sg.id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  associate_public_ip_address = true
  depends_on = [aws_security_group.rahulverse_sg]

  tags = {
    Name = "${var.environment}-SonarQube-Server"
  }

  user_data = file("${path.module}/../../scripts/install_docker.sh")
}

resource "aws_instance" "nexus" {
  ami                       = data.aws_ami.ubuntu.id
  instance_type             = var.instance_type
  subnet_id                 = var.public_subnet_ids[1]
  key_name                  = var.key_name
  vpc_security_group_ids    = [aws_security_group.rahulverse_sg.id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = {
    Name = "${var.environment}-Nexus-Server"
  }

  associate_public_ip_address = true
  depends_on = [aws_security_group.rahulverse_sg]

  user_data = file("${path.module}/../../scripts/install_docker.sh")
}

resource "aws_security_group" "rahulverse_sg" {
  name        = "${var.environment}-security-group"
  description = "Allow SSH, SonarQube and Nexus traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # restrict in real use
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-security-group"
  }
}
