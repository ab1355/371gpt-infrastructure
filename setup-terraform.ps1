# Setup script for Terraform on Windows
# Requires PowerShell 7.0 or later

# Ensure running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator. Please restart PowerShell as Administrator."
    exit 1
}

# Function to check if a command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Install Chocolatey if not present
if (-not (Test-Command -cmdname 'choco')) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    refreshenv
}

# Install Terraform if not present
if (-not (Test-Command -cmdname 'terraform')) {
    Write-Host "Installing Terraform..."
    choco install terraform -y
    refreshenv
}

# Verify Terraform installation
$terraformVersion = terraform --version
Write-Host "Terraform version: $terraformVersion"

# Initialize Terraform
Write-Host "Initializing Terraform..."
terraform init

# Create terraform.tfvars if it doesn't exist
if (-not (Test-Path -Path "terraform.tfvars")) {
    Write-Host "Creating terraform.tfvars from example..."
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    Write-Host "Please edit terraform.tfvars with your credentials and configuration."
}

# Set up environment variables if needed
$envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if (-not $envPath.Contains("terraform")) {
    Write-Host "Adding Terraform to system PATH..."
    $terraformPath = (Get-Command terraform).Source | Split-Path -Parent
    [Environment]::SetEnvironmentVariable("Path", "$envPath;$terraformPath", "Machine")
    refreshenv
}

Write-Host "Setup complete! You can now use Terraform to manage your infrastructure."
Write-Host "Next steps:"
Write-Host "1. Edit terraform.tfvars with your credentials"
Write-Host "2. Run 'terraform plan' to review changes"
Write-Host "3. Run 'terraform apply' to deploy"