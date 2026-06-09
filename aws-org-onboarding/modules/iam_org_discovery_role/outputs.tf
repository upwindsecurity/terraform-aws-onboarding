output "iam_role" {
  description = "The Org discovery role"
  value       = aws_iam_role.organization_service_role
}