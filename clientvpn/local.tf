locals {
  clientvpn_vpc_test_cidr                                   = "10.225.64.0/24"
  clientvpn_vpc_test_private_subnets                        = ["10.225.64.0/25", "10.225.64.128/25"]
  clientvpn_vpc_test_azs                                    = ["us-west-2a", "us-west-2b"]
  SAMLProviderArn                                           = "arn:aws:iam::150843090732:saml-provider/MCKID_VPN"
  ClientvpnCidrBlock                                        = "192.140.0.0/18"
  ServerCertificateArn                                      = "arn:aws:acm:us-west-2:150843090732:certificate/d6353a9e-64ea-465f-9c5a-07f675b03b64"
  resource_vpc_test_cidr                                    = "10.224.140.0/23"
  resource_vpc_test_azs                                     = ["us-west-2a", "us-west-2b"]
  resource_vpc_test_private_subnets                         = ["10.224.140.0/25", "10.224.140.128/25"]
  resource_vpc_test_public_subnets                          = ["10.224.141.0/25", "10.224.141.128/25"]
  ingress_from_port                                         = 443
  ingress_to_port                                           = 443
  ingress_protocol                                          = "tcp"
  egress_from_port                                          = 5432
  egress_to_port                                            = 5432
  egress_protocol                                           = "tcp"
  environment                                               = "dev"
}