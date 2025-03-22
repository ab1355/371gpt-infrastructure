# 371GPT Terraform Deployment Troubleshooting Guide

This guide covers common issues you might encounter when deploying the 371GPT infrastructure using Terraform with OVH Cloud and how to resolve them.

## Table of Contents

1. [Authentication Issues](#authentication-issues)
   - [OVH API Authentication Failures](#ovh-api-authentication-failures)
   - [OpenStack Authentication Failures](#openstack-authentication-failures)
2. [Resource Creation Issues](#resource-creation-issues)
   - [Instance Creation Failures](#instance-creation-failures)
   - [Volume Attachment Issues](#volume-attachment-issues)
3. [Network Configuration Issues](#network-configuration-issues)
   - [Network Creation Errors](#network-creation-errors)
   - [Security Group Configuration Issues](#security-group-configuration-issues)
4. [Deployment Script Issues](#deployment-script-issues)
   - [PowerShell Execution Policy](#powershell-execution-policy)
   - [Script Permission Problems](#script-permission-problems)
5. [General Troubleshooting](#general-troubleshooting)
   - [Terraform State Issues](#terraform-state-issues)
   - [Terraform Provider Problems](#terraform-provider-problems)
6. [Getting Help](#getting-help)

## Authentication Issues

### OVH API Authentication Failures

**Symptoms:**
- Error message: "OVH API credentials are invalid"
- Error message: "Invalid application key", "Invalid application secret", or "Invalid consumer key"
- Error message: "Unauthorized: The api key doesn't have access to this resource"

**Solutions:**
1. **Verify credentials in terraform.tfvars**:
   - Check that `ovh_application_key`, `ovh_application_secret`, and `ovh_consumer_key` are set correctly
   - Ensure there are no extra spaces or quotes around the values

2. **Generate new API credentials**:
   - Follow the steps in `GetNewOVHCredentials.md` to create new API keys
   - Ensure you're creating keys for the correct endpoint (US, EU, CA, etc.)

3. **Check endpoint configuration**:
   - In `main.tf`, verify that the OVH provider's endpoint matches your account region:
     ```hcl
     provider "ovh" {
       endpoint           = "ovh-us"  # Change this depending on your region
       application_key    = var.ovh_application_key
       application_secret = var.ovh_application_secret
       consumer_key       = var.ovh_consumer_key
     }
     ```

4. **Verify permissions**:
   - Ensure your API keys have sufficient permissions for the resources you're trying to create
   - For full deployment, your keys need GET/POST/PUT/DELETE on cloud/* paths

### OpenStack Authentication Failures

**Symptoms:**
- Error message: "Error creating OpenStack block storage client: Authentication failed"
- Error message: "Error creating OpenStack compute client: Unable to get token"
- Error message: "Required environment variable OS_AUTH_URL not set"

**Solutions:**
1. **Check OpenStack credentials**:
   - Verify all fields in `terraform.tfvars`: `os_tenant_id`, `os_tenant_name`, `os_username`, `os_password`, `os_region_name`
   - Ensure the region name is formatted correctly (e.g., `US-EAST-VA`, not `US-EAST-VA-1`)

2. **Update provider configuration**:
   - In `main.tf`, ensure your OpenStack provider has all required fields:
     ```hcl
     provider "openstack" {
       auth_url      = "https://auth.cloud.ovh.us/v3"
       domain_name   = "Default"
       tenant_id     = var.os_tenant_id
       tenant_name   = var.os_tenant_name
       user_name     = var.os_username
       password      = var.os_password
       region        = var.os_region_name
     }
     ```

3. **Run the verification script**:
   - Execute `./verify_ovh.ps1` to check your credentials and generate an OpenStack RC file
   - Use the output to diagnose authentication issues

4. **Check for expired credentials**:
   - OVH OpenStack passwords may need to be refreshed periodically
   - Generate a new password in the OVH Cloud Manager if necessary

## Resource Creation Issues

### Instance Creation Failures

**Symptoms:**
- Error message: "Error creating instance: Resource not found"
- Error message: "Quota exceeded for instances: Requested X, but already used Y of Z"
- Error message: "No valid host was found"

**Solutions:**
1. **Verify resource availability**:
   - Check your OVH Cloud Manager to ensure you have sufficient quota for the requested resources
   - Verify that the requested instance flavors (e.g., `s1-8`, `s1-4`) are available in your region

2. **Check image names**:
   - Ensure the specified image names match exactly what's available in your OVH account
   - In `terraform.tfvars`, verify `agent_image` is set to a valid image name (e.g., `"Ubuntu 20.04"`)

3. **Retry with different resources**:
   - Modify `terraform.tfvars` to use smaller instance flavors if quota is an issue
   - Try a different region if resources are constrained in your current region

4. **Check network configuration**:
   - Ensure the network referenced in instance configurations exists or can be created
   - Verify security groups exist and have proper rules

### Volume Attachment Issues

**Symptoms:**
- Error message: "Error attaching volume to instance"
- Error message: "volume is not available"
- Error message: "Workflow requires instance to be in ACTIVE state"

**Solutions:**
1. **Check volume configuration**:
   - Ensure volume sizes in `terraform.tfvars` are within allowed limits
   - Verify that `agent_volume_type` is set to a valid volume type (e.g., `"classic"`)

2. **Verify dependencies**:
   - Ensure that instances are fully created before attempting to attach volumes
   - Check that volumes are in "available" state before attachment

3. **Try sequential creation**:
   - Modify Terraform configuration to create and attach volumes one at a time
   - Use explicit dependencies with `depends_on` if necessary

4. **Check instance compatibility**:
   - Ensure the instance type supports attachable volumes
   - Verify the maximum number of volumes per instance hasn't been exceeded

## Network Configuration Issues

### Network Creation Errors

**Symptoms:**
- Error message: "Error creating network"
- Error message: "Quota exceeded for networks"
- Error message: "Conflict in subnet pool IP allocation"

**Solutions:**
1. **Check network quota**:
   - Verify in OVH Cloud Manager that you haven't exceeded network quotas
   - Clean up unused networks if necessary

2. **Verify subnet configuration**:
   - Ensure subnet CIDR blocks don't overlap with existing networks
   - In `network.tf`, confirm that the subnet CIDR is valid:
     ```hcl
     resource "openstack_networking_subnet_v2" "subnet" {
       name        = "371minds-subnet"
       network_id  = openstack_networking_network_v2.network.id
       cidr        = "192.168.1.0/24"  # Adjust if this conflicts
       ip_version  = 4
       enable_dhcp = true
     }
     ```

3. **Clean up conflicting resources**:
   - Use `terraform state list` to identify existing network resources
   - Use `terraform destroy -target=RESOURCE` to remove specific conflicting resources

### Security Group Configuration Issues

**Symptoms:**
- Error message: "Error creating security group rule: Conflict"
- Error message: "Security group rule already exists"
- Error message: "Invalid CIDR in security group rule"

**Solutions:**
1. **Check for duplicate rules**:
   - Ensure security group rules in `main.tf` aren't duplicated
   - Use unique rule combinations (port, protocol, CIDR)

2. **Verify CIDR notation**:
   - Ensure all CIDRs in security group rules are correctly formatted
   - For all IPs, use `0.0.0.0/0` not just `0.0.0.0`

3. **Check rule limits**:
   - Security groups may have maximum rule limits
   - Consider consolidating rules if you're hitting limits

4. **Import existing resources**:
   - If rules already exist but aren't in Terraform state, import them:
     ```
     terraform import openstack_compute_secgroup_v2.secgroup SECURITY_GROUP_ID
     ```

## Deployment Script Issues

### PowerShell Execution Policy

**Symptoms:**
- Error message: "execution of scripts is disabled on this system"
- Scripts won't run even though they exist

**Solutions:**
1. **Check execution policy**:
   - Run PowerShell as Administrator
   - Check current policy with `Get-ExecutionPolicy`
   - Set a more permissive policy with `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

2. **Unblock scripts**:
   - Right-click on script files, select Properties
   - Check "Unblock" if present at the bottom

3. **Run with bypass**:
   - Execute scripts with explicit bypass: `powershell -ExecutionPolicy Bypass -File .\script.ps1`

### Script Permission Problems

**Symptoms:**
- Error message: "Access is denied"
- Scripts fail with permission errors

**Solutions:**
1. **Check file permissions**:
   - Ensure your user account has read/write permissions to the script files
   - Verify you have permissions to the directories where logs will be written

2. **Run as Administrator**:
   - Right-click PowerShell and select "Run as Administrator"
   - Execute scripts from the elevated prompt

3. **Check antivirus interference**:
   - Temporarily disable antivirus software that might be blocking script execution
   - Add exceptions for your Terraform working directory

## General Troubleshooting

### Terraform State Issues

**Symptoms:**
- "Error loading state"
- Resources showing as needing creation when they already exist
- terraform.tfstate file corruption

**Solutions:**
1. **Clean Terraform environment**:
   ```powershell
   rm -r .terraform
   rm terraform.tfstate
   rm terraform.tfstate.backup
   terraform init
   ```

2. **Import existing resources**:
   - If resources exist but aren't in state, import them:
     ```
     terraform import RESOURCE_TYPE.NAME ID
     ```

3. **Fix state manually**:
   - If state is corrupted, use `terraform state` commands to fix it:
     ```
     terraform state list
     terraform state rm RESOURCE_ADDRESS
     ```

### Terraform Provider Problems

**Symptoms:**
- "Provider not found" errors
- Errors about incompatible provider versions
- Plugin crashes

**Solutions:**
1. **Update providers**:
   ```powershell
   terraform init -upgrade
   ```

2. **Check provider versions**:
   - In `main.tf`, verify that provider version constraints are reasonable:
     ```hcl
     terraform {
       required_providers {
         ovh = {
           source  = "ovh/ovh"
           version = "~> 0.25.0"
         }
         openstack = {
           source  = "terraform-provider-openstack/openstack"
           version = "~> 1.49.0"
         }
       }
     }
     ```

3. **Clean provider cache**:
   - Remove the `.terraform` directory
   - Re-initialize Terraform with `terraform init`

4. **Check terraform.lock.hcl**:
   - If present, review the lock file for any provider issues
   - If problematic, delete it and run `terraform init` again

5. **Verify file formats**:
   - Ensure all `.tf` files are UTF-8 encoded without BOM
   - Check for syntax errors with `terraform validate`

6. **Increase verbosity**:
   - Run Terraform with increased logging: `TF_LOG=DEBUG terraform apply`
   - Check logs for specific provider issues

## Getting Help

If you continue to encounter issues:

1. **Consult OVH Documentation**:
   - [OVH Cloud Documentation](https://docs.ovh.com/us/en/)
   - [OVH API Documentation](https://api.us.ovhcloud.com/console/)

2. **Terraform Resources**:
   - [Terraform OpenStack Provider Docs](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs)
   - [Terraform OVH Provider Docs](https://registry.terraform.io/providers/ovh/ovh/latest/docs)

3. **Contact Support**:
   - For OVH account or API issues, contact [OVH Support](https://www.ovhcloud.com/en-us/support/)
   - For 371GPT specific issues, file a GitHub issue in the project repository