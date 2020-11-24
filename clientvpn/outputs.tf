output "client_vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id
}

output "clientvpn_vpc_test_id" {
  value = "${module.clientvpn_vpc_test.vpc_id}"
}

output "clientvpn_vpc_test_private_subnets" {
  value = "${module.clientvpn_vpc_test.private_subnets}"
}

output "Security_group_us_east_1_id" {
  value = "${aws_security_group.clientvpn_security_group.id}"
}



