resource "aws_iam_role" "master-role" {

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "master-profile" {

  name = "master-profile"
  roles = ["${aws_iam_role.master-role.name}}"]
}

resource "aws_iam_role_policy_attachment" "master-role-policy" {

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role = "${aws_iam_role.master-role.name}"
}

resource "aws_launch_configuration" "master-config" {

  image_id = "${data.aws_ami.kube-node-ami.image_id}"
  instance_type = "${var.master-ec2-type}"
  name_prefix = "master-"
  key_name = "${aws_key_pair.kube-node-key.key_name}"
  security_groups = ["${aws_security_group.kube-node-sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.master-profile.id}"
  associate_public_ip_address = false
  user_data = "${data.template_file.master-cloud-config.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "master-group" {

  launch_configuration = "${aws_launch_configuration.master-config.id}"
  max_size = "${var.az_count * 3}"
  min_size = "${var.az_count}"
  desired_capacity = "${var.az_count}"
  vpc_zone_identifier = ["${aws_subnet.kube-az-subnet-priv.*.id}"]
  load_balancers = ["${aws_elb.internal-api.id}"]

  tag {
    key = "Name"
    value = "master-node"
    propagate_at_launch = true
  }
}

resource "aws_elb" "internal-api" {

  name = "api-internal"
  cross_zone_load_balancing = true
  subnets = ["${aws_subnet.kube-az-subnet-priv.*.id}"]
  internal = true
  security_groups = [
    "${aws_security_group.kube-node-sg.id}",
    "${aws_security_group.kube-api-sg.id}"
  ]

  tags {
    Name = "api-internal"
  }

  "listener" {
    instance_port = 6443
    instance_protocol = "TCP"
    lb_port = 443
    lb_protocol = "TCP"
  }
}

data "template_file" "master-cloud-config" {

  template = "${file("${path.module}/assets/master.tpl")}"
  vars {
    kubelet_unit = "${base64encode(data.template_file.kubelet_unit.rendered)}"
  }
}
