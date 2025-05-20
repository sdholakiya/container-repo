variable "pod_name" {
  description = "Name of the pod containing all three containers"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy the pod"
  type        = string
}

variable "container_image_frontend" {
  description = "Docker image for the frontend container"
  type        = string
}

variable "container_image_backend" {
  description = "Docker image for the backend container"
  type        = string
}

variable "container_image_logger" {
  description = "Docker image for the logger container"
  type        = string
}