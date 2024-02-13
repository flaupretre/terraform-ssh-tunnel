Note: This is version 2, a major version including a lot of new features, the most important addition being the support
of several new tunnel mechanisms in addition to SSH. Compatibility should be preserved for terraform code already using
version 1 : new variables were added but the former ones are usable as-is and the module output does not change.

Some of these additions are adapted from the multiple forks of this project. I had a look to the changes committed
in these forks and integrated the ideas I found interesting. Github is not the ideal place to ask permission for this. So,
if you think I shouldn't have taken an idea from your code without telling you, feel free to contact me.
Once again, thanks to all who give time and energy to the community.

As some of this code was not tested thoroughly and, sometimes, not tested at all, please consider SSH tunnels to be
the only gateway ready for production purpose. If you experiment another one, I'm very interested by the experience
you may have, positive or negative. Of course, comments and suggestions are always welcome.

----

This terraform module allows to manage a 'remote' resource via a tunnel. A tunnel (aka <i>gateway</i>, aka <i>bastion host</i>)
provides a bidirectionnal connection between a 'public' area and a 'private'
area. Terraform runs on a host located in the 'public ' area and uses the gateway to
access a target host & port located in the 'private' area.

This is used, for instance, to create and configure databases on AWS RDS instances.
Creating RDS instances is easy, as it uses the public AWS API, but creating
databases is more complex because it requires connecting to the RDS instance which,
usually, is accessible from private subnets only.

Running terraform on a host inside the private area is a possible solution, often used by Terraform automation software like [Atlantis](https://www.runatlantis.io/) but generally too complex
to install and manage. It also does not allow accessing more than one private areas from
a single location. So, for a lot of users, using tunnels is the best solution.

Initially, only SSH tunnels were supported, hence the module name. Version 2 added suport for other tunnel mechanisms. So, we now support :

- [SSH tunnels](https://www.ssh.com/academy/ssh/tunneling-example)
- [AWS Systems Manager (SSM)](https://docs.aws.amazon.com/systems-manager/latest/userguide/)
    - [Using SSH for doing the Port Forwarding](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#sessions-start-ssh)
    - [Using the direct port forwarding from AWS SSM without going through SSH](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#sessions-remote-port-forwarding)
- [Google IAP](https://cloud.google.com/iap/docs/using-tcp-forwarding)
- [Kubernetes port forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

You can also provide your own shell script if your gateway is not supported yet.

---
<!--ts-->
- [Supported gateways](#supported-gateways)
  - [SSH](#ssh)
    - [Using multiple SSH gateways (ProxyJump)](#using-multiple-ssh-gateways-proxyjump)
    - [Target host name resolution](#target-host-name-resolution)
  - AWS SSM
    - [Using an SSH Tunnel](#aws-ssm-via-ssh)
    - [Directly via AWS SSM without SSH](#aws-ssm-directly)
  - [Google IAP](#google-iap)
  - [Kubernetes port forwarding](#kubernetes-port-forwarding)
  - [External](#external)
- [Module output](#module-output)
- [Tunnel conditional creation](#tunnel-conditional-creation)
- [Environment](#environment)
- [Requirements](#requirements)
  - [Posix shell](#posix-shell)
  - ['timeout' utility](#timeout-utility)
  - ['nohup' utility](#nohup-utility)
  - [SSH client](#ssh-client)
  - [AWS CLI](#aws-cli)
  - [Kubectl](#kubectl)
  - [gcloud CLI](#gcloud-cli)
- [Limitations](#limitations)
  - [Running terraform apply from plan out](#running-terraform-apply-from-plan-out)
- [Examples](#examples)
- [To do](#to-do)
  - [Add support for Azure bastion host tunnels](#add-support-for-azure-bastion-host-tunnels)
- [Requirements](#requirements-1)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->
<!-- Added by: flaupretre, at: Sat Aug 19 14:30:13 UTC 2023 -->

<!--te-->

## Supported gateways

### SSH

Initially, it was the only supported gateway. It remains the default.

In order to use this gateway, you need to have a bastion host running some SSH server software. This host
must be directly accessible from the host running terraform. It must also have a direct access to the
target host & port.

You cannot use passwords to open the SSH connection. So, every potential user must be registered on the
bastion host along with the appropriate public key. In order to avoid this key management, an alternative
is to share a key between authorized users but keeping a shared secret secure is also a complex task.

See below the default value for the 'ssh_cmd' input variable. These are the command
and options used by default to launch the SSH client. You can change them if the default value does not
correspond to your environment or if you need specific options to be added to the
command line. This can be needed, for instance, to sspecify the path of the private key to use.

#### Using multiple SSH gateways (ProxyJump)

Please note that the module cannot
be used to create a tunnel running through a set of several SSH gateways, each
one opening an SSH connection to the
next one. This is technically possible using the 'ProxyJump' feature introduced
in OpenSSH v7.3 and the feature might appear in a future version if there's a real user's demand.

#### Target host name resolution

Note that, when supplying a target DNS name, the name is resolved by the
bastion host, not by the client you're running terraform on. So, you can use a private
DNS name, like 'xxxx.csdfkzpf0iww.eu-west-1.rds.amazonaws.com'
without having to convert it to an IP address first.

### AWS SSM (via SSH)

The feature is adapted from the [terraform-ssm-tunnel](https://github.com/littlejo/terraform-ssm-tunnel/tree/master) fork by [Joseph Ligier](https://github.com/littlejo). Many thanks to Joseph for this addition.

If you're using AWS, you can open a tunnel using AWS SSM ([AWS Systems
manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/)). In this case,
a 'Session Manager SSH session' is opened from your desktop
to an EC2 instance via the AWS API. This session is, then, connected with another
connection to the target host.

The benefits of using SSM, compared to a bare SSH tunnel, are :

- you don't need to maintain a bastion host anymore,
- you still need an EC2 instance but this instance does not have to expose any port, as the connection is done via the much safer AWS API public endpoints,
- permissions can be managed per user/group using IAM roles and policies (no more public key management).

Note that, since all traffic goes through the AWS API, this can be used on a fully-private platform (a platform without public subnets).

Of course, this requires [an AWS SSM agent to be installed and configured
correctly on the EC2 gateway](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#sessions-start-ssh). SSM agent version must be 2.3.672.0 or later.

How to activate the SSM variant :

- Configure the EC2 gateway and attach appropriate policies
- Configure security groups so that the EC2 gateway can access the target host & port,
- set 'type' to 'ssm'
- set 'gateway_host' to the instance ID of the EC2 gateway
- set 'gateway_user' to the appropriate name (see documentation), generally
  'ec2-user' ('ubuntu' when using Ubuntu-based AMIs).
- Optional: set `aws_assume_role` to assume a role before opening the SSM session (e.g. into a different AWS account)
- As an option, add environment variables, like 'AWS_PROFILE', into the 'env' input array.

### AWS SSM (directly)
Additionally to the method above, there is support to use the `ssm_direct` method that does not use SSH for the port forwarding but rather directly uses the [port forwarding feature](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#sessions-remote-port-forwarding) of AWS SSM. This has the advantage, that it also works with AWS ECS Tasks that are cheaper to operate than EC2 machines. You need to provide the following variables for this variant:

- set `type` to `ssm_direct`
- set 'gateway_host' to the instance ID of the EC2 gateway or to the container id of the ECS task (i.e. `ecs:cluster-dev_76f81c3a205d40f795a66a1f11a7547b_76f81c3a205d40f795a66a1f11a7547b-4098987087`
- set `target_host` and `target_port` as normal

The following example shows how to use an EC2 jump host to connect to EKS:
```
data "aws_eks_cluster" "cluster" {
  name = "cluster-name"
}

data "aws_instance" "jump_node" {

  filter {
    name   = "tag:Name"
    values = ["cluster-name-bastion"]
  }
}

module "tunnel" {
  version           = "2.0.0"
  type              = "ssm_direct"

  gateway_host = data.aws_instance.jump_node.id
  gateway_user = "ec2-user"
  target_host  = data.aws_eks_cluster.cluster.endpoint
  target_port  = 443
}
```

The following example shows how to use a container running inside a task inside an ECS cluster to connect to an RDS machine:
```
// Fetch the RDS Instance
data "aws_db_instance" "database" {
  db_instance_identifier = var.rds_instance_identifier
}

// Open a tunnel via AWS SSM to RDS through the ECS container
module "db_tunnel" {
  source  = "flaupretre/tunnel/ssh"
  version = "2.0.0"

  type            = "ssm_direct"

  target_host  = data.aws_db_instance.database.address
  target_port  = data.aws_db_instance.database.port
  // TODO: Compute dynamically
  // Format for ECS is: "ecs:[ecs cluster name]_[ecs task id]_[ecs container id]"
  gateway_host = "ecs:m79-platform-dev_2ac3750fa9704bf5b4cd387078bd0b9d_2ac3750fa9704bf5b4cd387078bd0b9d-4098987087"
}

provider "postgresql" {
  host            = module.db_tunnel.host
  port            = module.db_tunnel.port
  database        = "postgres"
  username        = data.aws_db_instance.database.master_username
  password        = var.rds_masteruser_password
}
```

  
### Google IAP

This feature is EXPERIMENTAL and was never tested. You use it under your total responsibility.
Among others, no assumption should be made on the security level it provides.

This gateway uses the Google Identity-Aware Proxy (IAP) feature to create a tunnel to a private target host and port.

Functionally, the mechanism is quite similar to AWS SSM as it requires an existing Google VM instance to be used as gateway but
it does not require this instance to expose anything on the public networks. Actually, an SSH tunnel is created
between the Google internal IAP hosts and the target host & port, going through the bastion VM.

### Kubernetes port forwarding

In order to access a server running in a Kubernetes pod, you can use the 'kubectl' gateway. This gateway
uses Kubernetes 'port forwarding' mechanism to create a bidirectionnal tunnel to the target server.
Of course, it requires the
target object to expose at least one port.

This gateway is activated by setting the 'type' variable to 'kubectl'.

The 'gateway_host' input variable has the same syntax as the 'kubectl port-forward' command argument : 'pod/xxx',
'deployment/xxx', 'service/xxx'... Targeting a K8S service, if it exists, should be preferred to benefit
from the K8S load-balancing features.

The 'kubectl_context' and 'kubectl_namespace' input variables should be set to determine the target
context and namespace. If it is not set, the
current context and namespace (as set in your kube config file) will be used, which is probably
not what you want. You can also enrich the 'kubectl_cmd' variable with additional options.

### External

If a tunnel mechanism is not supported yet, you can provide the code for it.
Just set 'type' to 'external', write a shell script file and set its path as 'external_script'.
The script will be sourced by a shell interpreter in order to create the tunnel.

Refer to the existing
scripts in the 'gateways' subdirectory as examples to understand how to get the parameters.
Your script must also set
an environment variable named TUNNEL_PID. This must contain the PID of the
process handling the tunnel.

If other users may be interested, feel free to move it into the 'gateways'
subdirectory, add the required documentation in the README.md file,  and submit a pull request.

## Module output

The module returns two values : 'host' and 'port'. These values define the tunnel's
'local' endpoint. When you connect a subsequent provider to this endpoint, it will
transparently access the target resource. Obviously, each remote resource corresponds
to a separate tunnel. If you're accessing multiple remote resources, you need to
create one tunnel per resource, so one module call per resource and, then, one
provider instance per tunnel. For instance, accessing multiple 'private' RDS
instances requires one tunnel per RDS instance and each module call will output a different 'port' value.

By default, the local host and port values are automatically determined, automatically choosing an unused port on the
host where terraform is running. In special cases and if you know what you're doing, you can
force these values via the 'local_host' and 'local_port' input variables. Once again, do this at your own risk,
the default behavior should be fine in most cases.

## Tunnel conditional creation

When the 'create' input variable is false or the 'gateway_host'
input variable is an empty string, no tunnel
is created and the target host and port are returned as outputs, causing a direct connection
to the target.

This makes the module usable in a scenario where you cannot determine in advance whether
the connection will require a tunnel or not.

## Environment

The SSH client process inherits your environment, including a
possible SSH agent configuration to retrieve your private key.

If you want to set and/or replace environment variables before creating the tunnel,
you can provide a non-empty 'env' input variable. This string will be 'eval'uated
before launching the command to create the tunnel. When using an SSM connection, for instance, it can be used to set the 'AWS_PROFILE' variable.

## Requirements

### Posix shell

A Posix-compatible shell should be available.

We use 'bash' by default but you can change it to another string by setting
the 'shell_cmd' input variable.

On Windows, I think it can run with the cygwin environment but I can't
help on this.

### 'timeout' utility

This module requires the 'timeout' utility to be installed on the host.

On MacOS, the 'timeout' utility is not installed by default. You can install it
via homebrew with 'brew install coreutils' (source: https://stackoverflow.com/a/70109348).

### 'nohup' utility

You also need the 'nohup' utility. On MacOS again, it seems 'nohup' may be
missing and people have reported using 'gnohup' instead.

If you are on MacOS and can provide some logic to check for this and
determine the command to use, please tell me.

### SSH client

In order to use the 'ssh' or 'ssm' gateways, an SSH client software must be installed on the terraform host.
The command to launch this client can be modified via the 'ssh_cmd' variable.

### AWS CLI

The 'ssm' and the `ssm_direct` gateway types requires AWS CLI to be installed and configured (the profile whose name is
passed as 'aws_profile' must be defined).

The EC2 gateway or ECS task instance must run an SSM agent configured to allow SSM sessions and permissions must
be set accordingly. IAM policies must also allow access from the EC2 gateway to the target host & port.

### Kubectl

In order to use the 'kubectl' gateway, you need the 'kubectl' utility to be installed on the terraform host.

You also need :

- the 'kubectl_context' you pass to be defined in the kube config file,
- appropriate permissions to access the corresponding cluster,
- the namespace you set as 'kubectl_namespace' to exist
- and, of course, the target resource must exist in this namespace.

### gcloud CLI

The 'iap' gateway type requires [gcloud CLI to be installed](https://cloud.google.com/sdk/docs/install)
and configured on the terraform host.

IAP and the bastion host must also be configured to allow creating an SSH tunnel from
the IAP hosts (35.235.240.0/20 according to the [Google documentation](https://cloud.google.com/iap/docs/using-tcp-forwarding))
to the target host & port (see [this page](https://www.padok.fr/en/blog/iap-gcp-bastion-apis) for more details).

## Limitations

If you have ideas/suggestions on the issues below, please share.

### Running terraform apply from plan out

When running terraform apply from a plan output this module does not work.

    terraform plan -input=false -out tf.plan
    terraform apply -input=false -auto-approve tf.plan

## Examples

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
      version      = "2.0.0"

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

## To do

If you want to contribute to the project, here are somme ideas and suggestions.

### Add support for Azure bastion host tunnels

[This document](https://learn.microsoft.com/en-us/cli/azure/network/bastion?view=azure-cli-latest)
gives information about Azure bastion hosts. These can be used as gateways to open a CLI connection
to a target virtual machine using the [az](https://learn.microsoft.com/fr-fr/cli/azure/) CLI command.
I don't know if it can connect to service like DB instances.

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
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS SSM only - AWS profile | `string` | `""` | no |
| <a name="input_create"></a> [create](#input\_create) | If false, do nothing and return target host | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | An array of name -> value environment variables | `any` | `{}` | no |
| <a name="input_external_script"></a> [external\_script](#input\_external\_script) | External only - Path of shell script to run to open the tunnel | `string` | `"undef"` | no |
| <a name="input_gateway_host"></a> [gateway\_host](#input\_gateway\_host) | Gateway (syntax and meaning depend on gateway type - empty if no gateway (direct connection) | `any` | `""` | no |
| <a name="input_gateway_port"></a> [gateway\_port](#input\_gateway\_port) | Gateway port | `number` | `22` | no |
| <a name="input_gateway_user"></a> [gateway\_user](#input\_gateway\_user) | User to use on gateway (default for SSH : current user) | `any` | `""` | no |
| <a name="input_kubectl_cmd"></a> [kubectl\_cmd](#input\_kubectl\_cmd) | Alternate command for 'kubectl' (including options) | `string` | `"kubectl"` | no |
| <a name="input_kubectl_context"></a> [kubectl\_context](#input\_kubectl\_context) | Kubectl target context | `string` | `""` | no |
| <a name="input_kubectl_namespace"></a> [kubectl\_namespace](#input\_kubectl\_namespace) | Kubectl target namespace | `string` | `""` | no |
| <a name="input_local_host"></a> [local\_host](#input\_local\_host) | Local host name or IP. Set only if you cannot use default value | `string` | `"127.0.0.1"` | no |
| <a name="input_local_port"></a> [local\_port](#input\_local\_port) | Local port to use. Default causes the system to find an unused port number | `number` | `"0"` | no |
| <a name="input_parent_wait_sleep"></a> [parent\_wait\_sleep](#input\_parent\_wait\_sleep) | extra time to wait in the parent process for the child to create the tunnel | `string` | `"3"` | no |
| <a name="input_putin_khuylo"></a> [putin\_khuylo](#input\_putin\_khuylo) | Do you agree that Putin doesn't respect Ukrainian sovereignty and territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo! | `bool` | `true` | no |
| <a name="input_shell_cmd"></a> [shell\_cmd](#input\_shell\_cmd) | Alternate command to launch a Posix shell | `string` | `"bash"` | no |
| <a name="input_ssh_cmd"></a> [ssh\_cmd](#input\_ssh\_cmd) | Alternate command to launch the SSH client (including options) | `string` | `"ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no"` | no |
| <a name="input_ssm_document_name"></a> [ssm\_document\_name](#input\_ssm\_document\_name) | AWS SSM only - SSM Document Name | `string` | `"AWS-StartSSHSession"` | no |
| <a name="input_ssm_options"></a> [ssm\_options](#input\_ssm\_options) | AWS SSM only - Options to add to the 'aws ssm start-session' command line | `string` | `""` | no |
| <a name="input_target_host"></a> [target\_host](#input\_target\_host) | Target host | `string` | n/a | yes |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | Target port number | `number` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout value ensures tunnel won't remain open forever - do not change | `string` | `"30m"` | no |
| <a name="input_tunnel_check_sleep"></a> [tunnel\_check\_sleep](#input\_tunnel\_check\_sleep) | extra time to wait for the tunnel to become available | `string` | `"0"` | no |
| <a name="input_type"></a> [type](#input\_type) | Gateway type | `string` | `"ssh"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host"></a> [host](#output\_host) | Host to connect to |
| <a name="output_port"></a> [port](#output\_port) | Port number to connect to |
<!-- END_TF_DOCS -->
