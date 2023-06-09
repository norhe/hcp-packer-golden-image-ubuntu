packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "version" {
  type    = string
  default = "1.0.5"
}

variable "ami_name" {
  default = "Ubuntu_20_04_Golden_Image"
}

data "amazon-ami" "ubuntu-focal-east" {
  region = "us-east-2"
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "basic-example-east" {
  region         = "us-east-2"
  source_ami     = data.amazon-ami.ubuntu-focal-east.id
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "${var.ami_name}_{{timestamp}}_v${var.version}"
}

data "amazon-ami" "ubuntu-focal-west" {
  region = "us-west-1"
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "basic-example-west" {
  region         = "us-west-1"
  source_ami     = data.amazon-ami.ubuntu-focal-west.id
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "${var.ami_name}_{{timestamp}}_v${var.version}"
}

build {
  hcp_packer_registry {
    bucket_name = "golden-image-ubuntu-20-04"
    description = <<EOT
Approved Ubuntu 20.04 server image.  Required for corporate deployment
    EOT
    bucket_labels = {
      "owner"          = "platform-team"
      "os"             = "Ubuntu",
      "ubuntu-version" = "Focal 20.04",
    }

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }

  provisioner "shell" {
    inline = [
      "echo \"Waiting for cloudinit...\"",
      "cloud-init status --wait",
      "echo \"Proceeding with install...\"",
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "export DEBIAN_FRONTEND=noninteractive",
      "export NEEDRESTART_MODE=a",
      "export DEBIAN_PRIORITY=critical",
      "sudo apt-get -qy update",
      "sudo apt-get -qy install apt-utils -y",
      "sudo apt-get -qy -o \"Dpkg::Options::=--force-confdef\" -o \"Dpkg::Options::=--force-confold\" upgrade",
      "sudo apt-get -qy -o \"Dpkg::Options::=--force-confdef\" -o \"Dpkg::Options::=--force-confold\" install nginx-full"
    ]
  }
  sources = [
    "source.amazon-ebs.basic-example-east",
    "source.amazon-ebs.basic-example-west"
  ]
}
