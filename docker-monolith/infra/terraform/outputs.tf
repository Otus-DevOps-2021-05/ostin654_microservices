output "external_ip_address_dockerhost" {
  value = yandex_compute_instance.dockerhost.*.network_interface.0.nat_ip_address
}
