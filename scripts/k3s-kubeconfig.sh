#!/bin/bash
# Script to get kubeconfig from the k3s master node

# Check if instance ID is provided
if [ -z "$1" ]; then
  echo "Error: Instance ID not provided"
  exit 1
fi

INSTANCE_ID=$1

# Get the kubeconfig from the k3s master node using AWS SSM
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands=["cat /etc/rancher/k3s/k3s.yaml"] \
  --output text --query "Command.CommandId" > /tmp/command_id.txt

COMMAND_ID=$(cat /tmp/command_id.txt)

# Wait for the command to complete
aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID"

# Get the command output
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --output text --query "StandardOutputContent" | sed "s/127.0.0.1/$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)/g"