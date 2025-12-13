output "vpc_id" {
    description = "VPC ID"
    value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
    description = "VPC CIDR Block"
    value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
    description = "List of Public Subnet IDs"
    value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
    description = "List of Private Subnet IDs"
    value       = aws_subnet.private[*].id
}

output "nat_gateway_public_ips" {
    description = "List of Public IPs of NAT Gateways"
    value       = aws_eip.nat[*].public_ip
}
