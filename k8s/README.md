# Kubernetes Deployment

This directory contains Kubernetes manifests for the Animal Clinic microservices stack without changing the existing Maven, Docker, or Docker Compose workflow.

## What Gets Deployed

- Config Server
- Discovery Server
- Customers, Visits, Vets, and GenAI services
- API Gateway
- Spring Boot Admin
- Zipkin
- Prometheus
- Grafana

All resources are deployed into the `animalclinic` namespace. The service names match the Docker Compose names so the existing Docker profile can keep resolving `config-server`, `discovery-server`, and the application services.

## Validate

From the repository root:

```bash
scripts/check_k8s.sh
```

The script renders the Kustomize overlay and checks that the expected deployments and services are present. It does not require a live cluster.

## Deploy

From the repository root:

```bash
kubectl apply -k k8s
kubectl -n animalclinic get pods
```

Wait until all pods are `Running` and ready.

## Access Locally

Use port forwarding for local development:

```bash
kubectl -n animalclinic port-forward svc/api-gateway 8080:8080
```

Open the application at:

```text
http://localhost:8080
```

Optional monitoring access:

```bash
kubectl -n animalclinic port-forward svc/grafana-server 3030:3000
kubectl -n animalclinic port-forward svc/prometheus-server 9091:9090
kubectl -n animalclinic port-forward svc/discovery-server 8761:8761
kubectl -n animalclinic port-forward svc/admin-server 9090:9090
```

## GenAI Secrets

The GenAI service works without external keys by using the app fallback path. To enable OpenAI or Azure OpenAI inside Kubernetes, create the optional secret before deploying or restart the GenAI pod after creating it:

```bash
kubectl -n animalclinic create secret generic genai-secrets \
  --from-literal=OPENAI_API_KEY="your_api_key_here" \
  --from-literal=AZURE_OPENAI_KEY="" \
  --from-literal=AZURE_OPENAI_ENDPOINT=""
```

## Remove

```bash
kubectl delete -k k8s
```
