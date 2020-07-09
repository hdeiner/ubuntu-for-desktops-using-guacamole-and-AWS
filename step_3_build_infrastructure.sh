#!/usr/bin/env bash

terraform init
terraform apply -auto-approve

aws ec2 reboot-instances --region us-east-1 --instance-ids $(terraform output ubuntu_desktop_ec2_id | grep -Eo 'i\-[0-9a-z]*')