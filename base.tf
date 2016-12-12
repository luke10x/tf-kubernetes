provider "aws" {

  region = "${var.region}"
}

data "aws_availability_zones" "azs" {}

data "aws_ami" "kube-node-ami" {

  most_recent = true
  filter {
    name = "name"
    values = ["CoreOS-stable-*"]
  }
  owners = ["595879546273"]
}

resource "tls_private_key" "ssh-key" {

  algorithm = "RSA"
  provisioner "local-exec" {
    command = "echo '${tls_private_key.ssh-key.private_key_pem}' > key.pem && chmod 0600 key.pem && ssh-add key.pem"
  }
}

resource "aws_key_pair" "kube-node-key" {

  key_name = "coreos-node"
  public_key = "${tls_private_key.ssh-key.public_key_openssh}"
}

resource "aws_instance" "bastion-node" {

  ami = "${data.aws_ami.kube-node-ami.image_id}"
  instance_type = "t2.medium"
  subnet_id = "${aws_subnet.kube-az-subnet-pub.0.id}"
  vpc_security_group_ids = ["${aws_security_group.kube-node-sg.id}"]
  key_name = "${aws_key_pair.kube-node-key.key_name}"
  tags {
    Name = "bastion"
  }
}

resource "aws_eip_association" "bastion-eip" {

  instance_id = "${aws_instance.bastion-node.id}"
  allocation_id = "${aws_eip.kube-bastion-eip.id}"
}

data "template_file" "kubelet_unit" {

  template = "${file("${path.module}/assets/kubeunit.tpl")}"

  vars {
    kube_version = "${var.kube_version}"
    etcd_servers = "${join(",", formatlist("http://%s:2379/", var.etcd-nodes))}"
  }
}