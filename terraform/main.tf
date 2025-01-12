provider "aws" {
  region = "us-east-1" 
  
}

# Security Group
resource "aws_security_group" "instance_sg" {

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22000
    to_port     = 22000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1     
    to_port     = -1     
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create database Master
resource "aws_instance" "dbMaster" {
  ami           = "ami-04505e74c0741db8d"  # Ubuntu 22.04 AMI for us-east-1
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name      = "CCS"


  associate_public_ip_address = true

  tags = {
    Name = "CCS-Database-Master"
  }
  
  provisioner "file" {
      source      = "/home/ubuntu/CCS.pem" # File lokal Anda
      destination = "/home/ubuntu/CCS.pem" # Lokasi di instance EC2
  }

  connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/ubuntu/CCS.pem") 
      host        = self.public_ip
  }

}

resource "null_resource" "inventory_dbMaster" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "[dbMaster]" >> ../ansible/inventory.txt
      echo "dbMaster ansible_host=${aws_instance.dbMaster.public_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/CCS.pem private_ip=${aws_instance.dbMaster.private_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> ../ansible/inventory.txt
    EOT
  }
}

# Create Database Slave
resource "aws_instance" "dbSlave" {
  ami           = "ami-04505e74c0741db8d"  # Ubuntu 22.04 AMI for us-east-1
  instance_type = "t2.micro"
  count         = 2
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name      = "CCS"


  associate_public_ip_address = true

  tags = {
    Name = "CCS-Database-Slave-${count.index+1}"
  }
  
}

resource "null_resource" "inventory_dbSlave" { 
  provisioner "local-exec" {
    command = <<EOT
    echo "[dbSlave]" >> ../ansible/inventory.txt
    x=0
    %{ for instance in aws_instance.dbSlave }
    x=$((x + 1))
    echo "dbSlave$x ansible_host=${instance.public_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/CCS.pem private_ip=${instance.private_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> ../ansible/inventory.txt
    %{ endfor }
    EOT
  }

}

# Create an EC2 instance
resource "aws_instance" "phpMyAdmin" {
  ami           = "ami-04505e74c0741db8d"  # Ubuntu 22.04 AMI for us-east-1
  instance_type = "t2.micro"
  count         = 2
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name      = "CCS"


  associate_public_ip_address = true

  tags = {
    Name = "CCS-phpMyAdmin-${count.index+1}"
  }
  
}

# Save inventory with Elastic IP
resource "null_resource" "inventory_phpMyAdmin" {
  provisioner "local-exec" {
    command = <<EOT
    echo "[phpMyAdmin]" >> ../ansible/inventory.txt
    x=0
    %{ for instance in aws_instance.phpMyAdmin }
    x=$((x + 1))
    echo "phpMyAdmin$x ansible_host=${instance.public_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/CCS.pem private_ip=${instance.private_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> ../ansible/inventory.txt
    %{ endfor }
    EOT
  }

}

resource "aws_instance" "haproxy" {
  ami           = "ami-04505e74c0741db8d"  # Ubuntu 22.04 AMI for us-east-1
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name      = "CCS"


  associate_public_ip_address = true

  tags = {
    Name = "CCS-Haproxy"
  }
  
}

resource "null_resource" "inventory_haproxy" {
  provisioner "local-exec" {
    command = <<EOT
    echo "[haproxy]" >> ../ansible/inventory.txt
    echo "haproxy ansible_host=${aws_instance.haproxy.public_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/CCS.pem private_ip=${aws_instance.haproxy.private_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> ../ansible/inventory.txt
    EOT
  }

}

resource "aws_instance" "DNS" {
  ami           = "ami-04505e74c0741db8d"  # Ubuntu 22.04 AMI for us-east-1
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name      = "CCS"


  associate_public_ip_address = true

  tags = {
    Name = "CCS-DNS"
  }
  
}

resource "null_resource" "inventory_DNS" { 
  provisioner "local-exec" {
    command = <<EOT
    echo "[DNS]" >> ../ansible/inventory.txt
    echo "DNS ansible_host=${aws_instance.DNS.public_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/CCS.pem private_ip=${aws_instance.DNS.private_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> ../ansible/inventory.txt
    EOT
  }

}

# output "php_public_ip" {
#   value = aws_instance.phpMyAdmin.public_ip
# }