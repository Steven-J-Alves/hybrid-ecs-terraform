output "db_instance_endpoint" {
  value = replace(aws_db_instance.rds_instance.endpoint, ":3306", "")
}
