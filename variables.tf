variable "region"          {}
variable "az_count"        {}
variable "master-ec2-type" {}
variable "node-ec2-type"   {}
variable "kube_version"    {}
variable "cluster-name"    {}
variable "etcd-nodes"      {type = "list"}