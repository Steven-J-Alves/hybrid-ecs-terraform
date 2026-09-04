resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.identifier}-sng-instance"
  subnet_ids = var.subnets_id
  
  tags = {
    Name = "${var.identifier}-sng-cluster"
  }
}

resource "aws_rds_cluster" "aurora_pg_cluster" {
  cluster_identifier      = var.identifier
  engine                  = "aurora-postgresql"
  engine_version          = var.engine_version
  master_username         = var.username
  master_password         = var.password
  database_name           = var.database
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = var.security_group_ids
  skip_final_snapshot     = true
  deletion_protection     = var.deletion_protection
  storage_encrypted       = true
  backup_retention_period = 1
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_pg_cluster_param_group.name

  tags = {
    Name = var.identifier
  }
}

resource "aws_rds_cluster_instance" "aurora_pg_instance" {
  count                   = 1
  identifier              = "${var.identifier}-${var.instance_identifier_suffix}"
  cluster_identifier      = aws_rds_cluster.aurora_pg_cluster.id
  instance_class          = var.instance_class
  publicly_accessible     = var.publicly_accessible
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  engine                  = "aurora-postgresql"
  promotion_tier          = var.promotion_tier
  monitoring_interval     = var.monitoring_interval

  engine_version          = var.engine_version
  tags = {
    Name = "${var.identifier}-${var.instance_identifier_suffix}"
  }
}

resource "aws_rds_cluster_parameter_group" "aurora_pg_cluster_param_group" {
  name        = "${var.identifier}-cluster-param-group"
  family      = "aurora-postgresql17"
  description = "Aurora PostgreSQL cluster parameter group"

  parameter {
    name  = "timezone"
    value = "America/Fortaleza"
  }

  parameter {
    name  = "ssl"
    value = "0"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
}


# Create PostgreSQL RDS Instance (Primary)
# resource "aws_db_instance" "primary_instance" {
#   identifier             = var.identifier
#   engine                 = "aurora-postgresql"
#   engine_version         = var.engine_version
#   instance_class         = var.instance_class
#   allocated_storage      = var.allocated_storage
#   db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
#   vpc_security_group_ids = var.security_group_ids
#   db_name                = var.database
#   username               = var.username
#   password               = var.password
#   skip_final_snapshot    = true
#   publicly_accessible    = var.publicly_accessible
#   parameter_group_name   = aws_db_parameter_group.postgres_param_group.name
#   # storage_encrypted       = var.storage_encrypted
#   # backup_retention_period = var.backup_retention_period
#   # preferred_backup_window = var.preferred_backup_window
#   apply_immediately = true
#   # Add multi-AZ deployment for high availability
#   multi_az = var.multi_az
#   # Parameter to enable enhanced monitoring
#   # monitoring_interval = var.monitoring_interval
#   # Optional storage autoscaling
#   max_allocated_storage = var.allocated_storage
#   # Lifecycle settings to ignore specific changes
#   lifecycle {
#     ignore_changes = [enabled_cloudwatch_logs_exports, tags]
#   }
#   tags = {
#     Name = var.identifier
#   }
#   deletion_protection = var.deletion_protection
# }

# # Optional Read Replica (PostgreSQL supports read replicas)
# resource "aws_db_instance" "read_replica" {
#   count                  = var.read_replica_count
#   identifier             = "${var.identifier}-replica-${count.index}"
#   engine                 = "postgres"
#   engine_version         = var.engine_version
#   instance_class         = var.instance_class
#   publicly_accessible    = var.publicly_accessible
#   db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
#   vpc_security_group_ids = var.security_group_ids
#   replicate_source_db    = aws_db_instance.primary_instance.id
#   parameter_group_name   = aws_db_parameter_group.postgres_param_group.name
#   lifecycle {
#     ignore_changes = [tags]
#   }
#   tags = {
#     Name = var.identifier
#   }
#   deletion_protection = var.deletion_protection
# }

