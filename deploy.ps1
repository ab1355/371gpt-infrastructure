# Deployment script for 371GPT infrastructure on Windows
# Requires PowerShell 7.0 or later

# Stop on any error
$ErrorActionPreference = "Stop"

# Function to check if a command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Verify prerequisites
$prerequisites = @{
    "terraform" = "Terraform"
    "git" = "Git"
}

foreach ($cmd in $prerequisites.Keys) {
    if (-not (Test-Command -cmdname $cmd)) {
        Write-Error "Required tool $($prerequisites[$cmd]) is not installed. Please run setup-terraform.ps1 first."
        exit 1
    }
}

# Function to handle errors
function Handle-Error {
    param($ErrorMessage)
    Write-Error $ErrorMessage
    exit 1
}

# Ensure we're in the right directory
try {
    if (-not (Test-Path -Path "terraform.tfvars")) {
        Handle-Error "terraform.tfvars not found. Please run this script from the project root directory."
    }
} catch {
    Handle-Error "Error checking for terraform.tfvars: $_"
}

# Initialize Terraform if needed
Write-Host "Initializing Terraform..."
try {
    terraform init
} catch {
    Handle-Error "Failed to initialize Terraform: $_"
}

# Plan the deployment
Write-Host "Planning Terraform deployment..."
try {
    terraform plan -out tfplan
} catch {
    Handle-Error "Failed to create Terraform plan: $_"
}

# Confirm deployment
$confirmation = Read-Host "Do you want to proceed with the deployment? (y/N)"
if ($confirmation -ne "y") {
    Write-Host "Deployment cancelled."
    exit 0
}

# Apply the Terraform configuration
Write-Host "Applying Terraform configuration..."
try {
    terraform apply "tfplan"
} catch {
    Handle-Error "Failed to apply Terraform configuration: $_"
}

# Get outputs
Write-Host "Retrieving deployment information..."
try {
    $outputs = terraform output -json | ConvertFrom-Json
    
    # Store outputs in environment variables
    foreach ($output in $outputs.PSObject.Properties) {
        $value = $output.Value.value
        [Environment]::SetEnvironmentVariable($output.Name, $value, "Process")
        Write-Host "Set $($output.Name) = $value"
    }
} catch {
    Write-Warning "Failed to process Terraform outputs: $_"
}

# Run post-deployment tasks
Write-Host "Running post-deployment tasks..."

# Check if agents need to be configured
if (Test-Path -Path "agents-setup.yml") {
    Write-Host "Configuring agents..."
    try {
        # Add agent configuration steps here
        # This might include setting up SSH keys, installing dependencies, etc.
    } catch {
        Write-Warning "Failed to configure agents: $_"
    }
}

Write-Host "Deployment completed successfully!"
Write-Host "Next steps:"
Write-Host "1. Verify the infrastructure is running correctly"
Write-Host "2. Configure your application settings"
Write-Host "3. Set up monitoring and alerts"

# Display cleanup instructions
Write-Host "`nTo clean up the infrastructure, run:"
Write-Host "terraform destroy"