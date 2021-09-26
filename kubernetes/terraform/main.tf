provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.yc_cloud_id
  folder_id                = var.yc_folder_id
  zone                     = var.yc_zone
}

resource "yandex_compute_instance" "kubernetes" {
  name = "kubernetes-${count.index}"

  count = var.instance_count

  resources {
    cores  = var.cores
    memory = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.disk_image
      size = var.disk_size
    }
  }

  network_interface {
    subnet_id = var.yc_subnet_id
    nat = var.is_nat
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }
}
