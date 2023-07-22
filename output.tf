
output "port" {
  value       = local.local_port
  description = "Port number to connect to"
}

output "host" {
  value       = data.external.ssh_tunnel.result.host
  description = "Host to connect to"
}

