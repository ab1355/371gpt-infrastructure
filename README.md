# 371GPT Infrastructure

This repository contains Terraform configuration for deploying 371GPT infrastructure on OVH Cloud.

## Architecture Components

- **371GPT Core**: Main AI orchestration service
- **XPipe Server**: Data pipeline management
- **Supabase**: Database with vector capabilities (replacing PostgreSQL + MongoDB)
- **Kespa**: Automation service

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- OVH Cloud account
- OpenStack credentials for OVH
- SSH key pair configured in OVH Cloud

## Setup Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/371gpt-infrastructure.git
   cd 371gpt-infrastructure
   ```

2. Copy the example variables file and add your credentials:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your credentials
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Preview the changes:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Environment Variables

For Windows, run the provided setup script:
```
setup-env.bat
```

For Linux/Mac, source the OpenStack RC file:
```bash
source openrc.sh
```

## Security Configurations

The infrastructure includes:
- Dedicated security groups with properly configured firewall rules
- Internal network for communication between services
- Limited external access to necessary ports only

## Resource Specifications

- **GPT Core**: s1-8 instance (8 vCPUs, 16GB RAM)
- **Supabase**: s1-8 instance with 200GB storage
- **XPipe**: s1-4 instance (4 vCPUs, 8GB RAM)
- **Kespa**: s1-4 instance with 50GB storage

## Maintenance

To update the infrastructure:
```bash
terraform plan
terraform apply
```

To tear down the infrastructure:
```bash
terraform destroy
```

## Monitoring & Management

Access IP addresses for each service will be displayed in the outputs after successful deployment. 