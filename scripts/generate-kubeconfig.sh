#!/bin/bash
# Script to generate kubeconfig file for terraform to use with private k3s clusters

# Check if instance ID is provided
if [ -z "$1" ]; then
  echo "Error: Instance ID not provided"
  echo "Usage: $0 <INSTANCE_ID>"
  exit 1
fi

INSTANCE_ID=$1
OUTPUT_FILE="$(dirname "$0")/k3s-kubeconfig.yaml"

echo "Generating kubeconfig file at $OUTPUT_FILE..."

# Get the kubeconfig from the k3s master node using AWS SSM
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands=["cat /etc/rancher/k3s/k3s.yaml"] \
  --output text --query "Command.CommandId" > /tmp/command_id.txt

COMMAND_ID=$(cat /tmp/command_id.txt)

# Wait for the command to complete
aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID"

# Get the private IP address of the instance (since we're in private subnets)
IP_ADDRESS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

if [ -z "$IP_ADDRESS" ]; then
  echo "Error: Could not determine private IP address for instance $INSTANCE_ID"
  exit 1
fi

echo "Using private IP address: $IP_ADDRESS"

# Get the command output and replace localhost with the instance private IP
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --output text --query "StandardOutputContent" | sed "s/127.0.0.1/$IP_ADDRESS/g" > "$OUTPUT_FILE"

if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
  echo "Kubeconfig successfully generated at $OUTPUT_FILE"
  echo "This file will be used by Terraform to deploy resources to your K3s cluster in private subnets"
else
  echo "Error: Failed to generate kubeconfig file or file is empty"
  exit 1
fi