# Remote state backend config (GCS) - DEV
# 1) Create the bucket (recommended):
#    PROJECT_ID="my-project" REGION="us-central1" ENV=dev ./scripts/bootstrap_state_gcp.sh
# 2) Replace bucket below if you use a different naming convention.

bucket = "tfstate-REPLACE_PROJECT_ID-dev"
prefix = "terraform-k8s-baseline/gcp/dev"
