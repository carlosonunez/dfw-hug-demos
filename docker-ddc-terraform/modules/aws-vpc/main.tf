resource "aws_vpc" "vpc" {
  cidr_block = "${var.aws_vpc_cidr_block}"
  tags = {
    Domain = "${var.aws_vpc_dns_domain}"
    Environment = "${var.aws_environment_name}"
  }
}

resource "aws_security_group" "bastion_host" {
  depends_on = ["${aws_vpc.vpc}"]
  name = "vpc-bastion_host-sg"
  description = "Bastion host for instances within this VPC. Managed by Terraform. Manual changes will be reversed."
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = "0.0.0.0/0"
  }
}

resource "aws_security_group" "all_instances" {
  depends_on = ["${aws_vpc.vpc}"]
  name = "${format("%s-access-sg", var.aws_environment_name)}"
  description = "Access policy for instances in the environment specified. Managed by Terraform. Manual changes will be reversed."
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = ["${aws_security_group.bastion_host.id}"]
  }
}

resource "aws_instance" "bastion_host" {
  depends_on = [
    "${aws_security_group.bastion_host}",
    "${aws_security_group.all_instances}",
    "${data.aws_ami.coreos}"
  ]
  ami = "${data.aws_ami.coreos}"
  instance_type = "t2.micro"
  key_name = "${var.aws_environment_name}"
  security_groups = 
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}
