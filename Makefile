SHELL := /bin/bash
STACK_GCP := stacks/gcp-gke

# Var files are ignored by git (see .gitignore). Create them from *.example.
TFVARS_GCP_DEV := envs/gcp/dev/terraform.tfvars
TFVARS_GCP_PROD := envs/gcp/prod/terraform.tfvars

# Backend config is safe to commit (no secrets). Replace bucket names per project.
BACKEND_GCP_DEV := ../../envs/gcp/dev/backend.hcl
BACKEND_GCP_PROD := ../../envs/gcp/prod/backend.hcl

.PHONY: help fmt validate lint scan policy docs         gcp-dev-init gcp-dev-plan gcp-dev-apply gcp-dev-destroy         gcp-prod-init gcp-prod-plan gcp-prod-apply         bootstrap-state-dev bootstrap-state-prod

help:
	@echo "Targets:"
	@echo "  fmt                 - terraform fmt -recursive"
	@echo "  validate            - validate all stacks (backend=false)"
	@echo "  lint                - tflint (recursive)"
	@echo "  scan                - trivy config scan"
	@echo "  policy              - OPA/Conftest (HCL2) baseline checks"
	@echo "  docs                - generate module docs (terraform-docs)"
	@echo "  bootstrap-state-dev - create GCS bucket for DEV remote state"
	@echo "  bootstrap-state-prod- create GCS bucket for PROD remote state"
	@echo "  gcp-dev-init/plan/apply/destroy (remote state)"
	@echo "  gcp-prod-init/plan/apply (remote state)"

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
	tflint --recursive -f compact

scan:
	trivy config --severity HIGH,CRITICAL --exit-code 1 .

policy:
	chmod +x scripts/policy.sh
	./scripts/policy.sh

docs:
	chmod +x scripts/generate_docs.sh
	./scripts/generate_docs.sh

bootstrap-state-dev:
	ENV=dev ./scripts/bootstrap_state_gcp.sh

bootstrap-state-prod:
	ENV=prod ./scripts/bootstrap_state_gcp.sh

gcp-dev-init:
	terraform -chdir=$(STACK_GCP) init -reconfigure -backend-config=$(BACKEND_GCP_DEV)

gcp-dev-plan:
	terraform -chdir=$(STACK_GCP) plan -var-file=$(TFVARS_GCP_DEV)

gcp-dev-apply:
	terraform -chdir=$(STACK_GCP) apply -var-file=$(TFVARS_GCP_DEV)

gcp-dev-destroy:
	terraform -chdir=$(STACK_GCP) destroy -var-file=$(TFVARS_GCP_DEV)

gcp-prod-init:
	terraform -chdir=$(STACK_GCP) init -reconfigure -backend-config=$(BACKEND_GCP_PROD)

gcp-prod-plan:
	terraform -chdir=$(STACK_GCP) plan -var-file=$(TFVARS_GCP_PROD)

gcp-prod-apply:
	terraform -chdir=$(STACK_GCP) apply -var-file=$(TFVARS_GCP_PROD)
