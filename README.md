
This terraform module allows to communicate with a resource via an SSH tunnel.

It is used, for instance, to create and configure databases on AWS RDS instances.
Creating RDS instances is easy, as it uses the AWS API, which is public but, creating
databases is harder because it requires connecting to the instance which is,
usually, connected to private subnets only.
Running terraform on a host inside the AWS VPC would be a solution but often too complex
to install and manage.

An alternate solution is to access remote resources via
an SSH tunnel through an SSH bastion host. There are two conditions :

- The bastion host can open a connection to the target host/port,
- and you can open an SSH connection to the bastion from your client.

## Tunnel conditional creation

When the 'create' input variable is false or the 'gateway_host'
input variable is an empty string, no tunnel
is created and the target host and port are returned, causing a direct connection
to the target.

So, this module can be used in a scenario where you don't know in advance if
your connection will require a tunnel or not, passing configuration parameters you receive
from the outside, and using the host/port you receive from the module.

## SSH command and options

By default, the module uses the 'ssh -o StrictHostKeyChecking=no' string
in the command to launch the SSH client. If you use a different SSH client name/path or
if you want to add/remove options, you can modify this string by setting the
'ssh_cmd' input variable.
This may be used, for instance, to set the private key to use with a '-i' option.

## Target host name resolution

When supplying the target DNS name, the name will be resolved by the
bastion host, not by the client you're running terraform on. So, you can use a private
DNS name, like 'xxxx.csdfkzpf0iww.eu-west-1.rds.amazonaws.com'
without having to convert it to an IP address first.

## SSH agent

The SSH client process inherits your environment, including a
possible SSH agent configuration to retrieve your private key.

## Multiple SSH gateways

Please also note that the module cannot
be used to create a tunnel running through a set of several SSH gateways, each
one opening an SSH connection to the
next one. This is technically possible using the 'ProxyJump' feature introduced
in OpenSSH v7.3 and the feature may be added in a future version, depending on user's
demand (I personally don't need it yet).

## Related resources

You may also be interested by the
[terraform-ssh-tunnel-databases](https://github.com/flaupretre/terraform-ssh-tunnel-databases)
module, which uses SSH tunnels to manage MySql/PostgreSql databases, roles, and
permissions.

## Example

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
      version      = "1.10.0"

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
| <a name="input_gateway_host"></a> [gateway\_host](#input\_gateway\_host) | Name or IP of SSH gateway - empty string if no gateway (direct connection) | `any` | `""` | no |
| <a name="input_gateway_port"></a> [gateway\_port](#input\_gateway\_port) | Gateway port | `number` | `22` | no |
| <a name="input_gateway_user"></a> [gateway\_user](#input\_gateway\_user) | User to use on SSH gateway (default = empty string = current username) | `any` | `""` | no |
| <a name="input_local_host"></a> [local\_host](#input\_local\_host) | Local host name or IP. Set only if you cannot use the '127.0.0.1' default value | `string` | `"127.0.0.1"` | no |
| <a name="input_putin_khuylo"></a> [putin\_khuylo](#input\_putin\_khuylo) | Do you agree that Putin doesn't respect Ukrainian sovereignty and territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo! | `bool` | `true` | no |
| <a name="input_shell_cmd"></a> [shell\_cmd](#input\_shell\_cmd) | Command to run a shell | `string` | `"bash"` | no |
| <a name="input_ssh_cmd"></a> [ssh\_cmd](#input\_ssh\_cmd) | Shell command to use to start ssh client | `string` | `"ssh -o StrictHostKeyChecking=no"` | no |
| <a name="input_ssh_tunnel_check_sleep"></a> [ssh\_tunnel\_check\_sleep](#input\_ssh\_tunnel\_check\_sleep) | extra time to wait for ssh tunnel to connect | `string` | `"0s"` | no |
| <a name="input_ssh_parent_wait_sleep"></a> [ssh\_parent\_wait\_sleep](#input\_ssh\_parent\_wait\_sleep) | extra time to wait in the parent process for the child ssh tunnel to open ports | `string` | `"3s"` | no |
| <a name="input_target_host"></a> [target\_host](#input\_target\_host) | The target host. Name will be resolved by gateway | `string` | n/a | yes |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | Target port number | `number` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout value ensures tunnel won't remain open forever | `string` | `"30m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host"></a> [host](#output\_host) | Host to connect to |
| <a name="output_port"></a> [port](#output\_port) | Port number to connect to |
<!-- END_TF_DOCS -->
