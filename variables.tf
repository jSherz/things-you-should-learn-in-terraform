variable "name" {
  type        = string
  description = "Bucket name."
}

variable "versioning" {
  type        = bool
  default     = true
  description = "Enable bucket versioning?"
}

variable "policy" {
  type        = string
  default     = null
  description = "Bucket IAM policy."
}
