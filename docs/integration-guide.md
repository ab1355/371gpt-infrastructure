# 371GPT Integration Guide

This guide explains how the Terraform-managed infrastructure connects to and supports the main 371GPT system components.

## System Integration Overview

The 371GPT infrastructure provides the foundation for the entire system. Here's how the different components work together:

```
┌────────────────────────────────────────────────────────────────┐
│                     371GPT System                              │
│                                                                │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │  UI Layer   │     │ Agent Layer │     │ API Layer   │       │
│  │ (NiceGUI)   ├────►│ (Python)    ├────►│ (FastAPI)   │       │
│  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘       │
│         │                   │                   │              │
│         │                   │                   │              │
│         ▼                   ▼                   ▼              │
│  ┌─────────────────────────────────────────────────────┐       │
│  │                Infrastructure Layer                  │       │
│  │                                                      │       │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │       │
│  │  │  Compute    │  │  Database   │  │  Storage    │  │       │
│  │  │  Resources  │  │  Services   │  │  Services   │  │       │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │       │
│  │                                                      │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Integration Points

### 1. Compute Resources to Application Containers

| Infrastructure Component | Maps to Application Component | Integration Method |
|--------------------------|-------------------------------|-------------------|
| 371GPT Core instance     | Agent Containers              | SSH/Docker API    |
| XPipe Server instance    | Data Pipeline Services        | SSH/Docker API    |
| Kespa Service instance   | Automation Services           | SSH/Docker API    |

### 2. Database Services to Application Data

| Infrastructure Component | Maps to Application Component | Integration Method |
|--------------------------|-------------------------------|-------------------|
| Supabase Database        | Agent Memory Store            | PostgreSQL Connection |
| Supabase Database        | Vector Knowledge Base         | PostgreSQL + pgvector |
| Supabase Database        | User Management               | PostgreSQL + Auth API |

### 3. Storage Services to Application Assets

| Infrastructure Component | Maps to Application Component | Integration Method |
|--------------------------|-------------------------------|-------------------|
| Object Storage           | AI Model Storage              | S3-compatible API |
| Object Storage           | Document Repository           | S3-compatible API |
| Object Storage           | System Backups                | S3-compatible API |

## Connection Configuration

### Environment Variables

The application services connect to the infrastructure using environment variables defined in `.env`. Here's how they map:

```
# Infrastructure Connection Variables
DB_HOST=<supabase_instance_ip>         # From Terraform output
DB_PORT=5432                           # Standard PostgreSQL port
DB_NAME=371gpt                         # Database name
DB_USER=<database_user>                # From Terraform output
DB_PASSWORD=<database_password>        # From Terraform output

STORAGE_ENDPOINT=<storage_endpoint>    # From Terraform output
STORAGE_ACCESS_KEY=<access_key>        # From Terraform output
STORAGE_SECRET_KEY=<secret_key>        # From Terraform output
STORAGE_BUCKET=371gpt-assets           # Bucket name

XPIPE_HOST=<xpipe_instance_ip>         # From Terraform output
XPIPE_PORT=8080                        # XPipe service port
```

### Connection Security

Secure connections between application services and infrastructure are established using:

1. **Private Network**: All services communicate over the private network defined in Terraform
2. **Security Groups**: Connections are limited to specific ports and protocols
3. **TLS Encryption**: All connections use TLS for data in transit
4. **API Keys**: Authentication is required for all service connections

## Integration Process

### Step 1: Deploy Infrastructure

Use Terraform to provision the infrastructure resources:

```bash
terraform apply
```

After deployment, gather the output values:

```bash
terraform output
```

### Step 2: Prepare Application Configuration

Create or update the `.env` file in the main 371GPT repository with values from the Terraform output:

```bash
# In the main 371GPT repository directory
cp .env.example .env
# Edit .env with the infrastructure values
```

### Step 3: Deploy Application Services

Deploy the application services:

```bash
# In the main 371GPT repository directory
docker-compose up -d
```

### Step 4: Verify Integration

Verify successful integration:

1. Check database connectivity:
   ```bash
   docker-compose exec db-service python -c "import os; import psycopg2; conn = psycopg2.connect(host=os.environ['DB_HOST'], dbname=os.environ['DB_NAME'], user=os.environ['DB_USER'], password=os.environ['DB_PASSWORD']); print('Connection successful')"
   ```

2. Check storage connectivity:
   ```bash
   docker-compose exec storage-service python -c "import boto3; s3 = boto3.resource('s3', endpoint_url=os.environ['STORAGE_ENDPOINT'], aws_access_key_id=os.environ['STORAGE_ACCESS_KEY'], aws_secret_access_key=os.environ['STORAGE_SECRET_KEY']); print('Storage connection successful')"
   ```

3. Check XPipe connectivity:
   ```bash
   docker-compose exec xpipe-client curl -s http://${XPIPE_HOST}:${XPIPE_PORT}/health
   ```

## Common Integration Issues

### Database Connection Issues

**Problem**: Unable to connect to the Supabase database.

**Solution**:
1. Verify the database instance is running:
   ```bash
   terraform state show openstack_compute_instance_v2.supabase
   ```
2. Check the security group allows connections:
   ```bash
   terraform state show openstack_networking_secgroup_rule_v2.db_rule
   ```
3. Verify the database credentials in the `.env` file match the Terraform outputs.

### Storage Connection Issues

**Problem**: Unable to connect to the object storage.

**Solution**:
1. Verify the storage service is available:
   ```bash
   terraform output storage_endpoint
   ```
2. Ensure the access keys are correctly configured in the `.env` file.
3. Check if the bucket exists and is accessible.

### Network Connectivity Issues

**Problem**: Services cannot communicate with each other.

**Solution**:
1. Verify all services are on the same network:
   ```bash
   terraform state show openstack_networking_network_v2.private
   ```
2. Check security group rules allow internal communication.
3. Verify DNS resolution is working correctly between services.

## Advanced Integration Scenarios

### Integrating with External Services

To connect the 371GPT system with external services like RapidAPI:

1. Configure the external-facing API endpoints in the infrastructure:
   ```terraform
   # In your Terraform configuration
   resource "openstack_networking_floatingip_v2" "api_ip" {
     pool = "public"
   }
   
   resource "openstack_compute_floatingip_associate_v2" "api_ip_assoc" {
     floating_ip = openstack_networking_floatingip_v2.api_ip.address
     instance_id = openstack_compute_instance_v2.api_server.id
   }
   ```

2. Update the external service configuration to point to the new API endpoint.

### Scaling the Infrastructure

When scaling the 371GPT system:

1. Update the Terraform configuration to provision additional resources:
   ```terraform
   # In your Terraform configuration
   variable "agent_count" {
     description = "Number of agent instances to deploy"
     default     = 3
   }
   
   resource "openstack_compute_instance_v2" "agent_servers" {
     count       = var.agent_count
     name        = "agent-server-${count.index}"
     image_name  = "Ubuntu 20.04"
     flavor_name = "s1-4"
     # ...
   }
   ```

2. Update the application configuration to utilize the additional resources:
   ```yaml
   # In docker-compose.yml
   services:
     agent-service:
       image: 371gpt/agent-service
       deploy:
         replicas: ${AGENT_COUNT:-3}
   ```

## Conclusion

By following this integration guide, you've connected the Terraform-managed infrastructure to the 371GPT application services. This integrated system provides a scalable and robust platform for AI agent orchestration, suitable for various business and research applications. 