# 371GPT Infrastructure - Quick Start Guide

This guide provides a quick overview of how to deploy the 371GPT infrastructure on OVH Cloud using Terraform. For more detailed instructions, refer to the main README.md file.

## Prerequisites

Before you begin, ensure you have:

- [PowerShell 7+](https://github.com/PowerShell/PowerShell/releases) installed
- [Terraform 1.0+](https://www.terraform.io/downloads.html) installed
- OVH Cloud account with valid API credentials
- SSH key pair configured in your OVH Cloud account

## 5-Minute Deployment Guide

### 1. Clone the Repository

```powershell
git clone https://github.com/ab1355/371gpt-infrastructure.git
cd 371gpt-infrastructure
```

### 2. Run the Test Script

Verify your environment is properly configured:

```powershell
.\test_setup.ps1
```

This will check:
- If PowerShell and Terraform are installed
- If required files exist
- If network connectivity to OVH APIs is working

### 3. Set Up Your Environment

Run the setup script to create and validate your configuration:

```powershell
.\setup.ps1
```

The setup script will:
- Create a terraform.tfvars file if it doesn't exist
- Verify required credentials are present
- Initialize Terraform

### 4. Deploy the Infrastructure

Run the deployment script:

```powershell
.\deploy.ps1
```

This will:
- Validate your credentials
- Create a Terraform plan
- Apply the plan to create your infrastructure
- Output the IP addresses and other details when complete

## Configuration Overview

The key configuration files are:

- **terraform.tfvars**: Your credentials and infrastructure settings
- **main.tf**: Provider configuration and security groups
- **network.tf**: Network resources (VPC, subnets)
- **agents.tf**: AI agent instance definitions
- **orchestration.tf**: Kubernetes cluster configuration

## Quick Reference: Common Commands

### Check Infrastructure State

```powershell
terraform state list
```

### Get Output Values (IPs, etc.)

```powershell
terraform output
```

### Make Configuration Changes

After changing any .tf files:

```powershell
terraform plan -out=tfplan
terraform apply tfplan
```

### Clean Up All Resources

```powershell
terraform destroy
```

## Troubleshooting

If you encounter issues, check:

1. **Authentication Problems**:
   - Verify your OVH API credentials using `.\verify_ovh.ps1`
   - For new credentials, see `GetNewOVHCredentials.md`

2. **Deployment Failures**:
   - Check `TroubleshootingDeployment.md` for common issues and solutions
   - Review the latest log file in the project directory

3. **Resource Creation Issues**:
   - Verify you have sufficient quota in your OVH account
   - Check that the requested flavors and images are available

## Next Steps

After deployment:

1. **Access Your Infrastructure**:
   - Connect via SSH: `ssh -i <your-ssh-key> ubuntu@<instance-ip>`
   - The IPs are shown in the deployment output

2. **Configure Kubernetes**:
   - Follow the Kubernetes documentation to set up your cluster
   - Use the provided Ansible playbooks for easier configuration

3. **Deploy the Applications**:
   - Clone the 371GPT application repository
   - Follow the instructions in `docs/deployment-guide.md` to deploy apps

## Getting Help

For additional assistance:

- Review the full documentation in README.md
- Check the OVH Cloud documentation for platform-specific issues
- Open an issue in the GitHub repository for persistent problems