resource "aws_db_subnet_group" "rds_cluster_subnet_group" {
  name       = "${var.identifier}-sng-cluster"
  subnet_ids = [for subnet in var.subnets_id : subnet]
}

# Create AWS RDS Database
resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier     = var.identifier
  engine                 = var.engine
  engine_version         = var.engine_version
  availability_zones     = var.aws_zones
  db_subnet_group_name   = aws_db_subnet_group.rds_cluster_subnet_group.name
  vpc_security_group_ids = var.security_group_ids
  database_name          = var.database
  master_username        = var.username
  master_password        = var.password
  skip_final_snapshot    = false

  # backup_retention_period = 1
  # preferred_backup_window = "07:00-09:00"
  # apply_immediately   = true

  lifecycle {
    ignore_changes = [enabled_cloudwatch_logs_exports, tags]
  }
}

# Create AWS Cluster instances
resource "aws_rds_cluster_instance" "cluster_instances" {
  identifier = "${var.identifier}-${count.index}"
  # identifier          = "${var.identifier}"
  count               = 1
  cluster_identifier  = aws_rds_cluster.rds_cluster.id
  publicly_accessible = var.publicly_accessible
  instance_class      = var.instance_class
  engine              = var.engine
  engine_version      = var.engine_version

  lifecycle {
    ignore_changes = [tags]
  }
}
