
output "port" {
  value = (var.create ? data.external.free_port.result.port : -1)
  description = "Local port number to connect to"
}
