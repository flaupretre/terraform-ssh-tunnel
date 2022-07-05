
output "port" {
  value = (var.create ? data.external.free_port.result.port : var.target_port)
  description = "Port number to connect to"
}

output "host" {
  value = (var.create ? data.external.ssh_tunnel[0].result.host : var.target_host)
  description = "Host to connect to"
}
