

###########
## SECURITY GROUP
###########
resource "aws_security_group" "autoscaling_patching_lambda_sg" {
  name        = "lambda_asg_patching_sg"
  description = "Security Group for the autosclaing group patching lambda"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "lambda_asg_patching_sg"
    },
    var.tags
  )
}

resource "aws_security_group_rule" "autoscaling_patching_lambda_sg_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.autoscaling_patching_lambda_sg.id
}

###########
## LAMBDA FUNCTION
###########
resource "aws_cloudwatch_log_group" "autoscaling_patching_lambda_log_group" {
  for_each = local.lambda_env_variables

  name              = "${local.cloudwatch_lg_name}-${each.value["target_asg"]}"
  retention_in_days = 3
}

resource "aws_iam_role" "autoscaling_patching_lambda_role" {
  name               = "${var.lambda_function_name}-role"
  assume_role_policy = file("${path.module}/policies/lambda_trust_policy.json")

  tags = merge(var.tags, {
    Name = "${var.lambda_function_name}-role"
  })
}

resource "aws_iam_policy" "autoscaling_patching_lambda_policy" {
  name   = "${var.lambda_function_name}-policy"
  policy = data.template_file.autoscaling_patching_lambda_policy.rendered

  tags = merge(var.tags, {
    Name = "${var.lambda_function_name}-policy"
  })
}

resource "aws_iam_role_policy_attachment" "autoscaling_patching_lambda_policy_attach" {
  role       = aws_iam_role.autoscaling_patching_lambda_role.name
  policy_arn = aws_iam_policy.autoscaling_patching_lambda_policy.arn
}

data "archive_file" "autoscaling_patching_lambda_file" {
  type             = "zip"
  source_file      = "${path.module}/src/lambda_asg_patching.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/src/lambda_asg_patching.py.zip"
}

resource "aws_lambda_function" "autoscaling_patching_lambda" {
  for_each = local.lambda_env_variables

  function_name    = "${var.lambda_function_name}-${each.value["target_asg"]}"
  role             = aws_iam_role.autoscaling_patching_lambda_role.arn
  handler          = "lambda_asg_patching.lambda_handler"
  runtime          = var.runtime
  timeout          = var.timeout
  filename         = data.archive_file.autoscaling_patching_lambda_file.output_path
  source_code_hash = data.archive_file.autoscaling_patching_lambda_file.output_base64sha256

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [aws_security_group.autoscaling_patching_lambda_sg.id]
  }

  environment {
    variables = {
      document_name              = each.value["document_name"]
      instance_profile           = each.value["instance_profile"]
      subnet_id                  = each.value["subnet_id"]
      security_group_ids         = each.value["security_group_ids"]
      target_asg                 = each.value["target_asg"]
      source_ami                 = each.value["source_ami"]
      ssm_automation_assume_role = each.value["ssm_automation_assume_role"]
    }
  }

  depends_on = [
    aws_iam_role.autoscaling_patching_ssm_role,
    aws_cloudwatch_log_group.autoscaling_patching_lambda_log_group
  ]

}

resource "aws_cloudwatch_event_rule" "autoscaling_patching_lambda_rule" {
  for_each = var.lambda_asg_env_variables

  name                = each.key
  description         = "Scheduled time for triggering the ${each.value["target_asg"]} patching lambda"
  schedule_expression = "cron(${each.value["maintenance_window"]})"
}

resource "aws_cloudwatch_event_target" "autoscaling_patching_lambda_target" {
  for_each = var.lambda_asg_env_variables

  rule      = aws_cloudwatch_event_rule.autoscaling_patching_lambda_rule[each.key].name
  target_id = "lambda"
  arn       = aws_lambda_function.autoscaling_patching_lambda[each.key].arn
}

resource "aws_lambda_permission" "autoscaling_patching_lambda_permissions" {
  for_each = var.lambda_asg_env_variables

  statement_id  = "AllowExeCW-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.autoscaling_patching_lambda[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.autoscaling_patching_lambda_rule[each.key].arn
}

resource "aws_lambda_function_event_invoke_config" "lambda_asg_patching_rule" {
  for_each = var.lambda_asg_env_variables

  function_name          = aws_lambda_function.autoscaling_patching_lambda[each.key].function_name
  maximum_retry_attempts = 0
}

###############
## SSM DOCUMENT
###############
resource "aws_iam_role" "autoscaling_patching_ssm_role" {
  name = "ssm-asg-patching-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ssm.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ssm-asg-patching-role"
  }
}

resource "aws_iam_policy" "autoscaling_patching_ssm_policy" {
  name        = "ssm-asg-patching-policy"
  description = "An autoscaling group cloudwatch policy"
  policy      = templatefile("${path.module}/policies/ssm-asg.json", {})

  tags = {
    Name = "ssm-asg-patching-policy"
  }
}

resource "aws_iam_role_policy_attachment" "autoscaling_patching_ssm_role_attachment" {
  role       = aws_iam_role.autoscaling_patching_ssm_role.name
  policy_arn = aws_iam_policy.autoscaling_patching_ssm_policy.arn
}

resource "aws_ssm_document" "autoscaling_patching_ssm_doc" {
  name            = "ssm-asg-patching-document"
  document_format = "YAML"
  document_type   = "Automation"
  content         = templatefile("${path.module}/templates/asg_ssm.yaml", {})

  tags = {
    Name = "ssm-asg-patching-document"
  }
}