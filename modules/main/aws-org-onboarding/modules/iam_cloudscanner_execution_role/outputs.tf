output "iam_role" {
  description = "The CloudScanner execution role"
  value       = aws_iam_role.cloudscanner_execution_role
}