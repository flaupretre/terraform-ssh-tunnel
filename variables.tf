
variable "create" {
  type = bool
  description = "If false, do nothing and return target host"
  default = true
}

variable "type" {
  type = string
  description = "Tunnel type (['ssh'], 'ssm', or 'external')"
  default = "ssh"
}

variable "shell_cmd" {
  type = string
  description = "Command to run a shell"
  default = "bash"
}

variable "ssh_cmd" {
  type = string
  description = "Shell command to use to start ssh client"
  default = "ssh -o StrictHostKeyChecking=no"
}

variable "env" {
  type = string
  description = "String to eval before launching the tunnel"
  default = ""
}

variable "local_host" {
  type = string
  description = "Local host name or IP. Set only if you cannot use the '127.0.0.1' default value"
  default="127.0.0.1"
}

variable "target_host" {
  type = string
  description = "The target host. Name will be resolved by gateway"
}

variable "target_port" {
  type = number
  description = "Target port number"
}

variable "gateway_host" {
  type = any
  default = ""
  description = "Gateway (name or IP for SSH, Instance ID for SSM) - empty if no gateway (direct connection)"
}

variable "gateway_user" {
  type = any
  description = "User to use on SSH gateway (default = empty string = current username)"
  default = ""
}

variable "gateway_port" {
  type = number
  description = "Gateway port"
  default = 22
}

variable "timeout" {
  type = string
  description = "Timeout value ensures tunnel won't remain open forever"
  default = "30m"
}

variable "ssh_tunnel_check_sleep" {
  type = string
  description = "extra time to wait for ssh tunnel to connect"
  default = "0"
}

variable "ssh_parent_wait_sleep" {
  type = string
  description = "extra time to wait in the tunnel parent process for the child ssh tunnel startup"
  default = "3"
}

variable "ssm_document_name" {
  type = string
  description = "For SSM only - SSM Document Name"
  default = "AWS-StartSSHSession"
}

variable "external_script" {
  type = string
  description = "Path of external script if type is 'external'"
  default = "undef"
}

variable "putin_khuylo" {
  description = "Do you agree that Putin doesn't respect Ukrainian sovereignty and territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo!"
  type        = bool
  default     = true
}
