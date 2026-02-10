# Architecture

## Overview

This document outlines the architecture of the MedinovAI LIS Infrastructure repository. This repository is responsible for the deployment and management of the MedinovAI Laboratory Information System (LIS) platform. It contains all the necessary Infrastructure-as-Code (IaC) and DevOps configurations to ensure a secure, scalable, and HIPAA-compliant environment.

## Architecture Diagram

```
+----------------------------------------------------+
|                                                    |
|                  GitHub Repository                 |
|           (medinovai-infrastructure)               |
|                                                    |
+------------------------+---------------------------+
                         | CI/CD (GitHub Actions)
                         v
+------------------------+---------------------------+
|                                                    |
|                Container Registry (ACR)            |
|                                                    |
+------------------------+---------------------------+
                         | Deployment
                         v
+------------------------+---------------------------+
|                                                    |
|              Kubernetes Cluster (AKS)              |
|                                                    |
|  +------------------+   +----------------------+   |
|  |                  |   |                      |   |
|  |   ArgoCD         +-->+   LIS Services       |   |
|  | (GitOps)         |   | (API, Workers, etc.) |   |
|  |                  |   |                      |   |
|  +------------------+   +----------------------+   |
|                                                    |
+----------------------------------------------------+

```

## Technology Stack

- **Orchestration:** Kubernetes (Azure Kubernetes Service - AKS)
- **Infrastructure as Code:** Terraform
- **Continuous Integration/Continuous Deployment:** GitHub Actions
- **GitOps:** ArgoCD
- **Containerization:** Docker
- **Monitoring:** Prometheus, Grafana

## Directory Structure

The repository is structured to separate concerns and environments:

- `kubernetes/`: Contains Kubernetes manifests, organized into base and overlays for different environments.
- `terraform/`: Manages cloud resources using Terraform, with modules for reusability.
- `docker/`: Holds Dockerfiles for building service images.
- `argocd/`: Defines ArgoCD applications for GitOps-based deployments.
- `monitoring/`: Configuration for Prometheus and Grafana.
- `.github/workflows/`: CI/CD pipelines using GitHub Actions.

## Data Flow

1. Developers push code to the GitHub repository.
2. GitHub Actions triggers a CI pipeline that builds, tests, and pushes Docker images to the container registry.
3. The CD pipeline updates the Kubernetes manifests in the repository.
4. ArgoCD detects the changes in the manifests and automatically deploys the new version of the application to the Kubernetes cluster.

## Dependencies on other MedinovAI services

This infrastructure is a foundational component and is a dependency for all other MedinovAI services that are deployed on Kubernetes. It provides the runtime environment, networking, and observability for services such as:

- `medinovai-lis-api`
- `medinovai-auth-service`
- `medinovai-platform`

## API Contracts summary

This repository does not directly expose any APIs. However, it is responsible for deploying services that do. The API contracts for those services are defined in their respective repositories and summarized in `API_CONTRACTS.md`.

## Security (HIPAA)

Security and HIPAA compliance are critical. The following measures are in place:

- **Infrastructure:** Deployed in a private virtual network.
- **Data:** Encryption at rest and in transit.
- **Access:** Role-Based Access Control (RBAC) in Kubernetes and cloud resources.
- **Compliance:** Regular security scans and audits.

## Deployment

Deployments are fully automated using a GitOps workflow with ArgoCD. Changes are promoted through different environments (dev, staging, prod) by updating the corresponding overlays in the `kubernetes/overlays` directory.

## Scaling Strategy

The platform is designed to scale horizontally. The Kubernetes Horizontal Pod Autoscaler (HPA) is used to automatically scale the number of pods based on CPU and memory usage. The underlying Kubernetes cluster can also be scaled by adjusting the number of nodes in the Terraform configuration.
