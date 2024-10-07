output "vpc_id" {
  description = "The id of the VPC."
  value       = "${aws_vpc.vpc.id}"
}
output "vpc_cidr" {
  description = "The CDIR block used for the VPC."
  value       = "${aws_vpc.vpc.cidr_block}"
}
output "public_subnets" {
  description = "A list of the public subnets."
  value       = ["${aws_subnet.public_subnet1.id}","${aws_subnet.public_subnet2.id}","${aws_subnet.public_subnet3.id}"]
}
output "public_subnets_cidr" {
  description = "A list of the public subnets."
  value       = ["${aws_subnet.public_subnet1.cidr_block}","${aws_subnet.public_subnet2.cidr_block}","${aws_subnet.public_subnet3.cidr_block}"]
}
output "private_subnets" {
  description = "A list of the private subnets."
  value       = ["${aws_subnet.private_subnet1.id}","${aws_subnet.private_subnet2.id}","${aws_subnet.private_subnet3.id}"]
}
output "private_subnets_cidr" {
  description = "A list of the public subnets."
  value       = ["${aws_subnet.db_subnet1.cidr_block}","${aws_subnet.db_subnet2.cidr_block}","${aws_subnet.db_subnet3.cidr_block}"]
}
output "db_subnets" {
  description = "A list of the private subnets."
  value       = ["${aws_subnet.db_subnet1.id}","${aws_subnet.db_subnet2.id}","${aws_subnet.db_subnet2.id}","${aws_subnet.db_subnet3.id}"]
}
output "db_subnets_cidr" {
  description = "A list of the public subnets."
  value       = ["${aws_subnet.db_subnet1.cidr_block}","${aws_subnet.db_subnet2.cidr_block}","${aws_subnet.db_subnet3.cidr_block}"]
}
output "availability_zones" {
  description = "List of the availability zones."
  value       = "${var.availability_zones[var.aws_region]}"
}
output "sg_nat" {
  value = aws_security_group.sg_nat
}
output "sg_private" {
  value = aws_security_group.sg_private
}

/*
output "public_routing_tables"{
  value = [aws_route_table.public_routetable1,aws_route_table.public_routetable2]
}
*/

output "main-route-table"{
  value = aws_vpc.vpc.default_route_table_id
}

/*
output "private_dns_zone_id" {
  description = "The id of the private DNS zone, if not created an empty string."
  value       = "${element(concat(aws_route53_zone.local.*.id),0)}"
}

output "private_domain_name" {
  description = "The name assigned to the private DNS zone, if not created an empty string."
  value       = "${element(concat(aws_route53_zone.local.*.name),0)}"
}
*/