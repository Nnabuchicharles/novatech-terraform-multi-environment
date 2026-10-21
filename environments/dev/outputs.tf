output "vpc_id" { value = module.network.vpc_id }
output "subnet_id" { value = module.network.public_subnet_id }
output "security_group_id" { value = module.security.security_group_id }
output "web_public_ip" {
  value = var.deploy_ec2 ? module.compute[0].public_ip : null
}
