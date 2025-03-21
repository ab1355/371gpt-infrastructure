# 371GPT Infrastructure Architecture

This document explains how the Terraform infrastructure configuration maps to the overall 371GPT system architecture.

## Infrastructure Overview

The 371GPT infrastructure is designed to be deployed on OVH Cloud using Terraform. It provides the foundation for running the multi-agent AI orchestration system with all its components.

```
┌─────────────────────────────────────────────────────────────────────┐
│                           OVH Cloud                                 │
│                                                                     │
│  ┌─────────────┐        ┌─────────────┐        ┌─────────────┐      │
│  │             │        │             │        │             │      │
│  │  371GPT     │◄──────►│  Supabase   │◄──────►│  FastAPI    │      │
│  │  Core       │        │  Database   │        │  Gateway    │      │
│  │             │        │             │        │             │      │
│  └─────┬───────┘        └─────────────┘        └──────┬──────┘      │
│        │                                              │             │
│        │                                              │             │
│        ▼                                              ▼             │
│  ┌─────────────┐        ┌─────────────┐        ┌─────────────┐      │
│  │             │        │             │        │             │      │
│  │  XPipe      │◄──────►│  Kespa      │◄──────►│  Agenta     │      │
│  │  Server     │        │  Service    │        │  Dev        │      │
│  │             │        │             │        │             │      │
│  └──────┬──────┘        └─────────────┘        └─────────────┘      │
│         │                                                           │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────┐        ┌─────────────┐                             │
│  │             │        │             │                             │
│  │  NocoDB     │◄──────►│  NiceGUI    │                             │
│  │  Config     │        │  Admin UI   │                             │
│  │             │        │             │                             │
│  └─────────────┘        └─────────────┘                             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Components and Mapping

### 1. Network Layer (`network.tf`)

The network configuration establishes:
- Private network for secure internal communication
- Router for connecting services
- Security groups defining access rules

This layer maps to the **Infrastructure Layer** in the overall architecture, providing secure connectivity between all components.

### 2. Database Layer (`database.tf`)

The database configuration provisions:
- Supabase instance with vector database capabilities
- Persistent storage volumes
- Backup configurations

This maps to the data storage needs of the 371GPT system, including:
- Vector storage for agent knowledge
- Relational data for business operations
- Document storage for unstructured data

### 3. Storage Layer (`storage.tf`)

The storage configuration provisions:
- Object storage for models, datasets, and files
- Backup storage for system state
- Content repositories

This maps to the **Content Repository** aspect of the overall architecture, supporting the Pimcore digital asset management component.

### 4. Application Layer (`application.tf`)

The application layer provisions specialized services for:
- Agent development and testing
- Configuration management
- User interface
- Internal API communication

This maps to the **Interface Layer** and **Agent Development** components in the overall architecture.

### 5. Compute Resources

The main compute resources in the Terraform configuration provision the following services:

#### Core Services

##### 371GPT Core (AI Orchestration)
- Hosts the CEO Orchestrator Agent
- Runs specialized sub-agents (Research, Development, Creative, Operations)
- Manages the agent communication framework
- Specifications: s1-8 instance (8 vCPUs, 16GB RAM)

##### XPipe Server (Data Pipelines)
- Handles knowledge ingestion from various sources
- Processes and transforms data for agent consumption
- Synchronizes data between business systems
- Specifications: s1-4 instance (4 vCPUs, 8GB RAM)

##### Kespa Service (Automation)
- Provides workflow automation for common tasks
- Handles scheduled operations and maintenance
- Manages resource optimization
- Specifications: s1-4 instance (4 vCPUs, 8GB RAM)

#### Application Services

##### FastAPI Gateway
- Provides internal API for agent communication
- Handles request routing between agents
- Manages authentication and logging
- Specifications: s1-4 instance (4 vCPUs, 8GB RAM)

##### Agenta Development Environment
- Supports agent creation and testing
- Provides evaluation frameworks
- Stores agent templates and versions
- Specifications: s1-8 instance (8 vCPUs, 16GB RAM) with 100GB storage

##### NocoDB
- Manages configuration through no-code interface
- Stores agent parameters and settings
- Provides user-friendly database access
- Specifications: s1-4 instance (4 vCPUs, 8GB RAM) with 50GB storage

##### NiceGUI Admin Interface
- Provides web-based administration dashboard
- Visualizes system performance and logs
- Offers no-code configuration tools
- Specifications: s1-4 instance (4 vCPUs, 8GB RAM)

## Terraform Implementation Details

### Infrastructure as Code Principles

The Terraform configuration follows these principles:
- **Modularity**: Separating concerns by resource type
- **Variables**: Using variables for customization
- **Outputs**: Providing clear access information
- **Security**: Implementing least privilege access

### Resource Management Strategy

1. **Provisioning**: Resources are created in a specific order to ensure dependencies are met
2. **Configuration**: Each resource is configured with appropriate settings
3. **Connection**: Network relationships between resources are established
4. **Security**: Access controls are applied to all resources

## Integration Points

### Connecting to Business Applications

The infrastructure provisions resources that will connect to:
- **Odoo**: For business operations (CRM, project management, invoicing)
- **Pimcore**: For digital asset management and customer experience

The connection points are defined in the network and security configurations.

### API Integration

#### Internal API Gateway (FastAPI)
The FastAPI Gateway provides a unified internal API for agent communication, featuring:
- Standardized request/response formats
- Authentication and authorization
- Request logging and monitoring
- Load balancing between agent instances

#### External API Integration
While RapidAPI is used in the overall architecture for external API monetization, the Terraform infrastructure focuses on the core systems. The RapidAPI integration occurs at the application level, not the infrastructure level.

## Communication Flow

The infrastructure supports this communication flow:
1. **User Request**: Enters through NiceGUI admin interface
2. **API Gateway**: Routes request to appropriate service
3. **Orchestrator Agent**: Plans and delegates tasks
4. **Specialized Agents**: Execute tasks as directed
5. **Data Storage**: Persists state in Supabase
6. **External Integration**: Connects with business systems

## Scaling Considerations

The infrastructure is designed to support scaling in several ways:
- **Horizontal Scaling**: Adding more instances of each service
- **Vertical Scaling**: Upgrading instance types for more power
- **Storage Expansion**: Increasing storage capacity as needed
- **Load Balancing**: Adding load balancers for high-traffic components

## Deployment Phases

The infrastructure deployment aligns with the overall project phases:

### Phase 1: Foundation
- Deploy core network infrastructure
- Provision database and storage resources
- Set up basic security configurations
- Deploy FastAPI Gateway and NiceGUI admin

### Phase 2: Integration
- Connect all services via internal network
- Set up Agenta for agent development
- Configure NocoDB for system settings
- Establish secure external access points
- Configure backups and monitoring

### Phase 3: Expansion
- Scale resources based on performance metrics
- Add specialized instances for industry-specific needs
- Implement advanced security features
- Deploy high availability configurations

## Security Architecture

Security is implemented at multiple levels:
- **Network Security**: Firewalls, security groups, private networks
- **Access Control**: IAM policies, role-based access
- **Data Protection**: Encryption at rest and in transit
- **Monitoring**: Audit logs, intrusion detection
- **API Security**: Token-based authentication, request validation

## Maintenance and Operations

The Terraform configuration supports:
- **Updates**: Easy infrastructure updates with minimal downtime
- **Backups**: Automated backup procedures
- **Monitoring**: Integrated with monitoring systems
- **Disaster Recovery**: Ability to recreate infrastructure from code 