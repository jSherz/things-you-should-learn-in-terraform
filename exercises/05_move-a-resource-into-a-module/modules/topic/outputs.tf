output "topic_arn" {
  value = aws_sns_topic.this.arn
}

output "topic_name" {
  value = aws_sns_topic.this.name
}
