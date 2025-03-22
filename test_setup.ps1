# 371GPT Infrastructure Test Script
# This script tests if the deployment environment is correctly configured
param(
    [switch]$SkipSystemTests,
    [switch]$SkipFileTests,
    [switch]$SkipNetworkTests,
    [switch]$Verbose
)

# Variables
$ErrorActionPreference = "Stop"
$logFile = "test_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$passedTests = 0
$failedTests = 0
$skippedTests = 0

# Function to log messages
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TEST")]
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
        "TEST" { $color = "Cyan" }
        default { $color = "White" }
    }
    
    # Output to console
    Write-Host $logMessage -ForegroundColor $color
    
    # Append to log file
    Add-Content -Path $logFile -Value $logMessage
}

# Function to display test header
function Write-TestHeader {
    param(
        [string]$TestName
    )
    
    Write-Log "-----------------------------------------------" "TEST"
    Write-Log "Testing: $TestName" "TEST"
    Write-Log "-----------------------------------------------" "TEST"
}

# Function to run a test and record result
function Test-Requirement {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$Test,
        
        [Parameter(Mandatory=$false)]
        [string]$SuccessMessage = "Test passed",
        
        [Parameter(Mandatory=$false)]
        [string]$FailureMessage = "Test failed",
        
        [Parameter(Mandatory=$false)]
        [string]$SkippedMessage = "Test skipped",
        
        [Parameter(Mandatory=$false)]
        [switch]$Skip,
        
        [Parameter(Mandatory=$false)]
        [string]$HintOnFailure = ""
    )
    
    if ($Skip) {
        Write-Log "SKIPPED: $Name - $SkippedMessage" "WARNING"
        $script:skippedTests++
        return $null
    }
    
    try {
        $result = & $Test
        
        if ($result -eq $true) {
            Write-Log "PASSED: $Name - $SuccessMessage" "SUCCESS"
            $script:passedTests++
            return $true
        } else {
            Write-Log "FAILED: $Name - $FailureMessage" "ERROR"
            if ($HintOnFailure) {
                Write-Log "HINT: $HintOnFailure" "WARNING"
            }
            $script:failedTests++
            return $false
        }
    } catch {
        Write-Log "ERROR: $Name - Exception: $_" "ERROR"
        if ($HintOnFailure) {
            Write-Log "HINT: $HintOnFailure" "WARNING"
        }
        $script:failedTests++
        return $false
    }
}

# Initialize test log
Write-Log "Starting 371GPT infrastructure environment tests" "INFO"
Write-Log "Log file: $logFile" "INFO"

# System Requirements Tests
Write-TestHeader "System Requirements"

# PowerShell Version
Test-Requirement -Name "PowerShell Version" -Skip:$SkipSystemTests -Test {
    $version = $PSVersionTable.PSVersion
    Write-Log "PowerShell Version: $version" "INFO"
    $version.Major -ge 7
} -SuccessMessage "PowerShell version is 7.0 or higher" `
  -FailureMessage "PowerShell version is below 7.0" `
  -HintOnFailure "Please upgrade PowerShell to version 7.0 or higher: https://github.com/PowerShell/PowerShell"

# Terraform Installation
Test-Requirement -Name "Terraform Installation" -Skip:$SkipSystemTests -Test {
    try {
        $tfVersion = terraform --version
        Write-Log "Terraform Version: $($tfVersion -split "`n" | Select-Object -First 1)" "INFO"
        $true
    } catch {
        Write-Log "Terraform not found: $_" "ERROR"
        $false
    }
} -SuccessMessage "Terraform is installed" `
  -FailureMessage "Terraform is not installed or not in PATH" `
  -HintOnFailure "Please install Terraform: https://www.terraform.io/downloads.html"

# File Requirements Tests
Write-TestHeader "File Requirements"

# terraform.tfvars exists
Test-Requirement -Name "terraform.tfvars exists" -Skip:$SkipFileTests -Test {
    Test-Path -Path "terraform.tfvars"
} -SuccessMessage "terraform.tfvars file exists" `
  -FailureMessage "terraform.tfvars file not found" `
  -HintOnFailure "Run ./setup.ps1 to create terraform.tfvars or create it manually"

# main.tf exists
Test-Requirement -Name "main.tf exists" -Skip:$SkipFileTests -Test {
    Test-Path -Path "main.tf"
} -SuccessMessage "main.tf file exists" `
  -FailureMessage "main.tf file not found" `
  -HintOnFailure "This file should be part of the repository. Please check your repository clone."

# variables.tf exists
Test-Requirement -Name "variables.tf exists" -Skip:$SkipFileTests -Test {
    Test-Path -Path "variables.tf"
} -SuccessMessage "variables.tf file exists" `
  -FailureMessage "variables.tf file not found" `
  -HintOnFailure "This file should be part of the repository. Please check your repository clone."

# network.tf exists
Test-Requirement -Name "network.tf exists" -Skip:$SkipFileTests -Test {
    Test-Path -Path "network.tf"
} -SuccessMessage "network.tf file exists" `
  -FailureMessage "network.tf file not found" `
  -HintOnFailure "This file should be part of the repository. Please check your repository clone."

# Required credentials in terraform.tfvars
Test-Requirement -Name "Required credentials in terraform.tfvars" -Skip:$SkipFileTests -Test {
    if (-not (Test-Path -Path "terraform.tfvars")) {
        return $false
    }
    
    $content = Get-Content -Path "terraform.tfvars" -Raw
    $requiredVars = @(
        "ovh_application_key",
        "ovh_application_secret",
        "ovh_consumer_key",
        "os_tenant_id",
        "os_tenant_name",
        "os_username",
        "os_password",
        "os_region_name"
    )
    
    $missingVars = @()
    foreach ($var in $requiredVars) {
        if ($content -notmatch $var) {
            $missingVars += $var
        }
    }
    
    if ($missingVars.Count -gt 0) {
        Write-Log "Missing variables: $($missingVars -join ', ')" "ERROR"
        return $false
    }
    
    $true
} -SuccessMessage "All required credentials exist in terraform.tfvars" `
  -FailureMessage "Some required credentials are missing in terraform.tfvars" `
  -HintOnFailure "Update your terraform.tfvars file with all required credentials"

# Network Connectivity Tests
Write-TestHeader "Network Connectivity"

# OVH API Connectivity
Test-Requirement -Name "OVH API Connectivity" -Skip:$SkipNetworkTests -Test {
    try {
        $response = Invoke-WebRequest -Uri "https://api.us.ovhcloud.com/1.0/auth/time" -UseBasicParsing
        Write-Log "OVH API Response Code: $($response.StatusCode)" "INFO"
        $response.StatusCode -eq 200
    } catch {
        Write-Log "OVH API Connection Failed: $_" "ERROR"
        $false
    }
} -SuccessMessage "OVH API is reachable" `
  -FailureMessage "Cannot connect to OVH API" `
  -HintOnFailure "Check your internet connection and firewall settings"

# OpenStack API Connectivity
Test-Requirement -Name "OpenStack API Connectivity" -Skip:$SkipNetworkTests -Test {
    try {
        $response = Invoke-WebRequest -Uri "https://auth.cloud.ovh.us/v3" -UseBasicParsing
        Write-Log "OpenStack API Response Code: $($response.StatusCode)" "INFO"
        $response.StatusCode -eq 200
    } catch {
        Write-Log "OpenStack API Connection Failed: $_" "ERROR"
        $false
    }
} -SuccessMessage "OpenStack API is reachable" `
  -FailureMessage "Cannot connect to OpenStack API" `
  -HintOnFailure "Check your internet connection and firewall settings"

# verify_ovh.ps1 script test
Test-Requirement -Name "verify_ovh.ps1 script test" -Skip:$SkipNetworkTests -Test {
    if (-not (Test-Path -Path "verify_ovh.ps1")) {
        Write-Log "verify_ovh.ps1 script not found" "ERROR"
        return $false
    }
    
    try {
        & ".\verify_ovh.ps1" -ErrorAction SilentlyContinue
        # We don't really care about the exit code here, just that it runs without throwing
        $true
    } catch {
        Write-Log "Error running verify_ovh.ps1: $_" "ERROR"
        $false
    }
} -SuccessMessage "verify_ovh.ps1 script runs without fatal errors" `
  -FailureMessage "verify_ovh.ps1 script fails to run" `
  -HintOnFailure "Ensure verify_ovh.ps1 has the correct permissions and is properly formatted"

# Summary
Write-TestHeader "Test Results Summary"
Write-Log "Tests Passed: $passedTests" "$($passedTests -gt 0 ? 'SUCCESS' : 'INFO')"
Write-Log "Tests Failed: $failedTests" "$($failedTests -gt 0 ? 'ERROR' : 'INFO')"
Write-Log "Tests Skipped: $skippedTests" "$($skippedTests -gt 0 ? 'WARNING' : 'INFO')"
Write-Log "Total Tests: $($passedTests + $failedTests + $skippedTests)" "INFO"

# Final assessment
if ($failedTests -eq 0) {
    if ($skippedTests -gt 0) {
        Write-Log "PARTIAL SUCCESS: All executed tests passed, but some tests were skipped" "WARNING"
    } else {
        Write-Log "SUCCESS: All tests passed! Your environment is ready for deployment." "SUCCESS"
    }
    Write-Log "You can now proceed with deploying the infrastructure using ./deploy.ps1" "SUCCESS"
    exit 0
} else {
    Write-Log "FAILURE: Some tests failed. Please fix the issues before proceeding with deployment." "ERROR"
    Write-Log "Review the log file for more details: $logFile" "ERROR"
    exit 1
}