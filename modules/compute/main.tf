data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true
  metadata_options { http_tokens = "required" }
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    echo 'Hello from ${var.project} ${var.environment}' > /var/www/html/index.html
    systemctl enable --now httpd
  EOF
  tags      = { Name = "${var.project}-${var.environment}-web" }
}
