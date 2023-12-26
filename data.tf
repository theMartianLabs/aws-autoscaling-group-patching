
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "template_file" "autoscaling_patching_lambda_policy" {
  template = file("${path.module}/policies/lambda_asg_patching_iam_policy.json")

  vars = {
    region         = data.aws_region.current.name
    account_id     = data.aws_caller_identity.current.account_id
    log_group_name = local.cloudwatch_lg_name
  }
}

