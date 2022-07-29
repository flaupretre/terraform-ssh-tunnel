
variable "create" {
  type = bool
  description = "If false, do nothing and return target host"
  default = true
}

variable "python_cmd" {
  type = string
  description = "Command to run python"
  default = "python"
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
  description = "Name or IP of SSH gateway - empty string if no gateway (direct connection)"
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
  default = "0s"
}
