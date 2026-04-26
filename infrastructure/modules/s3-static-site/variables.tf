variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "is_preview" {
  description = "Whether this is a preview bucket (true) or production bucket (false)"
  type        = bool
}

variable "index_document" {
  description = "The index document for static website hosting"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "The error document for static website hosting"
  type        = string
  default     = "404.html"
}
