provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "kubernetes" {
  config_path    = "${path.module}/../scripts/k3s-kubeconfig.yaml"
  # No need to specify config_context as it will use the default context from the kubeconfig
}

module "k3s_pod" {
  source = "./modules/k3s-pod"

  pod_name               = var.pod_name
  namespace              = var.namespace
  container_image_frontend = var.container_image_frontend
  container_image_backend  = var.container_image_backend
  container_image_logger   = var.container_image_logger
}

# Output the pod details
output "pod_name" {
  value = module.k3s_pod.pod_name
}

output "pod_status" {
  value = module.k3s_pod.pod_status
}

output "pod_ip" {
  value = module.k3s_pod.pod_ip
}