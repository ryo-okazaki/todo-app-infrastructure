############################
# Common Modules
############################
tf-fmt-mods:
	terraform -chdir=terraform/modules fmt

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
