resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.identifier}-sng"
  subnet_ids = [var.subnets_id[0], var.subnets_id[1]]
}

resource "aws_db_instance" "rds_instance" {
  identifier             = var.identifier
  username               = var.username
  password               = var.password
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  publicly_accessible    = var.publicly_accessible
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = var.security_group_ids
  skip_final_snapshot    = false

  # provisioner "local-exec" {
  #   command = <<EOT
  #     mysql -h ${self.endpoint} \
  #       -u ${var.username} \
  #       -p ${var.password} \
  #       -e "CREATE SCHEMA ${var.database};"
  #   EOT

  #   environment = {
  #     MYSQL_PWD = var.password
  #   }
  # }

  lifecycle {
    ignore_changes = [enabled_cloudwatch_logs_exports, tags]
  }
}