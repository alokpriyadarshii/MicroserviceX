#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="$(mktemp "${TMPDIR:-/tmp}/microservicex-k8s.XXXXXX.yaml")"
trap 'rm -f "$OUTPUT_FILE"' EXIT

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required to render the Kubernetes manifests." >&2
  exit 1
fi

kubectl kustomize "$ROOT_DIR/k8s" > "$OUTPUT_FILE"

require_resource() {
  local kind="$1"
  local name="$2"

  if ! awk -v kind="$kind" -v name="$name" '
    $1 == "kind:" && $2 == kind { in_kind = 1; next }
    in_kind && $1 == "name:" && $2 == name { found = 1 }
    /^---$/ { in_kind = 0 }
    END { exit(found ? 0 : 1) }
  ' "$OUTPUT_FILE"; then
    echo "Missing Kubernetes resource: ${kind}/${name}" >&2
    exit 1
  fi
}

require_resource Namespace animalclinic
require_resource ConfigMap animalclinic-common-env
require_resource ConfigMap prometheus-config
require_resource ConfigMap grafana-datasources

for app in \
  config-server \
  discovery-server \
  customers-service \
  visits-service \
  vets-service \
  genai-service \
  api-gateway \
  admin-server \
  tracing-server \
  prometheus-server \
  grafana-server
do
  require_resource Service "$app"
  require_resource Deployment "$app"
done

echo "Kubernetes manifests render successfully and include the expected resources."
