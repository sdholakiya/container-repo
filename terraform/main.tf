provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "kubernetes" {
  host                   = var.k3s_api_endpoint
  cluster_ca_certificate = data.aws_ssm_parameter.k3s_ca_cert.value
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "${path.module}/../scripts/k3s-kubeconfig.sh"
    args        = [var.k3s_master_instance_id]
  }
}

data "aws_ssm_parameter" "k3s_ca_cert" {
  name = "/k3s/ca_cert"
}

module "k3s_pod" {
  source = "./modules/k3s-pod"

  pod_name              = var.pod_name
  namespace             = var.namespace
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