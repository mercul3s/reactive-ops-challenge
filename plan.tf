# prompt for your aws iam username and account key path.

variable "user_name" {}
variable "key_path" {}

variable "region" {}

// Use AWS as the infrastructure provider, using the default region
provider "aws" {
    region = "${var.region}"
}

locals {
  "account_name" = "${var.user_name}"
  "private_key" = "${var.key_path}"
}

// Create a security group to control which ports are open when the server is
// running. If the server doesn't have a security group with ingress and egress,
// it won't be able to talk to the internet.
resource "aws_security_group" "webserver" {
  
  name = "ro-mercedescoyle"
  description = "Allow inbound traffic"
  
  // ssh access
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description = "ssh access"
  }
  
  // web access
  ingress {
      from_port   = 80 
      to_port     = 80 
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description = "http access"
  }

  // route out to the internet
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

// Define the infrastructure requirements for the webserver.
resource "aws_instance" "webserver" {
    ami           = "ami-0773391ae604c49a4"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    key_name = "${var.user_name}" 
    
    timeouts {
        create = "10m"
        delete = "10m"
    }
   
    tags {
        Name = "${local.account_name}.tech_challenge"
    }
    // Associate the server with the security group.
    vpc_security_group_ids = ["${aws_security_group.webserver.id}"]
}

// Install docker, pull a container, and tell the server to run it in detached
// mode. 
resource "null_resource" "provision_docker" {
    connection {
        host = "${aws_instance.webserver.public_ip}"
        type = "ssh"
        user = "ubuntu"
        agent_identity = "${local.account_name}"
        private_key = "${file("${local.private_key}")}"
    }

    provisioner "remote-exec" {
        inline = [
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
            "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable'",
            "sudo apt-get update",
            "apt-cache policy docker.io",
            "sudo apt-get install -y docker.io",
            "sudo docker pull mercul3s/hello-go:latest",
            "sudo docker run -d -p 80:8000 mercul3s/hello-go:latest"
        ]
    }
}
