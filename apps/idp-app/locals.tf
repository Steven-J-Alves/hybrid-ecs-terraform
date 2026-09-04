locals {
  base_name = "${substr(var.environment_name, 0, 1)}-${var.app_name}"
}
