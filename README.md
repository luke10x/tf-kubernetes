# tf-kubernetes

Before building the cluster, make sure you have AWS credentials configured.

If not using a default AWS profile, set the right credentials using ```export AWS_PROFILE=<profile-name>```

To build the cluster, do:
```
    make plan
    make apply
```

To destroy the cluster and clean-up, do:
```
    make destroy
```