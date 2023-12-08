data "external" "free_port" {
  count = ((var.local_port == 0) ? 1 : 0)
  program = [
    var.shell_cmd,
    "${path.module}/get-open-port.sh"
  ]
}

locals {
  local_port = ((var.local_port == 0) ? data.external.free_port[0].result.port : var.local_port)
}

data "external" "ssh_tunnel" {
  program = [
    var.shell_cmd,
    "${path.module}/tunnel.sh"
  ]
  query = {
    aws_profile        = var.aws_profile
    create             = ((var.create && var.putin_khuylo) ? "y" : "")
    env                = join(" ", [for n, v in var.env : "export ${n}=\"${replace(v, "\"", "\\\"")}\""])
    external_script    = var.external_script
    gateway_host       = var.gateway_host
    gateway_port       = var.gateway_port
    gateway_user       = var.gateway_user
    iap_gcp_project    = var.iap_gcp_project
    iap_gcp_zone       = var.iap_gcp_zone
    kubectl_cmd        = var.kubectl_cmd
    kubectl_context    = var.kubectl_context
    kubectl_namespace  = var.kubectl_namespace
    local_host         = var.local_host
    local_port         = local.local_port
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
