output "external_ip_address_kubernetes" {
  value = yandex_compute_instance.kubernetes.*.network_interface.0.nat_ip_address
}
