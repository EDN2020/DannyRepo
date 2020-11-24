# Create providers for every AWS region.
# us-west-2 is the default.
# Regions pulled from:
# `aws ec2 describe-regions | jq '.Regions[].RegionName' -r | sort`

# Default
provider "aws" {
  region  = "us-west-2"
}

#