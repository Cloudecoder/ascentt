module "ec2" {
    source = "./ec2"
    sg_id = module.security_group.sg_id   
}

module "security_group" {
    source = "./security_group"
    
}

module "log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 2.0"

  name              = "cloud_watch"
  retention_in_days = 120
}





