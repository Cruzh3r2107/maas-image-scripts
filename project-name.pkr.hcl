locals {
  qemu_arch = {
    "amd64" = "x86_64"
    "arm64" = "aarch64"
  }
  qemu_machine = {
    "amd64" = "accel=kvm"
    "arm64" = var.host_is_arm ? "virt,accel=kvm" : "virt"
  }
  qemu_cpu = {
    "amd64" = "host"
    "arm64" = var.host_is_arm ? "host" : "max"
  }

  project-name_env_content = file("${path.root}/project-name-customization.env")

  project-name_env = [
    for line in split("\n", local.project-name_env_content) :
    trimspace(line)
    if trimspace(line) != ""
  ]
}

source "null" "dependencies" {
  communicator = "none"
}

source "qemu" "project-name" {
  boot_wait      = "10s"
  cpus           = 1
  disk_image     = true
  disk_size      = "30G"
  format         = "raw"
  headless       = var.headless
  iso_checksum   = "file:${var.base_image_checksum}"
  iso_url        = var.base_image
  memory         = 4096
  qemu_binary    = "qemu-system-${lookup(local.qemu_arch, var.architecture, "")}"
  vnc_bind_address = "0.0.0.0"
  qemuargs = [
    ["-machine", "${lookup(local.qemu_machine, var.architecture, "")}"],
    ["-cpu", "${lookup(local.qemu_cpu, var.architecture, "")}"],
    ["-device", "virtio-gpu-pci"],
    ["-drive", "if=pflash,format=raw,id=ovmf_code,readonly=on,file=OVMF_CODE.fd"],
    ["-drive", "if=pflash,format=raw,id=ovmf_vars,file=OVMF_VARS.fd"],
    ["-drive", "file=output-project-name/packer-project-name,format=raw"],
    ["-drive", "file=seeds-project-name.iso,format=raw"]
  ]
  shutdown_command       = "sudo -S shutdown -P now"
  ssh_handshake_attempts = 500
  ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = var.ssh_username
  ssh_wait_timeout       = var.timeout
  use_backing_file       = false
}

build {
  name    = "project-name.deps"
  sources = ["source.null.dependencies"]

  provisioner "shell-local" {
    inline = [
      "cloud-localds seeds-project-name.iso user-data-project-name meta-data"
    ]
    inline_shebang = "/bin/bash -e"
  }
}

build {
  name    = "project-name.image"
  sources = ["source.qemu.project-name"]

  provisioner "file" {
    destination = "/tmp/"
    sources     = ["${path.root}/packer/scripts/curtin-hooks"]
  }

 provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/ubuntu", "http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "echo 'ubuntu' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts           = ["${path.root}/packer/scripts/curtin.sh", "${path.root}/packer/scripts/networking.sh", "${path.root}/packer/scripts/cleanup.sh"]
  }

 provisioner "shell" {
    environment_vars  = local.project-name_env
    execute_command   = "echo 'ubuntu' | {{ .Vars }} sudo -S -E bash -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [var.customize_script]
  } 

 post-processor "compress" {
    output = "${var.output_directory}/custom-project-name.dd.gz"
  }
}
