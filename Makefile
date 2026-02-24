SHELL := /bin/bash
STACK_GCP := stacks/gcp-gke
TFVARS_GCP_DEV := envs/gcp/dev/terraform.tfvars
TFVARS_GCP_PROD := envs/gcp/prod/terraform.tfvars

.PHONY: help fmt validate lint scan gcp-dev-init gcp-dev-plan gcp-dev-apply gcp-dev-destroy gcp-prod-init gcp-prod-plan gcp-prod-apply

help:
	@echo "Targets:"
	@echo "  fmt                 - terraform fmt -recursive"
	@echo "  validate            - validate all stacks (backend=false)"
	@echo "  lint                - tflint (root config)"
	@echo "  scan                - trivy config scan"
	@echo "  gcp-dev-init/plan/apply/destroy"
	@echo "  gcp-prod-init/plan/apply"

fmt:
	terraform fmt -recursive

validate:
	@for d in stacks/gcp-gke stacks/aws-eks; do \
		echo "==> $$d"; \
		(terraform -chdir=$$d init -backend=false >/dev/null); \
		(terraform -chdir=$$d validate); \
	done

lint:
	tflint --init
	tflint -f compact

scan:
	trivy config --severity HIGH,CRITICAL --exit-code 1 .

gcp-dev-init:
	terraform -chdir=$(STACK_GCP) init

gcp-dev-plan:
	terraform -chdir=$(STACK_GCP) plan -var-file=$(TFVARS_GCP_DEV)

gcp-dev-apply:
	terraform -chdir=$(STACK_GCP) apply -var-file=$(TFVARS_GCP_DEV)

gcp-dev-destroy:
	terraform -chdir=$(STACK_GCP) destroy -var-file=$(TFVARS_GCP_DEV)

gcp-prod-init:
	terraform -chdir=$(STACK_GCP) init

gcp-prod-plan:
	terraform -chdir=$(STACK_GCP) plan -var-file=$(TFVARS_GCP_PROD)

gcp-prod-apply:
	terraform -chdir=$(STACK_GCP) apply -var-file=$(TFVARS_GCP_PROD)
