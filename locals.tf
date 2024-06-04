locals {
  name_prefix = "${var.env}-${var.component}"
  tags = merge(var.tags , {tf-module-name = "${var.component}-app"},{env = var.env})
  parameters = concat(var.parameters,[var.component])
  policy_resources = [for i in local.var.parameters:"arn:aws:ssm:us-east-1:858763399718:parameter/${i}.${var.env}.*" ]

}