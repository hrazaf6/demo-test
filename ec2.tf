
resource "aws_key_pair" "web" {
  key_name   = "test_lab_1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkaDKhXLAbgQqZxcOrPNLtZ+YkNotWTI+4JQO4uFl3mIcgnrCHHe/8VToM4P7YbdzoAX0blB830kcKZO6p0HcB+dXFWbcN5WVVMTZOYRgMlfirzGOPskULKnzdoJlsPE+Zlol9UbP5B+McyiPBOAujMWcp7i6frurSLT1EaHaDCbDvDRXAAqK6rh90wUCa68IsHHPFrrsVj4y0Qe1B97V+ubYWDdxKSGGLzeBVym9elbqmMr7Su1MPPxCytseAcj5K3iuudFwOQNfiE2myxP5eLkOK5daywLuCsn0vjoiH0ILGh71c29RW+mgAf68OSj5MznKo8E1b3+c0dpL5jMlB vagrant@hashicorp"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/webserver.sh")}"
}

resource "aws_security_group" "web" {
  name        = "test_lab"
  vpc_id      = "vpc-fe398a84"
  description = "Security group for the EC2 and ELB"

  #HTTPS access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.anywhere}"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.anywhere}"]
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.anywhere}"]
  }

  tags {
    Name            = "test_lab"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-035be7bafff33b6b6"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.web.id}"
  user_data = "${data.template_file.user_data.rendered}"
  security_groups = ["${aws_security_group.web.name}"]
  tags = {
    Name = "WebServer"
  }
}

resource "aws_elb" "web" {
  name               = "test-lab"
  availability_zones = ["us-east-1c"]
  security_groups = ["${aws_security_group.web.id}"]

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 80
    lb_protocol        = "http"
  }

  tags = {
    Name = "test-lab"
  }
}

resource "aws_elb_attachment" "web" {
  elb      = "${aws_elb.web.name}"
  instance = "${aws_instance.web.id}"
}

output "dns_name" {
  value = "${aws_elb.web.dns_name}"
}
