resource "aws_route53_zone" "cluster-private" {

  name = "${var.cluster-name}.k8s"
  vpc_id = "${aws_vpc.kube-vpc.id}"
  tags {
    Name = "private-zone"
  }
}

resource "aws_route53_record" "api-endpoint" {

  name = "api"
  type = "A"
  zone_id = "${aws_route53_zone.cluster-private.id}"
  alias {

    evaluate_target_health = false
    name = "${aws_elb.internal-api.dns_name}"
    zone_id = "${aws_elb.internal-api.zone_id}"
  }
}
