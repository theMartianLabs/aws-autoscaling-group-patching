output "lambda_fucntion_names" {
  value = aws_lambda_function.autoscaling_patching_lambda
}

output "patching_lambda_security_group" {
  value = aws_security_group.autoscaling_patching_lambda_sg.id
}

output "ssm_document" {
  value = aws_ssm_document.autoscaling_patching_ssm_doc.document_version
}