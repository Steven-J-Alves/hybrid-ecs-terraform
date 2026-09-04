output "rds_cluster_writer_endpoint" {
  value = replace(aws_rds_cluster.rds_cluster.endpoint, ":3306", "")
}

output "rds_cluster_reader_endpoint" {
  value = replace(aws_rds_cluster.rds_cluster.reader_endpoint, ":3306", "")
}
