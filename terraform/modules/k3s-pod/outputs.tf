output "pod_name" {
  description = "Name of the deployed pod"
  value       = kubernetes_pod.multi_container_pod.metadata[0].name
}

output "pod_status" {
  description = "Status of the deployed pod"
  value       = kubernetes_pod.multi_container_pod.status[0].phase
}

output "pod_ip" {
  description = "IP address of the deployed pod"
  value       = kubernetes_pod.multi_container_pod.status[0].pod_ip
}