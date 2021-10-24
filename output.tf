
output "port" {
  value = (var.create ? data.external.free_port.result.port : -1)
  description = "Local port number to connect to"
}

output "host" {
  value = (var.create ? data.external.ssh_tunnel[0].result.host : -1)
  description = "Host to connect to"
}

