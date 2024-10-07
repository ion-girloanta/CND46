output "vpc_public_subnets_Israel" {
    value = "${module.vpc-Israel.public_subnets}"
}
output "vpc_private_subnets_Israel" {
    value = "${module.vpc-Israel.private_subnets}"
}
output "vpc_db_subnets_Israel" {
    value = "${module.vpc-Israel.db_subnets}"
}
/*
output "vpc_public_subnets_EU" {
    value = "${module.vpc-EU.public_subnets}"
}
output "vpc_private_subnets_EU" {
    value = "${module.vpc-EU.private_subnets}"
}
output "vpc_db_subnets_EU" {
    value = "${module.vpc-EU.db_subnets}"
}
output "availability_zones_EU" {
    value = "${module.vpc-EU.availability_zones}"
}
output "vpc-EU" {
    value = module.vpc-EU.vpc_id
}*/
output "availability_zones_Israel" {
    value = "${module.vpc-Israel.availability_zones}"
}
output "vpc-Israel" {
    value = module.vpc-Israel.vpc_id
}
output "vpn_instance_ip" {
    value = "" #module.ec2-Fortinet.public_ip
}
/*
output "dbUserName" {
    value = module.drupal-Israel.rds_username
}
*/
/*
output "private_key" {
    value     = tls_private_key.private_key.private_key_pem
    sensitive = true
}
*/