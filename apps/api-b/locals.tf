locals {
  base_name = "${substr(var.environment_name, 0, 1)}-${var.service_name}"
  common_tags = {
    Environment = var.environment_name
    Service     = var.tag_service
    Owner       = var.tag_owner
    CostCenter  = var.tag_costcenter
    # Name        = "${substr(var.environment_name, 0, 1)}-${var.service_name}-others"
  }
}