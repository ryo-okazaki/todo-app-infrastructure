############################
# Common Modules
############################
tf-fmt-mods:
	terraform -chdir=terraform/modules fmt -recursive

############################
# Development Environment
############################
tf-init-dev:
	terraform -chdir=terraform/environments/development init -backend-config=development.tfbackend

tf-fmt-dev:
	terraform -chdir=terraform/environments/development fmt

tf-vali-dev:
	terraform -chdir=terraform/environments/development validate

tf-plan-dev:
	terraform -chdir=terraform/environments/development plan -var-file=terraform.tfvars

tf-apply-dev:
	terraform -chdir=terraform/environments/development apply -var-file=terraform.tfvars

tf-destroy-dev:
	terraform -chdir=terraform/environments/development destroy -var-file=terraform.tfvars

tf-out-dev:
	terraform -chdir=terraform/environments/development output

tf-state-dev:
	terraform -chdir=terraform/environments/development state list
