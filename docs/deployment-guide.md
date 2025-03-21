# 371GPT Deployment Guide

This guide provides step-by-step instructions for deploying the 371GPT infrastructure and integrating it with the main 371GPT system.

## Deployment Process Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Infrastructure ├────►│  Application    ├────►│  Configuration  │
│  Deployment     │     │  Deployment     │     │  & Integration  │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## 1. Infrastructure Deployment (This Repository)

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- OVH Cloud account with API credentials
- OpenStack RC file or credentials
- SSH key pair configured in OVH Cloud

### Step-by-Step Deployment

1. **Clone this repository**:
   ```bash
   git clone https://github.com/ab1355/371gpt-infrastructure.git
   cd 371gpt-infrastructure
   ```

2. **Configure credentials**:
   - Copy the example variables file:
     ```bash
     cp terraform.tfvars.example terraform.tfvars
     ```
   - Edit `terraform.tfvars` with your specific credentials:
     ```
     ovh_endpoint = "ovh-eu"
     ovh_application_key = "your_app_key"
     ovh_application_secret = "your_app_secret"
     ovh_consumer_key = "your_consumer_key"
     public_key_path = "~/.ssh/id_rsa.pub"
     private_key_path = "~/.ssh/id_rsa"
     ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Preview the changes**:
   ```bash
   terraform plan -out=tfplan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply "tfplan"
   ```

6. **Note the outputs**:
   - After successful deployment, Terraform will display outputs including:
     - IP addresses for each service
     - Access credentials
     - Network configuration details
   - Save these for the next steps

## 2. Application Deployment

After deploying the infrastructure, you need to deploy the application components from the main 371GPT repository.

### Prerequisites

- Access to the deployed infrastructure
- Docker and Docker Compose (for local testing)
- Git

### Step-by-Step Deployment

1. **Clone the main 371GPT repository**:
   ```bash
   git clone https://github.com/ab1355/371GPT.git
   cd 371GPT
   ```

2. **Configure environment variables**:
   - Copy the example environment file:
     ```bash
     cp .env.example .env
     ```
   - Update the environment variables with the infrastructure outputs:
     ```
     # Database connection (from infrastructure outputs)
     DB_HOST=<supabase_instance_ip>
     DB_PORT=5432
     DB_NAME=371gpt
     DB_USER=<database_user>
     DB_PASSWORD=<database_password>
     
     # Service endpoints (from infrastructure outputs)
     XPIPE_HOST=<xpipe_instance_ip>
     XPIPE_PORT=8080
     
     # API credentials (from your providers)
     OPENAI_API_KEY=<your_openai_key>
     PORTKEY_API_KEY=<your_portkey_key>
     ```

3. **Deploy the application services**:
   - For Docker Compose deployment:
     ```bash
     docker-compose up -d
     ```
   - For Podman deployment on Windows:
     ```powershell
     .\run-with-podman.ps1
     ```
   - For Podman deployment on Linux/macOS:
     ```bash
     chmod +x run-with-podman.sh
     ./run-with-podman.sh
     ```

4. **Verify service deployment**:
   - Check that all services are running:
     ```bash
     docker-compose ps
     # or
     podman pod ps
     ```
   - Verify logs for any errors:
     ```bash
     docker-compose logs -f
     # or
     podman logs -f <container-name>
     ```

## 3. Configuration & Integration

After deploying both infrastructure and applications, you need to configure them to work together.

### Step-by-Step Configuration

1. **Access the admin interface**:
   - Navigate to the UI service: `http://<ui_instance_ip>:8000`
   - Login with the default credentials (see `docs/admin-guide.md` in the main repository)

2. **Configure service connections**:
   - In the admin interface, navigate to "System Configuration"
   - Update the service endpoints with the values from the infrastructure deployment
   - Save the configuration

3. **Initialize the system**:
   - In the admin interface, run the "System Initialization" workflow
   - This will:
     - Set up the database schema
     - Configure the agent orchestration
     - Initialize the knowledge base

4. **Test the deployment**:
   - Follow the testing procedures in `docs/testing-guide.md` in the main repository
   - Verify all services are communicating correctly

## Maintenance and Operations

### Regular Maintenance

1. **Backup database**:
   ```bash
   # From the main repository
   ./scripts/backup-database.sh
   ```

2. **Update infrastructure**:
   ```bash
   # From the infrastructure repository
   git pull
   terraform plan
   terraform apply
   ```

3. **Update application**:
   ```bash
   # From the main repository
   git pull
   docker-compose pull
   docker-compose up -d
   ```

### Monitoring

1. **Check system logs**:
   - Access the log viewer at `http://<ui_instance_ip>:8000/logs`
   - Monitor for any errors or warnings

2. **Infrastructure health**:
   - Use OVH Cloud dashboard to monitor resource utilization
   - Set up alerts for high CPU, memory, or disk usage

### Troubleshooting

For common issues and solutions, refer to:
- `docs/troubleshooting.md` in the main repository
- The Infrastructure FAQ in this repository's wiki

## Advanced Configurations

### High Availability Setup

For production deployments requiring high availability:

1. Update the Terraform configuration:
   - Modify `variables.tf` to enable high availability
   - Run `terraform apply` to update the infrastructure

2. Update the application configuration:
   - Modify `docker-compose.yml` to enable service replication
   - Deploy the updated configuration

### Custom Domain Configuration

To use custom domains for services:

1. Register your domain and add DNS records pointing to the service IPs
2. Configure SSL certificates (see `docs/ssl-configuration.md` in the main repository)
3. Update the service configurations to use the custom domains 