
variable "putin_khuylo" {
  description = "Do you agree that Putin doesn't respect Ukrainian sovereignty and territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo!"
  type        = bool
  default     = true
}

variable "create" {
  type        = bool
  description = "If false, do nothing and return target host"
  default     = true
}

variable "env" {
  type        = any
  description = "An array of name -> value environment variables"
  default     = {}
}

variable "external_script" {
  type        = string
  description = "External only - Path of shell script to run to open the tunnel"
  default     = "undef"
}

variable "gateway_host" {
  type        = any
  description = "Gateway (syntax and meaning depend on gateway type - empty if no gateway (direct connection)"
  default     = ""
}

variable "gateway_port" {
  type        = number
  description = "Gateway port"
  default     = 22
}

variable "gateway_user" {
  type        = any
  description = "User to use on gateway (default for SSH : current user)"
  default     = ""
}

variable "iap_project" {
  type        = string
  description = "IAP only - GCP project in which the gateway host is located"
  default     = ""
}

variable "iap_zone" {
  type        = string
  description = "IAP only - GCP zone in which the gateway host is located"
  default     = ""
}

variable "kubectl_cmd" {
  type        = string
  description = "Alternate command for 'kubectl' (including options)"
  default     = "kubectl"
}

variable "kubectl_context" {
  type        = string
  description = "Kubectl target context"
  default     = ""
}

variable "kubectl_namespace" {
  type        = string
  description = "Kubectl target namespace"
  default     = ""
}

variable "local_host" {
  type        = string
  description = "Local host name or IP. Set only if you cannot use default value"
  default     = "127.0.0.1"
}

variable "local_port" {
  type        = number
  description = "Local port to use. Default causes the system to find an unused port number"
  default     = "0"
}

variable "parent_wait_sleep" {
  type        = string
  description = "extra time to wait in the parent process for the child to create the tunnel"
  default     = "3"
}

variable "shell_cmd" {
  type        = string
  description = "Alternate command to launch a Posix shell"
  default     = "bash"
}

variable "ssh_cmd" {
  type        = string
  description = "Alternate command to launch the SSH client (including options)"
  default     = "ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no"
}

variable "ssh_private_key" {
  description = "Optional private key content to use for SSH tunneling"
  type        = string
  sensitive   = true
  default     = null
}

variable "gcloud_cmd" {
  type        = string
  description = "Alternate 'gcloud' command (GCP only)"
  default     = "gcloud"
}

variable "ssm_document_name" {
  type        = string
  description = "AWS SSM only - SSM Document Name"
  default     = "AWS-StartSSHSession"
}

variable "ssm_options" {
  type        = string
  description = "AWS SSM only - Options to add to the 'aws ssm start-session' command line"
  default     = ""
}

variable "ssm_profile" {
  type        = string
  description = "AWS SSM only - AWS profile (default: empty)"
  default     = ""
}

variable "ssm_role" {
  type        = string
  description = "AWS SSM only - Role to assume before starting the session (default: empty)"
  default     = ""
}

variable "target_host" {
  type        = string
  description = "Target host"
}

variable "target_port" {
  type        = number
  description = "Target port number"
}

variable "timeout" {
  type        = string
  description = "Timeout value ensures tunnel won't remain open forever - do not change"
  default     = "30m"
}

variable "tunnel_check_sleep" {
  type        = string
  description = "extra time to wait for the tunnel to become available"
  default     = "0"
}

variable "type" {
  type        = string
  description = "Gateway type"
  default     = "ssh"
}
