# 371GPT Infrastructure Setup Script
# This script prepares the environment for deploying the 371GPT infrastructure
param(
    [switch]$Force,
    [switch]$SkipTerraformCheck,
    [switch]$SkipCredentialCheck,
    [switch]$Verbose
)

# Variables
$ErrorActionPreference = "Stop"
$logFile = "setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Function to log messages
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Set console color based on level
    switch ($Level) {
        "INFO" { $color = "White" }
        "WARNING" { $color = "Yellow" }
        "ERROR" { $color = "Red" }
        "SUCCESS" { $color = "Green" }
        default { $color = "White" }
    }
    
    # Output to console
    Write-Host $logMessage -ForegroundColor $color
    
    # Append to log file
    Add-Content -Path $logFile -Value $logMessage
}

# Function to check if Terraform is installed
function Test-TerraformInstalled {
    if ($SkipTerraformCheck) {
        Write-Log "Skipping Terraform installation check" "WARNING"
        return $true
    }
    
    try {
        $tfVersion = terraform --version
        Write-Log "Terraform is installed: $($tfVersion -split "`n" | Select-Object -First 1)" "SUCCESS"
        return $true
    } catch {
        Write-Log "Terraform is not installed or not in PATH" "ERROR"
        
        $installTerraform = Read-Host "Would you like to install Terraform now? (y/n)"
        if ($installTerraform -eq "y") {
            try {
                Write-Log "Attempting to install Terraform using winget..." "INFO"
                winget install -e --id Hashicorp.Terraform
                
                # Refresh environment variables
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                
                # Check if installation was successful
                $tfVersion = terraform --version
                Write-Log "Terraform installed successfully: $($tfVersion -split "`n" | Select-Object -First 1)" "SUCCESS"
                return $true
            } catch {
                Write-Log "Failed to install Terraform automatically. Please install it manually: https://www.terraform.io/downloads.html" "ERROR"
                return $false
            }
        } else {
            Write-Log "Terraform installation skipped. Please install manually before continuing." "WARNING"
            return $false
        }
    }
}

# Function to check if terraform.tfvars exists
function Test-TerraformVarsFile {
    if (Test-Path -Path "terraform.tfvars") {
        Write-Log "terraform.tfvars file exists" "SUCCESS"
        return $true
    } else {
        if (Test-Path -Path "terraform.tfvars.example") {
            Write-Log "terraform.tfvars file not found, but example file exists" "WARNING"
            
            $createFromExample = Read-Host "Would you like to create terraform.tfvars from the example file? (y/n)"
            if ($createFromExample -eq "y") {
                try {
                    Copy-Item -Path "terraform.tfvars.example" -Destination "terraform.tfvars"
                    Write-Log "Created terraform.tfvars from example file" "SUCCESS"
                    Write-Log "Please edit terraform.tfvars to include your actual credentials" "WARNING"
                    return $true
                } catch {
                    Write-Log "Failed to create terraform.tfvars: $_" "ERROR"
                    return $false
                }
            } else {
                Write-Log "terraform.tfvars creation skipped. Please create it manually." "WARNING"
                return $false
            }
        } else {
            Write-Log "terraform.tfvars and example file not found" "ERROR"
            
            $createEmpty = Read-Host "Would you like to create an empty terraform.tfvars file? (y/n)"
            if ($createEmpty -eq "y") {
                try {
                    @"
# OVH API Credentials
ovh_application_key    = ""
ovh_application_secret = ""
ovh_consumer_key       = ""

# OpenStack Credentials
os_tenant_id   = ""
os_tenant_name = ""
os_username    = ""
os_password    = ""
os_region_name = "US-EAST-VA"

# SSH Key
ssh_key_pair = ""

# Agent Configuration
agent_image           = "Ubuntu 20.04"
ceo_agent_flavor      = "s1-8"
standard_agent_flavor = "s1-4"

# Storage Volumes
ceo_agent_volume_size      = 100
research_agent_volume_size = 50
dev_agent_volume_size      = 50
comm_agent_volume_size     = 50
security_agent_volume_size = 50
agent_volume_type          = "classic"

# Logging level for agents
agent_logging_level = "INFO"
"@ | Out-File -FilePath "terraform.tfvars" -Encoding utf8
                    
                    Write-Log "Created empty terraform.tfvars file" "SUCCESS"
                    Write-Log "Please edit terraform.tfvars to include your actual credentials" "WARNING"
                    return $true
                } catch {
                    Write-Log "Failed to create terraform.tfvars: $_" "ERROR"
                    return $false
                }
            } else {
                Write-Log "terraform.tfvars creation skipped. Please create it manually." "WARNING"
                return $false
            }
        }
    }
}

# Function to check required variables in terraform.tfvars
function Test-TerraformVarsContent {
    if (-not (Test-Path -Path "terraform.tfvars")) {
        Write-Log "terraform.tfvars file not found, cannot check content" "ERROR"
        return $false
    }
    
    try {
        $varsContent = Get-Content -Path "terraform.tfvars" -Raw
        
        $requiredVars = @(
            "ovh_application_key",
            "ovh_application_secret",
            "ovh_consumer_key",
            "os_tenant_id",
            "os_tenant_name",
            "os_username",
            "os_password",
            "os_region_name",
            "ssh_key_pair"
        )
        
        $missingVars = @()
        $emptyVars = @()
        
        foreach ($var in $requiredVars) {
            if ($varsContent -notmatch $var) {
                $missingVars += $var
            } elseif ($varsContent -match "$var\s*=\s*`"?`"") {
                $emptyVars += $var
            }
        }
        
        if ($missingVars.Count -gt 0) {
            Write-Log "Missing required variables in terraform.tfvars:" "ERROR"
            $missingVars | ForEach-Object { Write-Log "  - $_" "ERROR" }
            return $false
        }
        
        if ($emptyVars.Count -gt 0) {
            Write-Log "The following variables are empty in terraform.tfvars:" "WARNING"
            $emptyVars | ForEach-Object { Write-Log "  - $_" "WARNING" }
            
            $continueWithEmpty = Read-Host "Continue with empty variables? (y/n)"
            if ($continueWithEmpty -ne "y" -and -not $Force) {
                Write-Log "Setup cancelled. Please fill in the empty variables in terraform.tfvars" "ERROR"
                return $false
            }
            
            Write-Log "Continuing with empty variables" "WARNING"
        } else {
            Write-Log "All required variables are present in terraform.tfvars" "SUCCESS"
        }
        
        return $true
    } catch {
        Write-Log "Error reading terraform.tfvars: $_" "ERROR"
        return $false
    }
}

# Function to check OVH and OpenStack credentials
function Test-Credentials {
    if ($SkipCredentialCheck) {
        Write-Log "Skipping credential check" "WARNING"
        return $true
    }
    
    if (-not (Test-Path -Path "verify_ovh.ps1")) {
        Write-Log "Verification script (verify_ovh.ps1) not found" "WARNING"
        
        if ($Force) {
            Write-Log "Continuing without credential verification due to -Force flag" "WARNING"
            return $true
        }
        
        $skipVerification = Read-Host "Skip credential verification? (y/n)"
        if ($skipVerification -eq "y") {
            Write-Log "Credential verification skipped" "WARNING"
            return $true
        } else {
            Write-Log "Cannot proceed without credential verification" "ERROR"
            return $false
        }
    }
    
    try {
        Write-Log "Verifying OVH and OpenStack credentials..." "INFO"
        $output = & ".\verify_ovh.ps1" 2>&1
        $output | ForEach-Object { Write-Log $_ "INFO" }
        
        if ($LASTEXITCODE -eq 0 -or $Force) {
            Write-Log "Credential verification completed successfully or force flag used" "SUCCESS"
            return $true
        } else {
            Write-Log "Credential verification failed" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error during credential verification: $_" "ERROR"
        
        if ($Force) {
            Write-Log "Continuing despite verification error due to -Force flag" "WARNING"
            return $true
        }
        
        return $false
    }
}

# Function to initialize Terraform
function Initialize-Terraform {
    Write-Log "Initializing Terraform..." "INFO"
    
    try {
        $output = terraform init 2>&1
        $output | ForEach-Object { Write-Log $_ "INFO" }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform initialized successfully" "SUCCESS"
            return $true
        } else {
            Write-Log "Terraform initialization failed" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error during Terraform initialization: $_" "ERROR"
        return $false
    }
}

# Main setup process
Write-Log "Starting 371GPT infrastructure setup" "INFO"
Write-Log "Log file: $logFile" "INFO"

# Check Terraform installation
if (-not (Test-TerraformInstalled)) {
    if (-not $Force) {
        Write-Log "Setup cannot continue without Terraform. Use -Force to skip this check." "ERROR"
        exit 1
    }
    Write-Log "Continuing despite Terraform installation issue due to -Force flag" "WARNING"
}

# Check terraform.tfvars file
if (-not (Test-TerraformVarsFile)) {
    if (-not $Force) {
        Write-Log "Setup cannot continue without terraform.tfvars. Use -Force to skip this check." "ERROR"
        exit 1
    }
    Write-Log "Continuing despite terraform.tfvars issue due to -Force flag" "WARNING"
}

# Check required variables
if (-not (Test-TerraformVarsContent)) {
    if (-not $Force) {
        Write-Log "Setup cannot continue with missing or empty variables. Use -Force to skip this check." "ERROR"
        exit 1
    }
    Write-Log "Continuing despite variable issues due to -Force flag" "WARNING"
}

# Verify credentials
if (-not (Test-Credentials)) {
    if (-not $Force) {
        Write-Log "Setup cannot continue with invalid credentials. Use -Force to skip this check." "ERROR"
        exit 1
    }
    Write-Log "Continuing despite credential issues due to -Force flag" "WARNING"
}

# Initialize Terraform
if (-not (Initialize-Terraform)) {
    Write-Log "Setup failed during Terraform initialization" "ERROR"
    exit 1
}

# Setup completed successfully
Write-Log "371GPT infrastructure setup completed successfully" "SUCCESS"
Write-Log "You can now deploy the infrastructure using deploy.ps1" "SUCCESS"

# Display next steps
Write-Log "Next Steps:" "INFO"
Write-Log "1. Review terraform.tfvars to ensure all credentials are correct" "INFO"
Write-Log "2. Run ./deploy.ps1 to deploy the infrastructure" "INFO"
Write-Log "3. After deployment, check the output for IP addresses and connection details" "INFO"