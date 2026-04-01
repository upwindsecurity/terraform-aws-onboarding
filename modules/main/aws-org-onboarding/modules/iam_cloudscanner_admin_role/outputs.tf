output "iam_role" {
  description = "The CloudScanner admin role"
  value       = aws_iam_role.cloudscanner_administration_role
}