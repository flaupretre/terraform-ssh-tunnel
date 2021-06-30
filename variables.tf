
variable "create" {
  type = bool
  description = "If false, do nothing"
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
  default = "ssh"
}

variable "ssh_config" {
  type = string
  description = "SSH Config file to use"
  default = "~/.ssh/config"
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
  description = "Name or IP of SSH gateway"
}

variable "gateway_user" {
  type = any
  description = "User to use on SSH gateway (default = current username)"
  default = ""
}

variable "timeout" {
  type = string
  description = "Timeout value ensures tunnel cannot remain open forever"
  default = "30m"
}
