output "state_bucket_arn" {
  value = aws_s3_bucket.state.arn
}

output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}
