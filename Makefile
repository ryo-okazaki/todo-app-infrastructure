############################
# Common Modules
############################
TF_DEV_DIR=terraform/environments/development
TF_DEV_VARS=-var-file=terraform.tfvars

############################
# Common Modules
############################
tf-fmt-mods:
	terraform -chdir=terraform/modules fmt -recursive

############################
# Development Environment
############################
tf-init-dev:
	terraform -chdir=$(TF_DEV_DIR) init -backend-config=development.tfbackend

tf-fmt-dev:
	terraform -chdir=$(TF_DEV_DIR) fmt

tf-vali-dev:
	terraform -chdir=$(TF_DEV_DIR) validate

tf-plan-dev:
	terraform -chdir=$(TF_DEV_DIR) plan $(TF_DEV_VARS)

tf-apply-dev:
	terraform -chdir=$(TF_DEV_DIR) apply $(TF_DEV_VARS)

tf-destroy-dev:
	terraform -chdir=$(TF_DEV_DIR) destroy $(TF_DEV_VARS)

tf-out-dev:
	terraform -chdir=$(TF_DEV_DIR) output

tf-state-dev:
	terraform -chdir=$(TF_DEV_DIR) state list
