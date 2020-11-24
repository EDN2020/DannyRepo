variable "aws_region" {
  default = "us-east-1"
}

variable "client_cidr_block" {
  description = "The IPv4 address range, in CIDR notation being /22 or greater, from which to assign client IP addresses"
  default     = "10.225.64.0/24"
}

variable "vpc_id" {
  default     = "vpc-cd99dcb5"
  description = "The ID of the VPC to associate with the Client VPN endpoint."
}

variable "subnet_id" {
  type        = string
  default     = "subnet-05d5b0b1fc47c9b79"
  description = "The ID of the subnet to associate with the Client VPN endpoint."
}

variable "domain" {
  default = "aws-clientvpn.com"
}

variable "server_cert" {
  default     = "arn:aws:acm:us-east-1:684912126428:certificate/8de078d4-46c6-437b-ad26-bbd7a84df596"
  description = "Server certificate"
}

variable "client_cert" {
  default     =  "arn:aws:iam::684912126428:saml-provider/JJTECH-Onelogin"
  description = "Client/Root certificate"
}

variable "split_tunnel" {
  default = "true"
}

variable "dns_servers" {
  type = list
  default = []
}