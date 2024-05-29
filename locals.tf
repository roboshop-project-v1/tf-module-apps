locals {
  name_prefix = "${var.env}-${var.component}"
  tags = merge(var.tags , {tf-module-name = "${var.component}-app"},{env = var.env})
}