all: plan apply

VARFILE=default.tfvars

plan:
	terraform plan -out=.plan -var-file=$(VARFILE)

apply:
	terraform apply .plan

destroy:
	terraform destroy -var-file=$(VARFILE) -force

.PHONY: plan apply destroy