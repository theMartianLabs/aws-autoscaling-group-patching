locals {
  cloudwatch_lg_name         = "/aws/lambda/${var.lambda_function_name}"
  ssm_automation_assume_role = aws_iam_role.autoscaling_patching_ssm_role.arn

  lambda_env_variables = {
    for key, value in var.lambda_asg_env_variables : key => {
      "document_name"              = value["document_name"]
      "subnet_id"                  = value["subnet_id"]
      "instance_profile"           = value["instance_profile"]
      "target_asg"                 = value["target_asg"]
      "source_ami"                 = value["source_ami"]
      "security_group_ids"         = value["security_group_ids"]
      "ssm_automation_assume_role" = "${tostring(local.ssm_automation_assume_role)}"
    }
  }
}