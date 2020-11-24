# This file contains configuration for resource VPCs used for Client VPN

locals {
  clientvpn_vpc_us_east_1_cidr                      = ""
  clientvpn_vpc_us_east_1_clientvpn_private_subnets = ["", ""]
  clientvpn_vpc_us_east_1_azs                       = ["us-east-1a", "us-east-1b"]
  SAMLProviderArn_us_east_1                         = "arn:aws:iam::2"
  ClientvpnCidrBlock_us_east_1                      = "192.146.0.0/18"
  ServerCertificateArn_us_east_1                    = "${aws_acm_certificate.clientvpn_us_east_1_cert.arn}"
  resource_vpc_us_east_1_cidr_blocks                = ""
  CloudwatchLogGroup_us_east_1                      = ""
  TransportProtocol                                 = "tcp"
  

}

### us-east-1

module "clientvpn_vpc_us_east_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.72.0"

  providers = {
    aws = "aws.us-east-1"
  }

  name = "lz-prod-pmk-clientvpn-vpc-us-east-1"

  cidr            = "${local.clientvpn_vpc_us_east_1_cidr}"
  azs             = ["${local.clientvpn_vpc_us_east_1_azs}"]
  private_subnets = ["${local.clientvpn_vpc_us_east_1_clientvpn_private_subnets}"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  enable_dhcp_options      = true
  dhcp_options_ntp_servers = ["169.254.169.123"]

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

data "aws_cloudwatch_log_group" "clientvpn_vpc_us_east_1" {
  provider = "aws.us-east-1"

  name = "${local.CloudwatchLogGroup_us_east_1}"
}

resource "aws_flow_log" "clientvpn_vpc_us_east_1" {
  provider = "aws.us-east-1"

  log_destination = "${data.aws_cloudwatch_log_group.clientvpn_vpc_us_east_1.arn}"
  iam_role_arn    = "${module.vpc_flow_logs_role.arn}"
  vpc_id          = "${module.clientvpn_vpc_us_east_1.vpc_id}"
  traffic_type    = "ALL"
}

data "aws_ssm_parameter" "clientvpn_us_east_1_server_key" {
  name = "/ncod/clientvpn/clientvpn_server.key"
}

data "aws_ssm_parameter" "clientvpn_us_east_1_server_cert" {
  name = "/ncod/clientvpn/clientvpn_server.crt"
}

data "aws_ssm_parameter" "clientvpn_us_east_1_ca_crt" {
  name = "/ncod/clientvpn/clientvpn_ca.crt"
}

resource "aws_acm_certificate" "clientvpn_us_east_1_cert" {
  private_key       = "${data.aws_ssm_parameter.clientvpn_us_east_1_server_key.value}"
  certificate_body  = "${data.aws_ssm_parameter.clientvpn_us_east_1_server_cert.value}"
  certificate_chain = "${data.aws_ssm_parameter.clientvpn_us_east_1_ca_crt.value}"
}


# vpc peering connection between Clientvpn vpc and shared resource vpc all in the same account. 
# no need to specify the owner account as both vpcs are in thesame account
resource "aws_vpc_peering_connection" "clientvpn_vpc_us_east_1" {
  provider = "aws.us-east-1"

  vpc_id      = "${module.clientvpn_vpc_us_east_1.vpc_id}"
  peer_vpc_id = "${module.resource_vpc_us_east_1.vpc_id}"
  auto_accept = true

  tags = {
    Name        = "VPC Peering between lz-prod-pmk-clientvpn-vpc-us-east-1 and resource_vpc_us_east_1"
    Side        = "Requester"
    Terraform   = "true"
    Environment = "prod"
  }
}

# due to bug https://github.com/hashicorp/terraform/issues/12570 this resource has to be excluded on first apply
resource "aws_route" "clientvpn_vpc_us_east_1" {
   provider = "aws.us-east-1"

   count                     = "${length(module.clientvpn_vpc_us_east_1.private_route_table_ids)}"
   route_table_id            = "${element(module.clientvpn_vpc_us_east_1.private_route_table_ids, count.index)}"
   destination_cidr_block    = "${local.resource_vpc_us_east_1_cidr_blocks}"
   vpc_peering_connection_id = "${aws_vpc_peering_connection.clientvpn_vpc_us_east_1.id}"
 
}


resource "aws_route" "lz-prod-ncc-resource_rt_us_east_1" {
  provider                  = "aws.us-east-1"
  count                     = "${length(module.resource_vpc_us_east_1.private_route_table_ids)}"
  route_table_id            = "${element(module.resource_vpc_us_east_1.private_route_table_ids, count.index)}"
  destination_cidr_block    = "${local.clientvpn_vpc_us_east_1_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.clientvpn_vpc_us_east_1.id}"
}

resource "aws_security_group" "clientvpn_security_group_us_east_1" {
  provider    = "aws.us-east-1"
  name        = "clientvpn_security_group"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${module.clientvpn_vpc_us_east_1.vpc_id}"

  ingress {
    description = "TLS from clientvpn_vpc_us_east_1"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${local.clientvpn_vpc_us_east_1_cidr}"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${local.resource_vpc_us_east_1_cidr_blocks}"]
  }

  egress {
    from_port   = 2022
    to_port     = 2022
    protocol    = "tcp"
    cidr_blocks = ["${local.resource_vpc_us_east_1_cidr_blocks}"]
  }

}

# this resouce is to create a client vpn endpoint. Terraform is calling the cft.
# we are using this because current version of terraform does not support client vpn endpoint

resource "aws_cloudformation_stack" "clientvpn-endpoint-stack_us_east_1" {
  name     = "clientvpn-endpoint-stack"
  provider = "aws.us-east-1"

  parameters = {
    SAMLProviderArn              = "${local.SAMLProviderArn_us_east_1}"
    ClientvpnCidrBlock           = "${local.ClientvpnCidrBlock_us_east_1}"
    TargetVpcSubnetId            = "${module.clientvpn_vpc_us_east_1.private_subnets[0]}"
    TargetVpcSubnetId2           = "${module.clientvpn_vpc_us_east_1.private_subnets[1]}"
    ServerCertificateArn         = "${local.ServerCertificateArn_us_east_1}"
    DestinationCidrBlock         = "${local.resource_vpc_us_east_1_cidr_blocks}"
    TransportProtocol            = "${local.TransportProtocol}"
    VPCID                        = "${module.clientvpn_vpc_us_east_1.vpc_id}"
    NetworkAssociationSubnetId   = "${module.clientvpn_vpc_us_east_1.private_subnets[0]}"
    NetworkAssociationSubnetId2  = "${module.clientvpn_vpc_us_east_1.private_subnets[1]}"
    SecurityGroupIds             = "${aws_security_group.clientvpn_security_group_us_east_1.id}"
    CloudwatchLogGroup           = "${local.CloudwatchLogGroup_us_east_1}"
    CloudwatchLogStream          = "${local.CloudwatchLogGroup_us_east_1}"
    TargetNetworkCidr1           = "${local.resource_vpc_us_east_1_cidr_blocks}"
    TargetNetworkCidr2           = "${local.clientvpn_vpc_us_east_1_cidr}"
  }

  template_body = "${file("clientvpnendpoint_us_east_1.yml")}"
}

output "clientvpn_vpc_us_east_1_id" {
  value = "${module.clientvpn_vpc_us_east_1.vpc_id}"
}

output "clientvpn_vpc_us_east_1_private_subnets" {
  value = "${module.clientvpn_vpc_us_east_1.private_subnets}"
}

output "Security_group_us_east_1_id" {
  value = "${aws_security_group.clientvpn_security_group.id}"
}
