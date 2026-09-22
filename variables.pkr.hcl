packer {
  required_version = ">= 1.11.0"
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "headless" {
  type        = bool
  default     = true
  description = "Whether VNC viewer should not be launched."
}

variable "host_is_arm" {
  type        = bool
  default     = false
  description = "The host architecture is aarch64"
}

variable "http_proxy" {
  type    = string
  default = "${env("http_proxy")}"
}

variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}

variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
}

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "ssh_ubuntu_password" {
  type    = string
  default = "ubuntu"
}

variable "timeout" {
  type        = string
  default     = "1h"
  description = "Timeout for building the image"
}

variable "ubuntu_series" {
  type        = string
  default     = "noble"
  description = "The codename of the Ubuntu series to build."
}

variable "base_image" {
  type        = string
  default     = "project-name.img"
  description = "The image name to build the image from"
}

variable "base_image_checksum" {
  type        = string
  default     = "sha256sum"
  description = "The checksum of the image to build the image from"
}

variable "customize_script" {
  type        = string
  default     = "/dev/null"
  description = "The filename of the script that will run in the VM to customize the image."
}

variable "architecture" {
  type        = string
  default     = "amd64"
  description = "The architecture to build the image for (amd64 or arm64)"
}

variable "ovmf_suffix" {
  type        = string
  default     = "_4"
  description = "Suffix for OVMF CODE and VARS files. Newer systems such as Noble use _4M."
}

variable "output_directory" {
  type        = string
  default     = "out"
  description = "The directory in which the image will be created."
}
