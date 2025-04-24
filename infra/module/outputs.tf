output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "alb_dns" {
  description = "ALB DNS Name will be available after deploying the service"
  value       = module.alb.dns_name
}
