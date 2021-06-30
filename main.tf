
locals {
  gw_prefix = (var.gateway_user == "" ? "" : "${var.gateway_user}@")
}
  

data external free_port {
  program = [
    var.python_cmd,
    "-c",
    "import socket; s=socket.socket(); s.bind((\"\", 0)); print(\"{ \\\"port\\\": \\\"\" + str(s.getsockname()[1]) + \"\\\" }\"); s.close()"
  ]
}

data external ssh_tunnel {
  count = (var.create ? 1 : 0)
  program = [
    var.shell_cmd,
    "${path.module}/tunnel.sh",
    var.timeout,
    var.ssh_cmd,
    var.ssh_config,
    data.external.free_port.result.port,
    var.target_host,
    var.target_port,
    "${local.gw_prefix}${var.gateway_host}",
    var.shell_cmd
  ]
}
