output "cluster_id" {
  value = aws_eks_cluster.vaishnavi.id
}

output "node_group_id" {
  value = aws_eks_node_group.vaishnavi.id
}

output "vpc_id" {
  value = aws_vpc.vaishnavi_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.vaishnavi_subnet[*].id
}

