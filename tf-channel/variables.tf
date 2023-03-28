variable "region" {
  type    = string
  default = "us-east-2"
}

variable "bucket_name" {
  type = string
  default = "golden-image-ubuntu-20-04"
}

variable "channel" {
  type = string
  description = "HCP Packer Image Channel"
  validation {
    condition = contains(["Production", "UAT", "latest"], var.channel)
    error_message = "Valid value is one of the following: Production, UAT, latest."
  }
}