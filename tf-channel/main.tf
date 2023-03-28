provider "hcp" {}

provider "aws" {
  region = var.region
}

data "hcp_packer_iteration" "ubuntu" {
  bucket_name = var.bucket_name
  channel     = var.channel
}

data "hcp_packer_image" "ubuntu_us_east_2" {
  bucket_name    = var.bucket_name
  cloud_provider = "aws"
  iteration_id   = data.hcp_packer_iteration.ubuntu.ulid
  region         = "us-east-2"
}

resource "aws_instance" "app_server" {
  ami           = data.hcp_packer_image.ubuntu_us_east_2.cloud_image_id
  instance_type = "t2.micro"
  tags = {
    Name = "Approved 22.04 Image"
  }
}
