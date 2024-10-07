output "ec2-id" {
    value = aws_instance.fortinet.id
}
output "public_ip" {
    value = aws_eip.eip.public_ip
}
