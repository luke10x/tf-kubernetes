resource "aws_iam_role" "node-role" {

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

resource "aws_iam_instance_profile" "node-profile" {

  name = "node-profile"
  roles = ["${aws_iam_role.node-role.name}}"]
}

resource "aws_iam_role_policy_attachment" "node-role-policy" {

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role = "${aws_iam_role.node-role.name}"
}

resource "aws_launch_configuration" "node-config" {

  image_id = "${data.aws_ami.kube-node-ami.image_id}"
  instance_type = "${var.node-ec2-type}"
  name_prefix = "node-"
  key_name = "${aws_key_pair.kube-node-key.key_name}"
  security_groups = ["${aws_security_group.kube-node-sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.node-profile.id}"
  associate_public_ip_address = false
  user_data = "${data.template_file.node-cloud-config.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "node-group" {

  launch_configuration = "${aws_launch_configuration.node-config.id}"
  max_size = "${var.az_count * 10}"
  min_size = "${var.az_count}"
  desired_capacity = "${var.az_count}"
  vpc_zone_identifier = ["${aws_subnet.kube-az-subnet-priv.*.id}"]

  tag {
    key = "Name"
    value = "node"
    propagate_at_launch = true
  }
}

data "template_file" "node-cloud-config" {

  template = "${file("${path.module}/assets/node.tpl")}"
  vars {
    kubelet_unit = "${base64encode(data.template_file.kubelet_unit.rendered)}"
    kube_api     = "https://${aws_route53_record.api-endpoint.fqdn}"
  }
}
