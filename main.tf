
locals {
  gw = (var.gateway_host == null) ? "" : (var.gateway_user == "" ? var.gateway_host : "${var.gateway_user}@${var.gateway_host}")
}


data external free_port {
  program = [
    var.python_cmd,
    "-c",
    "import socket; s=socket.socket(); s.bind((\"\", 0)); print(\"{ \\\"port\\\": \\\"\" + str(s.getsockname()[1]) + \"\\\" }\"); s.close()"
  ]
}

data external ssh_tunnel {
  count = var.create ? 1 : 0
  program = [
    var.shell_cmd,
    "${path.module}/tunnel.sh"
  ]
  query = {
    timeout = var.timeout,
    ssh_cmd = var.ssh_cmd,
    local_host = var.local_host,
    local_port = data.external.free_port.result.port,
    target_host = var.target_host,
    target_port = var.target_port,
    gateway_host = local.gw,
    gateway_port = var.gateway_port,
    shell_cmd = var.shell_cmd,
    ssh_tunnel_check_sleep = var.ssh_tunnel_check_sleep
  }
}
