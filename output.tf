
output "port" {
  value = data.external.free_port.result.port
  description = "Local port number to connect to"
}
