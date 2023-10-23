output "trust_anchors" {
  value = [for trust_anchor in aws_rolesanywhere_trust_anchor.this : trust_anchor]
}

output "trust_anchor_arns" {
  value = [for trust_anchor in aws_rolesanywhere_trust_anchor.this : trust_anchor.arn]
}

output "trust_anchor_names" {
  value = [for trust_anchor in aws_rolesanywhere_trust_anchor.this : trust_anchor.name]
}
