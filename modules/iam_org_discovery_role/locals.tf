locals {
  upwind_version = "TF-4.1.1"

  # Resolve the optional permissions boundary. A value beginning with "arn:" is used verbatim; a bare
  # policy name/path is expanded to a full ARN for this account. Null when no boundary was supplied.
  permissions_boundary_arn = (
    var.permissions_boundary == null ? null :
    can(regex("^arn:", var.permissions_boundary)) ? var.permissions_boundary :
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"
  )
}
