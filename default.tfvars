region          = "eu-west-1"
az_count        = "3"
master-ec2-type = "t2.medium"
node-ec2-type   = "t2.large"
kube_version    = "v1.4.6_coreos.0"
cluster-name    = "demo-cluster"
etcd-nodes      = [
  "52.30.26.51",
  "52.209.45.37",
  "52.51.16.222"
]
