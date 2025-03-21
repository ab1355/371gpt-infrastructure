# 371GPT Infrastructure

This repository contains Terraform configuration for deploying 371GPT infrastructure on OVH Cloud.

## System Overview

371GPT is a scalable, ethical AI orchestration system for non-coders based on the DSF (Discover, Space, Flow) model. This system enables non-technical users to harness the power of AI agents through intuitive interfaces and automated deployment.

This infrastructure repository is a component of the larger [371GPT system](https://github.com/ab1355/371GPT), focusing specifically on the cloud infrastructure deployment using Terraform.

## Key Features

- **Accessibility**: No-code interfaces for system configuration and management
- **Scalability**: Microservice architecture with dynamic agent creation
- **Ethics**: Built-in guardrails and monitoring for responsible AI use
- **Robustness**: Self-healing error handling and comprehensive logging

## Architecture Components

### Core Infrastructure
- **371GPT Core**: Main AI orchestration service with multiple specialized agents
- **XPipe Server**: Data pipeline management for knowledge processing
- **Supabase**: Database with vector capabilities (replacing PostgreSQL + MongoDB)
- **Kespa**: Automation service for workflow orchestration

### Application Components
- **FastAPI Gateway**: Internal API gateway for agent communication
- **Agenta**: Development environment for creating and testing AI agents
- **NocoDB**: No-code database for configuration management
- **NiceGUI**: Web-based admin interface for system management

## Documentation

### Infrastructure Documentation

- [Infrastructure Architecture](docs/infrastructure-architecture.md) - Detailed explanation of infrastructure components
- [Deployment Guide](docs/deployment-guide.md) - Step-by-step instructions for deploying infrastructure
- [Integration Guide](docs/integration-guide.md) - How to integrate with the main 371GPT system

### Main System Documentation

For more comprehensive information about the 371GPT system:

- [Architecture Overview](https://github.com/ab1355/371GPT/blob/main/docs/architecture.md)
- [Comprehensive Guide](https://github.com/ab1355/371GPT/blob/main/docs/comprehensive-guide.md)
- [Testing Guide](https://github.com/ab1355/371GPT/blob/main/docs/testing-guide.md)
- [Troubleshooting](https://github.com/ab1355/371GPT/blob/main/docs/troubleshooting.md)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- OVH Cloud account
- OpenStack credentials for OVH
- SSH key pair configured in OVH Cloud

## Setup Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/ab1355/371gpt-infrastructure.git
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
- Role-based access control
- Comprehensive audit logging

## Resource Specifications

### Core Resources
- **GPT Core**: s1-8 instance (8 vCPUs, 16GB RAM)
- **Supabase**: s1-8 instance with 200GB storage
- **XPipe**: s1-4 instance (4 vCPUs, 8GB RAM)
- **Kespa**: s1-4 instance (4 vCPUs, 8GB RAM) with 50GB storage

### Application Resources
- **FastAPI Gateway**: s1-4 instance (4 vCPUs, 8GB RAM)
- **Agenta**: s1-8 instance (8 vCPUs, 16GB RAM) with 100GB storage
- **NocoDB**: s1-4 instance (4 vCPUs, 8GB RAM) with 50GB storage
- **NiceGUI**: s1-4 instance (4 vCPUs, 8GB RAM)

## Networking

The infrastructure is configured with:

- **Private Network**: All services communicate over a secure 192.168.1.0/24 network
- **Security Groups**: Firewall rules limit access to appropriate services
- **Open Ports**:
  - SSH (22) - Admin access
  - HTTP/HTTPS (80/443) - Web interfaces
  - Application ports (8000, 8080, 8081, 8090) - Service APIs
  - Database port (5432) - Limited to internal network

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

## Integration with Full System

This infrastructure repository provides the cloud resources needed to run the complete 371GPT system. After deploying this infrastructure, you'll need to:

1. Deploy the application services defined in the [main 371GPT repository](https://github.com/ab1355/371GPT)
2. Configure the connections between services as defined in the architecture documentation
3. Set up the proper networking and security rules

## Related Documentation

For more comprehensive information about the 371GPT system:

- [Architecture Overview](https://github.com/ab1355/371GPT/blob/main/docs/architecture.md)
- [Comprehensive Guide](https://github.com/ab1355/371GPT/blob/main/docs/comprehensive-guide.md)
- [Testing Guide](https://github.com/ab1355/371GPT/blob/main/docs/testing-guide.md)
- [Troubleshooting](https://github.com/ab1355/371GPT/blob/main/docs/troubleshooting.md)

## Business Implementation

For information on implementing this system for business purposes, refer to:
- [371 Minds Implementation Plan](https://github.com/ab1355/371GPT/blob/main/docs/371-minds-implementation.md)
- [Pimcore & Odoo Integration](https://github.com/ab1355/371GPT/blob/main/docs/pimcore-odoo-integration.md)
- [RapidAPI & XPipe Integration](https://github.com/ab1355/371GPT/blob/main/docs/rapidapi-xpipe-integration.md)

## Monitoring & Management

Access IP addresses for each service will be displayed in the outputs after successful deployment.

### Service Access URLs

After deployment, services can be accessed at:

- **NiceGUI Admin**: `http://<nicegui_ip>:8080`
- **Agenta Development**: `http://<agenta_ip>:8090`
- **NocoDB**: `http://<nocodb_ip>:8081`
- **FastAPI Gateway**: `http://<fastapi_gateway_ip>:8000` 