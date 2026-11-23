#!/usr/bin/env bash
# Creates the "app tier" security group that will be allowed to reach your database. Run once: ./setup.sh
set -u
H=$(bash "$(dirname "$0")/.lab/handle.sh") || exit 1
VPC=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
[ "$VPC" != None ] && [ -n "$VPC" ] || { echo "No default VPC found (or no working AWS credentials). This lab uses the default VPC." >&2; exit 1; }
if aws ec2 describe-security-groups --filters Name=group-name,Values=clippy-app-$H Name=vpc-id,Values=$VPC --query 'SecurityGroups[0].GroupId' --output text | grep -q '^sg-'; then echo "clippy-app-$H already exists."; exit 0; fi
SG=$(aws ec2 create-security-group --group-name clippy-app-$H --description "Clippy app tier (stands for the servers that will call the database)" --vpc-id $VPC --tag-specifications "ResourceType=security-group,Tags=[{Key=lab,Value=aws-rds-multi-az},{Key=student,Value=$H}]" --query GroupId --output text)
echo "Created security group clippy-app-$H ($SG) in the default VPC $VPC."
echo "Your database goes in the same VPC, in subnets of at least two availability zones."
