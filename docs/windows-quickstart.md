# Windows Quickstart Guide for 371GPT Infrastructure

This guide provides step-by-step instructions for setting up and deploying the 371GPT infrastructure on Windows.

## Prerequisites

1. Windows 10 or later
2. PowerShell 7.0 or later
3. Git for Windows
4. OpenStack credentials from OVH Cloud

## Initial Setup

1. Clone the repository:
   ```powershell
   git clone https://github.com/ab1355/371gpt-infrastructure.git
   cd 371gpt-infrastructure
   ```

2. Run the setup script:
   ```powershell
   .\setup-terraform.ps1
   ```
   This script will:
   - Install Chocolatey (if not already installed)
   - Install Terraform using Chocolatey
   - Configure environment variables
   - Initialize Terraform

3. Copy and configure variables:
   ```powershell
   Copy-Item terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` with your OVH Cloud credentials and desired configuration.

## Deployment

1. Review the deployment plan:
   ```powershell
   terraform plan -out tfplan
   ```

2. Apply the configuration:
   ```powershell
   terraform apply "tfplan"
   ```

3. Run the deployment script:
   ```powershell
   .\deploy.ps1
   ```

## Troubleshooting

### Common Issues

1. **Line Ending Issues**
   - The repository uses `.gitattributes` to handle line endings
   - No manual CRLF/LF conversion should be needed

2. **Permission Errors**
   - Run PowerShell as Administrator when needed
   - Ensure execution policy allows script execution:
     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
     ```

3. **Terraform Initialization Failures**
   - Clear the `.terraform` directory
   - Re-run `terraform init`

### Getting Help

- Open an issue on GitHub
- Check the main README.md for additional documentation
- Consult the OVH Cloud documentation

## Cleanup

To destroy the infrastructure:
```powershell
terraform destroy
```

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [OVH Cloud Documentation](https://docs.ovh.com)
- [PowerShell Documentation](https://docs.microsoft.com/powershell)