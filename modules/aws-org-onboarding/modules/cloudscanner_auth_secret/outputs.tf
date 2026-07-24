output "secret" {
  description = "The CloudScanner secret"
  value       = aws_secretsmanager_secret.cloudscanner_secret
}