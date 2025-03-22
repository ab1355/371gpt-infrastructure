# OVH API Credential Verification Script
# This script validates that OVH API credentials are properly configured

param (
    [string]$ConfigFile = "terraform.tfvars"
)

# Functions for colorized output
function Write-Success {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Error {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Write-Warning {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Info {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Separator {
    Write-Host ("-" * 80) -ForegroundColor Gray
}

# Check if config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Config file '$ConfigFile' not found. Please create this file with your credentials."
    exit 1
}

Write-Info "Reading credentials from $ConfigFile..."

# Read credentials from terraform.tfvars
try {
    $configContent = Get-Content $ConfigFile -Raw

    # Extract credentials using regex
    $ovhAppKey = if ($configContent -match 'ovh_application_key\s*=\s*"([^"]*)"') { $matches[1] } else { "" }
    $ovhAppSecret = if ($configContent -match 'ovh_application_secret\s*=\s*"([^"]*)"') { $matches[1] } else { "" }
    $ovhConsumerKey = if ($configContent -match 'ovh_consumer_key\s*=\s*"([^"]*)"') { $matches[1] } else { "" }
    
    $osTenantId = if ($configContent -match 'os_tenant_id\s*=\s*"([^"]*)"') { $matches[1] } else { "" }
    $osTenantName = if ($configContent -match 'os_tenant_name\s*=\s*"([^"]*)"') { $matches[1] } else { "" }
    $osUsername = if ($configContent -match 'os_username\s*=\s*"([^"]*)"') { $matches[1] } else { "" }
    $osPassword = if ($configContent -match 'os_password\s*=\s*"([^"]*)"') { $matches[1] } else { "" }
    $osRegionName = if ($configContent -match 'os_region_name\s*=\s*"([^"]*)"') { $matches[1] } else { "" }

    # Display credentials (first few characters only for security)
    Write-Info "Found OVH Application Key: $($ovhAppKey.Substring(0, [Math]::Min(4, $ovhAppKey.Length)))..."
    Write-Info "Found OVH Application Secret: $($ovhAppSecret.Substring(0, [Math]::Min(4, $ovhAppSecret.Length)))..."
    Write-Info "Found OVH Consumer Key: $($ovhConsumerKey.Substring(0, [Math]::Min(4, $ovhConsumerKey.Length)))..."
    
    Write-Info "Found OpenStack Tenant ID: $osTenantId"
    Write-Info "Found OpenStack Tenant Name: $osTenantName"
    Write-Info "Found OpenStack Username: $osUsername"
    Write-Info "Found OpenStack Password: $($osPassword.Substring(0, [Math]::Min(4, $osPassword.Length)))..."
    Write-Info "Found OpenStack Region: $osRegionName"
    
    # Check if any credentials are missing
    $missingCredentials = @()
    if ([string]::IsNullOrWhiteSpace($ovhAppKey)) { $missingCredentials += "OVH Application Key" }
    if ([string]::IsNullOrWhiteSpace($ovhAppSecret)) { $missingCredentials += "OVH Application Secret" }
    if ([string]::IsNullOrWhiteSpace($ovhConsumerKey)) { $missingCredentials += "OVH Consumer Key" }
    if ([string]::IsNullOrWhiteSpace($osTenantId)) { $missingCredentials += "OpenStack Tenant ID" }
    if ([string]::IsNullOrWhiteSpace($osTenantName)) { $missingCredentials += "OpenStack Tenant Name" }
    if ([string]::IsNullOrWhiteSpace($osUsername)) { $missingCredentials += "OpenStack Username" }
    if ([string]::IsNullOrWhiteSpace($osPassword)) { $missingCredentials += "OpenStack Password" }
    if ([string]::IsNullOrWhiteSpace($osRegionName)) { $missingCredentials += "OpenStack Region" }
    
    if ($missingCredentials.Count -gt 0) {
        Write-Warning "Missing credentials:"
        foreach ($cred in $missingCredentials) {
            Write-Warning "  - $cred"
        }
        
        if ($missingCredentials.Count -ge 3) {
            Write-Error "Too many missing credentials. Please update your $ConfigFile file."
            exit 1
        }
    }
    
    # Create OpenStack RC file
    $openrcContent = @"
#!/bin/bash
export OS_AUTH_URL=https://auth.cloud.ovh.us/v3
export OS_IDENTITY_API_VERSION=3
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_NAME="Default"
export OS_TENANT_ID="$osTenantId"
export OS_TENANT_NAME="$osTenantName"
export OS_USERNAME="$osUsername"
export OS_PASSWORD="$osPassword"
export OS_REGION_NAME="$osRegionName"
"@

    $openrcContent | Out-File -FilePath "openrc.sh" -Encoding utf8
    Write-Success "Created OpenStack RC file: openrc.sh"
    
} catch {
    Write-Error "Error reading credentials from $ConfigFile: $_"
    exit 1
}

Write-Separator
Write-Info "Verifying OVH API credentials..."

# Try a direct API ping first to check connectivity 
try {
    $apiUrl = "https://api.us.ovhcloud.com/1.0/auth/time"
    $response = Invoke-WebRequest -Uri $apiUrl -Method Get -UseBasicParsing
    
    if ($response.StatusCode -eq 200) {
        Write-Success "OVH API direct connection successful. Server time: $($response.Content)"
    } else {
        Write-Warning "OVH API connection returned status code: $($response.StatusCode)"
    }
} catch {
    Write-Warning "OVH API direct connection failed: $_"
    Write-Warning "This may indicate network issues or incorrect endpoint."
}

# Try an authenticated API call to verify credentials
try {
    $timestamp = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-UFormat "%s"))
    $url = "https://api.us.ovhcloud.com/1.0/auth/credential"
    
    $headers = @{
        "X-Ovh-Application" = $ovhAppKey
        "Content-Type" = "application/json"
    }
    
    $body = @{
        "accessRules" = @(
            @{
                "method" = "GET"
                "path" = "/*"
            }
        )
        "redirection" = "https://api.us.ovhcloud.com/success"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Body $body -UseBasicParsing
    
    if ($response.StatusCode -eq 200) {
        Write-Success "OVH API credentials are valid."
        $validation = ConvertFrom-Json $response.Content
        Write-Success "Validation URL: $($validation.validationUrl)"
        Write-Success "Consumer Key: $($validation.consumerKey)"
        exit 0
    } else {
        Write-Error "OVH API credential verification failed with status code: $($response.StatusCode)"
        Write-Error "Response: $($response.Content)"
        exit 1
    }
} catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { "Unknown" }
    Write-Error "OVH API verification failed: Status Code $statusCode"
    Write-Error "Error details: $_"
    
    Write-Separator
    Write-Warning "OVH API credentials are invalid."
    Write-Info "To obtain new API credentials:"
    Write-Info "1. Visit https://api.us.ovhcloud.com/createToken/"
    Write-Info "2. Fill in your application name and description"
    Write-Info "3. Add the following access rules:"
    Write-Info "   - GET /*"
    Write-Info "   - POST /*"
    Write-Info "   - PUT /*"
    Write-Info "   - DELETE /*"
    Write-Info "4. Update your terraform.tfvars file with the new credentials"
    Write-Separator
    
    exit 1
}