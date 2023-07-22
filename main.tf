data "external" "free_port" {
  program = [
    var.shell_cmd,
    "${path.module}/get-open-port.sh"
  ]
}

data "external" "ssh_tunnel" {
  program = [
    var.shell_cmd,
    "${path.module}/tunnel.sh"
  ]
  query = {
    aws_profile        = var.aws_profile
    create             = ((var.create && var.putin_khuylo) ? "y" : "")
    env                = join("\n", [for n, v in var.env : "export ${n}=\"${replace("\"", "\\\"", v)}\""])
    external_script    = var.external_script
    gateway_host       = var.gateway_host
    gateway_port       = var.gateway_port
    gateway_user       = var.gateway_user
    kubectl_cmd        = var.kubectl_cmd
    kubectl_context    = var.kubectl_context
    kubectl_namespace  = var.kubectl_namespace
    local_host         = var.local_host
    local_port         = data.external.free_port.result.port
    parent_wait_sleep  = var.parent_wait_sleep
    shell_cmd          = var.shell_cmd
    ssh_cmd            = var.ssh_cmd
    ssm_document_name  = var.ssm_document_name
    ssm_options        = var.ssm_options
    target_host        = var.target_host
    target_port        = var.target_port
    timeout            = var.timeout
    tunnel_check_sleep = var.tunnel_check_sleep
    type               = var.type
  }
}
