variable "aws_region" {
  description = "AWS region where the infrastructure exists"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "k3s_master_instance_id" {
  description = "Instance ID of the k3s master node"
  type        = string
}

variable "k3s_token" {
  description = "K3s token for authentication"
  type        = string
  sensitive   = true
}

variable "k3s_api_endpoint" {
  description = "K3s API endpoint URL"
  type        = string
}

variable "container_image_frontend" {
  description = "Docker image for the frontend container"
  type        = string
  default     = "nginx:latest"
}

variable "container_image_backend" {
  description = "Docker image for the backend container"
  type        = string
  default     = "python:3.9-slim"
}

variable "container_image_logger" {
  description = "Docker image for the logger container"
  type        = string
  default     = "fluent/fluentd:v1.14"
}

variable "pod_name" {
  description = "Name of the pod containing all three containers"
  type        = string
  default     = "multi-container-pod"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy the pod"
  type        = string
  default     = "default"
}