output "name" {
  description = "Bucket name."
  value       = aws_s3_bucket.this.bucket
}

output "arn" {
  description = "Bucket ARN."
  value       = aws_s3_bucket.this.arn
}
