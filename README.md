
This terraform module allows to communicate with a resource via an SSH tunnel.

A typical usage can be to create and configure databases on AWS RDS instances.
Most often, RDS instances are connected to private subnets only and, so,
cannot be accessed directly by the host you're running terraform on.
Of course, you could run terraform on a host inside your AWS VPC but this
solution is far from perfect, especially
when you just want to test and debug code before commiting it. Going through
an SSH tunnel is much better.

This module just requires an SSH 'bastion' with
an account corresponding to your private key. It will create an SSH tunnel
through the bastion host to your private target host.

When supplying the target DNS name, note that the name will be resolved by the bastion.
So, you can pass AWS private DNS names without having to convert them to IP addresses first.

Example :

    # Your bastions are probably in an autoscaling group. Here's the way
    # to get a public IP address to use as gateway :

    data aws_instances bastions {
      instance_tags = {
        "aws:autoscaling:groupName" = "replace_with_bastion_autoscaling_group_name"
      }
    }
    
    #----
    
    module db_tunnel {
      source = "git::git@github.com:flaupretre/terraform-ssh-tunnel.git"
    
      target_host = aws_db_instance.mydb.address
      target_port = aws_db_instance.mydb.port
      gateway_host = data.aws_instances.bastions.public_ips[0]
      gateway_port = 22
    }
    
    #----
    
    provider mysql {
      endpoint = "${module.db_tunnel.host}:${module.db_tunnel.port}"
      username = aws_db_instance.mydb.username
      password = aws_db_instance.mydb.password
    }
    
    #---- Database
    
    resource mysql_database db {
      name = local.name
    }
    
    .... and other mysql_xxx resources...

Please note that you MUST use the 'module.db_tunnel.host' output variable
in the provider definition, even if the returned value is always the same.
If you don't, terraform won't create the required dependency to the SSH tunnel
and subsequent runs will fail when trying to refresh object states.

You may also be interested by the
[terraform-ssh-tunnel-databases](https://github.com/flaupretre/terraform-ssh-tunnel-databases)
module, as this modules uses terraform-sh-tunnel to manage MySql and PostgreSql
databases, roles, and permissions.

