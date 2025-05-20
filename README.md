# Multi-Container Pod Deployment with Terraform

This repository contains a Terraform infrastructure as code (IaC) solution for deploying a multi-container pod to an existing k3s cluster running on AWS EC2 in private subnets. The deployment includes three containers (frontend, backend, and logger) that communicate with each other within the same pod.

## Architecture

The deployment consists of:

- **Frontend Container**: Nginx web server serving static content
- **Backend Container**: Python-based HTTP server handling API requests
- **Logger Container**: Fluentd container for log aggregation

All three containers share volumes for data exchange and logging:
- A shared data volume accessible by frontend and backend
- A log volume where backend writes logs and logger reads from
- A config volume for logger configuration

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.0.0 or higher
- An existing k3s cluster running on EC2 in private subnets
- AWS SSM access to the k3s master node

## Project Structure

```
.
├── .gitlab-ci.yml               # GitLab CI/CD pipeline configuration
├── infrastructure-as-code
│   └── kubernetes
│       └── multi-container-pod.yaml  # Example Kubernetes manifest
├── scripts
│   ├── k3s-kubeconfig.sh        # Script to get kubeconfig from master node
│   └── generate-kubeconfig.sh   # Script to generate kubeconfig file for Terraform
└── terraform
    ├── main.tf                  # Main Terraform configuration
    ├── variables.tf             # Input variables declaration
    ├── terraform.tfvars.example # Example variable values
    └── modules
        └── k3s-pod
            ├── main.tf          # Pod deployment configuration
            ├── variables.tf     # Module input variables
            └── outputs.tf       # Module outputs
```

## Setup Instructions for Private Subnet Deployment

### 1. Generate Kubeconfig File

First, generate a kubeconfig file that Terraform will use to connect to your k3s cluster in private subnets:

```sh
# Make the script executable
chmod +x scripts/generate-kubeconfig.sh

# Generate the kubeconfig by providing the k3s master instance ID
./scripts/generate-kubeconfig.sh i-xxxxxxxxxx
```

This will create a `k3s-kubeconfig.yaml` file in the scripts directory that is configured to use the private IP of your k3s master node.

### 2. Configure Variables

Create a `terraform.tfvars` file based on the example:

```sh
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Update the values to match your existing infrastructure:

```
aws_region            = "us-west-2"              # Your AWS region
aws_profile           = "default"                # AWS profile to use
vpc_id                = "vpc-xxxxxxxx"           # Existing VPC ID
k3s_master_instance_id = "i-xxxxxxxxxx"          # EC2 instance ID of k3s master
pod_name              = "multi-container-pod"    # Name for the pod
namespace             = "default"                # Kubernetes namespace
container_image_frontend = "nginx:latest"        # Frontend container image
container_image_backend  = "python:3.9-slim"     # Backend container image
container_image_logger   = "fluent/fluentd:v1.14" # Logger container image
```

### 3. Initialize and Apply Terraform

```sh
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Verify Deployment

Once the deployment is complete, you can verify it by connecting to your k3s cluster:

```sh
export KUBECONFIG=$(pwd)/../scripts/k3s-kubeconfig.yaml
kubectl get pods
kubectl describe pod multi-container-pod
```

## How This Works with Private Subnets

The key difference in this deployment is that we:

1. Generate a kubeconfig file that uses the private IP of the k3s master node
2. Configure Terraform to use this kubeconfig file directly, rather than trying to connect to the API endpoint URL
3. This allows Terraform to deploy resources to a k3s cluster in private subnets without requiring public API access

## CI/CD Pipeline

This repository includes a GitLab CI/CD pipeline that automates the deployment process:

1. **Validate Stage**: Checks Terraform formatting and validates configuration
2. **Plan Stage**: Creates and preserves a Terraform plan
3. **Apply Stage**: Deploys the infrastructure (manual approval for production)

### Pipeline Variables

The following CI/CD variables need to be configured in GitLab:

| Variable | Description |
|----------|-------------|
| AWS_ACCESS_KEY_ID | AWS access key |
| AWS_SECRET_ACCESS_KEY | AWS secret access key |
| AWS_REGION | AWS region |
| VPC_ID | Existing VPC ID |
| K3S_MASTER_INSTANCE_ID | EC2 instance ID of k3s master |
| CONTAINER_IMAGE_FRONTEND | Frontend container image (optional) |
| CONTAINER_IMAGE_BACKEND | Backend container image (optional) |
| CONTAINER_IMAGE_LOGGER | Logger container image (optional) |
| POD_NAME | Name for the pod (optional) |
| NAMESPACE | Kubernetes namespace (optional) |

## Container Communication

The three containers communicate as follows:

1. **Frontend to Backend**: The frontend communicates with the backend via localhost:8080
2. **Backend to Logger**: The backend writes logs to the shared volume
3. **Logger**: Reads logs from the shared volume and processes them

This design enables tight communication between containers while maintaining separation of concerns.

## Customization

To customize the deployment:

1. Modify container images in `terraform.tfvars`
2. Update resource limits in `terraform/modules/k3s-pod/main.tf`
3. Add additional environment variables or configurations as needed

## Troubleshooting

If you encounter issues:

1. Check that AWS credentials have permission to access the EC2 instance through SSM
2. Verify the k3s cluster is running and accessible from your network
3. Check that the private IP of the k3s master is correct in the kubeconfig file
4. Ensure the AWS instance has proper IAM roles for SSM access
5. Check the Terraform logs for detailed error messages

## Security Considerations

- The kubeconfig file contains sensitive information and should be protected
- For production use, consider setting up proper RBAC for the Kubernetes deployment
- Use AWS IAM roles with minimal permissions for the CI/CD pipeline
- Using kubeconfig with private IPs is more secure than exposing the k3s API endpoint publicly