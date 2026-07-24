output "iam_role" {
  description = "The CloudScanner SaaS customer assume role"
  value       = aws_iam_role.cloudscanner_saas_customer_assume_role
}
