output "vpc_id" {
  description = "作成されたVPCのID"
  value       = module.network.vpc_id
}

output "public_subnets" {
  description = "作成されたパブリックサブネットのIDリスト"
  value       = module.network.public_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT GatewayのPublic IP (EIP)"
  value       = module.network.nat_gateway_public_ips
}
