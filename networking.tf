resource "aws_vpc" "kube-vpc" {

  cidr_block = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_vpc_dhcp_options" "kube-cluster" {
  domain_name = "${var.cluster-name}.k8s"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "kube-cluster-vpc" {

  dhcp_options_id = "${aws_vpc_dhcp_options.kube-cluster.id}"
  vpc_id = "${aws_vpc.kube-vpc.id}"
}

resource "aws_subnet" "kube-az-subnet-priv" {

  count = "${var.az_count}"
  cidr_block = "${cidrsubnet(aws_vpc.kube-vpc.cidr_block, 8, count.index)}"
  vpc_id = "${aws_vpc.kube-vpc.id}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "kube-az-subnet-pub" {

  count = "${var.az_count}"
  cidr_block = "${cidrsubnet(aws_vpc.kube-vpc.cidr_block, 8, count.index + var.az_count )}"
  vpc_id = "${aws_vpc.kube-vpc.id}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "kube-igw" {

  vpc_id = "${aws_vpc.kube-vpc.id}"
}

resource "aws_eip" "kube-nat-eip" {

  count = "${var.az_count}"
  vpc = true
}

resource "aws_eip" "kube-bastion-eip" {

  vpc = true
}

resource "aws_nat_gateway" "kube-nat-gw" {

  count = "${var.az_count}"
  allocation_id = "${aws_eip.kube-nat-eip.*.id[count.index]}"
  subnet_id = "${aws_subnet.kube-az-subnet-pub.*.id[count.index]}"
  depends_on = ["aws_internet_gateway.kube-igw"]
}

resource "aws_route_table" "kube-az-route" {

  count = "${var.az_count}"
  vpc_id = "${aws_vpc.kube-vpc.id}"
  route {
    nat_gateway_id = "${aws_nat_gateway.kube-nat-gw.*.id[count.index]}"
    cidr_block = "0.0.0.0/0"
  }
  tags {
    name = "private"
  }
}

resource "aws_route_table_association" "kube-subnet-route" {

  count = "${var.az_count}"
  route_table_id = "${aws_route_table.kube-az-route.*.id[count.index]}"
  subnet_id = "${aws_subnet.kube-az-subnet-priv.*.id[count.index]}"
}

resource "aws_route_table_association" "bastion-route" {

  count = "${var.az_count}"
  route_table_id = "${aws_vpc.kube-vpc.default_route_table_id}"
  subnet_id = "${aws_subnet.kube-az-subnet-pub.*.id[count.index]}"
}

resource "aws_default_route_table" "default-route" {

  default_route_table_id = "${aws_vpc.kube-vpc.default_route_table_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.kube-igw.id}"
  }
}

resource "aws_security_group" "kube-node-sg" {

  vpc_id = "${aws_vpc.kube-vpc.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self = true
  }
}

resource "aws_security_group" "kube-api-sg" {

  vpc_id = "${aws_vpc.kube-vpc.id}"
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}