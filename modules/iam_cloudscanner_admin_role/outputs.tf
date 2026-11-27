output "iam_role" {
  description = "The CloudScanner admin role"
  value       = aws_iam_role.cloudscanner_administration_role
}

output "instance_profile" {
  description = "The CloudScanner admin role instance profile"
  value       = aws_iam_instance_profile.cloudscanner_administration_role_instance_profile
}