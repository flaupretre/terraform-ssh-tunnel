
This terraform module allows to communicate with a resource via an SSH tunnel. I use
it to configure MySql databases in AWS. As my databases are connected to private
subnets only, I cannot connect from the host I'm running terraform on. The solution
of running terraform on a host inside the VPC is far from perfect, especially
when you just want to test and debug your code before commiting it. So, once you
have a bastion host with an account authorizing your key, it should be possible to
use this module to connect to your resources behind the bastion.

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
    }
    
    #----
    
    provider mysql {
      endpoint = "127.0.0.1:${module.db_tunnel.port}"
      username = aws_db_instance.mydb.username
      password = aws_db_instance.mydb.password
    }
    
    #---- Database
    
    resource mysql_database db {
      name = local.name
    }
    
    .... and other mysql_xxx resources...
    