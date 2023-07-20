This terraform module allows to communicate with a resource via an SSH tunnel.

It is used, for instance, to create and configure databases on AWS RDS instances.
Creating RDS instances is easy, as it uses the AWS API, which is public but, creating
databases is more complex because it requires connecting to the RDS instance which is,
usually, connected to private subnets only.
Running terraform on a host inside the AWS VPC can be a solution but generally too complex
to install and manage.

An alternate solution is to access remote resources via
an SSH tunnel via a bastion host. The steps are :

- You open an SSH connection to the bastion from your client (using the bastion
  public IP address).
- and, then, the bastion host opens a connection to the target host/port using
  its connection to the private subnets,

---
<!--ts-->
   * [Tunnel conditional creation](#tunnel-conditional-creation)
   * [SSH command and options](#ssh-command-and-options)
   * [Target host name resolution](#target-host-name-resolution)
   * [Environment](#environment)
   * [Multiple SSH gateways](#multiple-ssh-gateways)
   * [SSM support](#ssm-support)
   * [External - Using a not-yet-supported mechanism](#external---using-a-not-yet-supported-mechanism)
   * [Requirements](#requirements)
      * [Posix shell](#posix-shell)
      * [timeout](#timeout)
      * [nohup](#nohup)
   * [Limitations](#limitations)
      * [Running terraform apply from plan out](#running-terraform-apply-from-plan-out)
   * [Example](#example)
   * [Requirements](#requirements-1)
   * [Providers](#providers)
   * [Modules](#modules)
   * [Resources](#resources)
   * [Inputs](#inputs)
   * [Outputs](#outputs)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->
<!-- Added by: flaupretre, at: Thu Jul 20 12:33:09 UTC 2023 -->

<!--te-->

## Tunnel conditional creation

When the 'create' input variable is false or the 'gateway_host'
input variable is an empty string, no tunnel
is created and the target host and port are returned as outputs, causing a direct connection
to the target.

This makes the module usable in a scenario where the fact that the connection
requires a tunnel cannot be determined in advance and depends on input parameters.

## SSH command and options

By default, the module uses the 'ssh -o StrictHostKeyChecking=no' string to launch
the SSH client. If you use a different SSH client name/path or
if you want to add/remove options, you can modify this string by setting the
'ssh_cmd' input variable.
This may be used, for instance, to add a '-i' option and set the private key to use.

## Target host name resolution

When supplying the target DNS name, the name is resolved by the
bastion host, not by the client you're running terraform on. So, you can use a private
DNS name, like 'xxxx.csdfkzpf0iww.eu-west-1.rds.amazonaws.com'
without having to convert it to an IP address first.

## Environment

The SSH client process inherits your environment, including a
possible SSH agent configuration to retrieve your private key.

If you to set and/or replace environment variables before creating the tunnel,
you can provide a non-empty 'env' input variable. This string will be 'eval'uated
before launching the command to create the tunnel. When using an SSM connection, for instance, it can be used to set the 'AWS_PROFILE' variable.

## Multiple SSH gateways

Please also note that the module cannot
be used to create a tunnel running through a set of several SSH gateways, each
one opening an SSH connection to the
next one. This is technically possible using the 'ProxyJump' feature introduced
in OpenSSH v7.3 and the feature may be added in a future version, depending on user's
demand (I personally don't need it yet).

## SSM support

This feature is still alpha (it was introduced in v 1.14.0). So, don't hesitate to
report any good or bad experience using it. Suggestions are welcome too.

The feature is adapted from the [terraform-ssm-tunnel](https://github.com/littlejo/terraform-ssm-tunnel/tree/master) fork by [Joseph Ligier](https://github.com/littlejo). Many thanks to Joseph for this addition.

If you're using AWS, you can also open a tunnel using AWS SSM ([AWS Systems
manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/)). In this case,
a 'Session Manager SSH session' is opened from your desktop
to an EC2 instance via the AWS API. This seesion is, then, connected with another
connection to the target host.

The benefits of using SSM, compared to a bare SSH bastion host, are :

- you don't need to maintain a bastion host anymore,
- you don't need to expose SSH ports on your gateway host, as the connection is done via the much safer AWS API public endpoints,
- permissions can be managed per user/group using IAM roles and policies

Note that, since all traffic goes through the AWS API, this can be used on a platform without any inbound access to an EC2 instance (even without public subnets).

Of course, this requires [the AWS SSM agent to be installed and configured
correctly on the EC2 gateway](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#sessions-start-ssh). SSM agent version must be 2.3.672.0 or later.

How to activate the SSM variant :

- Configure the EC2 gateway and define an appropriate policy
- Configure security groups so that the EC2 gateway can access the target host,
- set 'type' to 'ssm'
- set 'gateway_host' to the 'instance ID' of the gateway host
- set 'gateway_user' to the appropriate name (see documentation), generally
  'ec2-user' ('ubuntu' when using Ubuntu-based AMIs).
- if needed, set the AWS_PROFILE environment variable using the 'env' input var.

## External - Using a not-yet-supported mechanism

The code can be extended to use a mechanism the module does not support yet. If you
set the 'type' to 'external' and provide the path of a shell script as 'external_script',
this script will be sourced by a shell interpreter to create the tunnel.

You should use the existing
scripts in the 'gateways subdirectory as examples to understand how to get the parameters.
Your script must also set
an environment variable named CPID. This must contain the PID of the
process managing the tunnel.

If it can interest other users, feel free to move it into the 'gateways'
subdirectory and create a pull request.

## Requirements

### Posix shell

A Posix-compatible shell should be available.

We use 'bash' by default but you can change it to another string by setting
the 'shell_cmd' input variable.

On Windows, I think it can run with the cygwin environment but I can't
help on this.

### timeout

This module requires the 'timeout' utility to be installed on the host.

On MacOS, the 'timeout' utility is not installed by default. You can install it
via homebrew with 'brew install coreutils' (source: https://stackoverflow.com/a/70109348).

### nohup

You also need the 'nohup' utility. On MacOS again, it seems 'nohup' may be
missing and people have reported using 'gnohup' instead.

If you are on MacOS and can provide some logic to check for this and
determine the 'nohup' path to use, you're welcome.

## Limitations

If you have ideas/suggestions on the issues below, please share.

### Running terraform apply from plan out

When running terraform apply from a plan output this module does not work.

    terraform plan -input=false -out tf.plan
    terraform apply -input=false -auto-approve tf.plan

## Example

You may also be interested by the
[terraform-ssh-tunnel-databases](https://github.com/flaupretre/terraform-ssh-tunnel-databases)
module, which uses SSH tunnels to manage MySql/PostgreSql databases, roles, and
permissions.

    # On AWS, if your bastions are in an autoscaling group,here's a way
    # to get a public IP address to use as a gateway :

    data aws_instances bastions {
      instance_tags = {
        "aws:autoscaling:groupName" = "replace_with_bastion_autoscaling_group_name"
      }
    }
    
    #----
    
    module db_tunnel {
      # You can also retrieve this module from the terraform registry
      source       = "flaupretre/tunnel/ssh"
      version      = "1.14.0"

      target_host  = aws_db_instance.mydb.address
      target_port  = aws_db_instance.mydb.port

      gateway_host = data.aws_instances.bastions.public_ips[0]
    }
    
    #----
    
    provider mysql {
      alias    = "tunnel"

      endpoint = "${module.db_tunnel.host}:${module.db_tunnel.port}"

      # Target credentials
      username = aws_db_instance.mydb.username
      password = aws_db_instance.mydb.password
    }
    
    #---- DB resources
    
    resource mysql_database this {
      provider = mysql.tunnel
      name = local.name
    }
    
    resource mysql_user user {
      provider = mysql.tunnel
      ....

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [external_external.free_port](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.ssh_tunnel](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create"></a> [create](#input\_create) | If false, do nothing and return target host | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | String to eval before launching the tunnel | `string` | `""` | no |
| <a name="input_external_script"></a> [external\_script](#input\_external\_script) | Path of external script if type == 'external' | `string` | `"undef"` | no |
| <a name="input_gateway_host"></a> [gateway\_host](#input\_gateway\_host) | Gateway (name or IP for SSH, Instance ID for SSM) - empty if no gateway (direct connection) | `any` | `""` | no |
| <a name="input_gateway_port"></a> [gateway\_port](#input\_gateway\_port) | Gateway port | `number` | `22` | no |
| <a name="input_gateway_user"></a> [gateway\_user](#input\_gateway\_user) | User to use on SSH gateway (default = empty string = current username) | `any` | `""` | no |
| <a name="input_local_host"></a> [local\_host](#input\_local\_host) | Local host name or IP. Set only if you cannot use the '127.0.0.1' default value | `string` | `"127.0.0.1"` | no |
| <a name="input_putin_khuylo"></a> [putin\_khuylo](#input\_putin\_khuylo) | Do you agree that Putin doesn't respect Ukrainian sovereignty and territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo! | `bool` | `true` | no |
| <a name="input_shell_cmd"></a> [shell\_cmd](#input\_shell\_cmd) | Command to run a shell | `string` | `"bash"` | no |
| <a name="input_ssh_cmd"></a> [ssh\_cmd](#input\_ssh\_cmd) | Shell command to use to start ssh client | `string` | `"ssh -o StrictHostKeyChecking=no"` | no |
| <a name="input_ssh_parent_wait_sleep"></a> [ssh\_parent\_wait\_sleep](#input\_ssh\_parent\_wait\_sleep) | extra time to wait in the tunnel parent process for the child ssh tunnel startup | `string` | `"3"` | no |
| <a name="input_ssh_tunnel_check_sleep"></a> [ssh\_tunnel\_check\_sleep](#input\_ssh\_tunnel\_check\_sleep) | extra time to wait for ssh tunnel to connect | `string` | `"0"` | no |
| <a name="input_ssm_document_name"></a> [ssm\_document\_name](#input\_ssm\_document\_name) | For SSM only - SSM Document Name | `string` | `"AWS-StartSSHSession"` | no |
| <a name="input_target_host"></a> [target\_host](#input\_target\_host) | The target host. Name will be resolved by gateway | `string` | n/a | yes |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | Target port number | `number` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout value ensures tunnel won't remain open forever | `string` | `"30m"` | no |
| <a name="input_type"></a> [type](#input\_type) | Tunnel type (['ssh'], 'ssm', or 'external') | `string` | `"ssh"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host"></a> [host](#output\_host) | Host to connect to |
| <a name="output_port"></a> [port](#output\_port) | Port number to connect to |
<!-- END_TF_DOCS -->
