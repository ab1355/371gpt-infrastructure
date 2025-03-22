# 371GPT Infrastructure Deployment Script
# This script handles the complete deployment process for the 371GPT infrastructure
param(
    [switch]$Force,
    [switch]$AutoApprove,
    [switch]$SkipValidation,
    [switch]$Cleanup
)

# Variables
$ErrorActionPreference = "Stop"
$startTime = Get-Date
$logFile = "deployment_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$terraformPlanFile = "tfplan"

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

# Function to check prerequisites
function Test-Prerequisites {
    Write-Log "Checking prerequisites..." "INFO"
    
    # Check if Terraform is installed
    try {
        $tfVersion = terraform --version
        Write-Log "Terraform is installed: $($tfVersion -split "`n" | Select-Object -First 1)" "SUCCESS"
    } catch {
        Write-Log "Terraform is not installed or not in PATH" "ERROR"
        return $false
    }
    
    # Check if terraform.tfvars exists
    if (Test-Path -Path "terraform.tfvars") {
        Write-Log "terraform.tfvars file exists" "SUCCESS"
    } else {
        Write-Log "terraform.tfvars file not found" "ERROR"
        return $false
    }
    
    # Check if main Terraform files exist
    $requiredFiles = @("main.tf", "variables.tf", "network.tf")
    $missingFiles = $requiredFiles | Where-Object { -not (Test-Path $_) }
    
    if ($missingFiles.Count -eq 0) {
        Write-Log "All required Terraform files exist" "SUCCESS"
    } else {
        Write-Log "Some required Terraform files are missing:" "ERROR"
        $missingFiles | ForEach-Object { Write-Log "  - $_" "ERROR" }
        return $false
    }
    
    return $true
}

# Function to validate credentials
function Test-Credentials {
    Write-Log "Validating credentials..." "INFO"
    
    if ($SkipValidation) {
        Write-Log "Credential validation skipped due to -SkipValidation flag" "WARNING"
        return $true
    }
    
    if (Test-Path -Path "verify_ovh.ps1") {
        try {
            $output = & ".\verify_ovh.ps1" 2>&1
            
            # Check for success in the output
            if ($output -match "OVH API credentials are valid" -or $Force) {
                Write-Log "Credentials validated successfully or force flag used" "SUCCESS"
                return $true
            } else {
                Write-Log "Credential validation failed" "ERROR"
                $output | ForEach-Object { Write-Log $_ "INFO" }
                return $false
            }
        } catch {
            Write-Log "Error running validation script: $_" "ERROR"
            return $false
        }
    } else {
        Write-Log "Verification script not found. Cannot validate credentials." "WARNING"
        if ($Force) {
            Write-Log "Proceeding anyway due to -Force flag" "WARNING"
            return $true
        }
        return $false
    }
}

# Function to initialize Terraform
function Initialize-TerraformEnvironment {
    Write-Log "Initializing Terraform environment..." "INFO"
    
    try {
        $output = terraform init -reconfigure 2>&1
        $output | ForEach-Object { Write-Log $_ "INFO" }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform environment initialized successfully" "SUCCESS"
            return $true
        } else {
            Write-Log "Terraform initialization failed with exit code: $LASTEXITCODE" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Exception during Terraform initialization: $_" "ERROR"
        return $false
    }
}

# Function to validate Terraform configuration
function Test-TerraformConfiguration {
    Write-Log "Validating Terraform configuration..." "INFO"
    
    try {
        $output = terraform validate 2>&1
        $output | ForEach-Object { Write-Log $_ "INFO" }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform configuration is valid" "SUCCESS"
            return $true
        } else {
            Write-Log "Terraform configuration is invalid" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Exception during Terraform validation: $_" "ERROR"
        return $false
    }
}

# Function to create Terraform plan
function New-TerraformPlan {
    Write-Log "Creating Terraform plan..." "INFO"
    
    try {
        $output = terraform plan -out="$terraformPlanFile" 2>&1
        $output | ForEach-Object { Write-Log $_ "INFO" }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform plan created successfully" "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to create Terraform plan" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Exception during Terraform plan creation: $_" "ERROR"
        return $false
    }
}

# Function to apply Terraform plan
function Invoke-TerraformApply {
    Write-Log "Applying Terraform plan..." "INFO"
    
    $applyCmd = "terraform apply"
    if ($AutoApprove) {
        $applyCmd += " -auto-approve"
    } else {
        $applyCmd += " `"$terraformPlanFile`""
    }
    
    try {
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command $applyCmd" -NoNewWindow -PassThru -Wait
        
        if ($process.ExitCode -eq 0) {
            Write-Log "Terraform resources applied successfully" "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to apply Terraform resources (Exit code: $($process.ExitCode))" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Exception during Terraform apply: $_" "ERROR"
        return $false
    }
}

# Function to cleanup resources in case of failure
function Remove-Resources {
    if ($Cleanup) {
        Write-Log "Cleaning up deployed resources..." "WARNING"
        
        $destroyCmd = "terraform destroy"
        if ($AutoApprove) {
            $destroyCmd += " -auto-approve"
        }
        
        try {
            $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command $destroyCmd" -NoNewWindow -PassThru -Wait
            
            if ($process.ExitCode -eq 0) {
                Write-Log "Resources cleaned up successfully" "SUCCESS"
            } else {
                Write-Log "Failed to clean up resources (Exit code: $($process.ExitCode))" "ERROR"
            }
        } catch {
            Write-Log "Exception during resource cleanup: $_" "ERROR"
        }
    } else {
        Write-Log "Resource cleanup skipped. Use -Cleanup flag to destroy resources on failure." "INFO"
    }
}

# Function to show deployment summary
function Show-Summary {
    param (
        [bool]$Success
    )
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Log "===============================================" "INFO"
    Write-Log "371GPT Infrastructure Deployment Summary" "INFO"
    Write-Log "===============================================" "INFO"
    Write-Log "Start Time: $startTime" "INFO"
    Write-Log "End Time: $endTime" "INFO"
    Write-Log "Duration: $($duration.ToString('hh\:mm\:ss'))" "INFO"
    
    if ($Success) {
        Write-Log "Deployment Status: SUCCESS" "SUCCESS"
        Write-Log "All infrastructure components deployed successfully" "SUCCESS"
    } else {
        Write-Log "Deployment Status: FAILED" "ERROR"
        Write-Log "Deployment failed. Check the log file for details: $logFile" "ERROR"
    }
    
    Write-Log "===============================================" "INFO"
}

# Main deployment process
Write-Log "Starting 371GPT infrastructure deployment" "INFO"
Write-Log "Log file: $logFile" "INFO"

# Verify prerequisites
if (-not (Test-Prerequisites)) {
    Write-Log "Prerequisite check failed. Deployment cannot continue." "ERROR"
    exit 1
}

# Validate credentials
if (-not (Test-Credentials)) {
    if (-not $Force) {
        Write-Log "Credential validation failed. Use -Force to override." "ERROR"
        exit 1
    }
    Write-Log "Proceeding despite credential validation failure due to -Force flag" "WARNING"
}

# Initialize Terraform
if (-not (Initialize-TerraformEnvironment)) {
    Write-Log "Terraform initialization failed. Deployment cannot continue." "ERROR"
    exit 1
}

# Validate Terraform configuration
if (-not (Test-TerraformConfiguration)) {
    Write-Log "Terraform configuration validation failed. Deployment cannot continue." "ERROR"
    exit 1
}

# Create Terraform plan
if (-not (New-TerraformPlan)) {
    Write-Log "Terraform plan creation failed. Deployment cannot continue." "ERROR"
    exit 1
}

# Apply Terraform plan
$applySuccess = Invoke-TerraformApply

# Handle failure
if (-not $applySuccess) {
    Write-Log "Terraform apply failed." "ERROR"
    Remove-Resources
    Show-Summary -Success $false
    exit 1
}

# Show deployment summary
Show-Summary -Success $true

# Display information about accessing the infrastructure
Write-Log "To access your infrastructure:" "INFO"
Write-Log "1. The IP addresses can be found in the Terraform output above" "INFO"
Write-Log "2. Use the SSH private key corresponding to the public key in terraform.tfvars" "INFO"
Write-Log "3. Connect using: ssh -i <private_key_path> user@<instance_ip>" "INFO"

Write-Log "Deployment completed" "SUCCESS"