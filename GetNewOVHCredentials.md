# How to Obtain New OVH API Credentials

This guide will walk you through the process of obtaining new OVH API credentials for your US account. These credentials are required for the 371GPT Terraform deployment.

## Why You Need New Credentials

You may need to create new API credentials if:

1. Your current credentials are invalid or expired
2. You're setting up the 371GPT infrastructure for the first time
3. You've received authentication errors when running Terraform commands
4. You're rotating credentials for security purposes

## Step-by-Step Guide

### 1. Log into the OVH US Control Panel

Visit [OVH US Control Panel](https://www.ovhcloud.com/en/public-cloud/) and log in with your account credentials.

### 2. Navigate to API Keys Management

Once logged in:

1. Click on your username in the top-right corner
2. Select "API Keys" from the dropdown menu
   - If you don't see this option, you may need to navigate to: Account Management → API Keys

### 3. Create New API Keys

On the API Keys management page:

1. Click on the "Create API Key" button
2. Fill in the required information:
   - **Account ID**: Your OVH account ID (should be pre-filled)
   - **Name**: "371GPT Infrastructure Deployment" (or your preferred name)
   - **Description**: "API credentials for Terraform deployment of 371GPT infrastructure"
   - **Validity**: Choose "Unlimited" unless you prefer a specific expiration

### 4. Define Rights/Permissions

For the 371GPT infrastructure deployment, you need the following permissions:

1. For **all** of these services, select "GET", "POST", "PUT", and "DELETE" methods:
   - `/cloud/*` (Cloud resources)
   - `/ip/*` (IP management)
   - `/vps/*` (If using VPS resources)
   - `/dedicated/*` (If using dedicated servers)

2. Alternatively, for full access (simplest option), select:
   - `/*` with all methods (GET, POST, PUT, DELETE)

> **Note**: For production environments, it's a best practice to limit permissions to only what's necessary, but for development and testing, full access is often simpler.

### 5. Create Keys

1. Click "Create Keys"
2. On the confirmation screen, you'll be provided with:
   - **Application Key**
   - **Application Secret**
   - **Consumer Key**

> **IMPORTANT**: Copy all three keys immediately and store them securely. The Application Secret and Consumer Key will NOT be displayed again after you leave this page.

### 6. Update Your terraform.tfvars File

Open your `terraform.tfvars` file in a text editor and update the following lines:

```hcl
# OVH API Credentials
ovh_application_key    = "your_new_application_key"
ovh_application_secret = "your_new_application_secret"
ovh_consumer_key       = "your_new_consumer_key"
```

Replace the placeholder values with your actual credentials.

## Verifying Your New Credentials

After updating your `terraform.tfvars` file:

1. Run the verification script:
   ```powershell
   .\verify_ovh.ps1
   ```

2. If successful, you'll see a message confirming that your OVH API credentials are valid.

3. If you encounter errors, double-check:
   - That you've copied the credentials correctly
   - That the credentials are for the US endpoint (api.us.ovhcloud.com)
   - That you've granted sufficient permissions

## Troubleshooting

### Common Issues

#### "Invalid credential" error

This typically means that one or more of your credentials is incorrect. Double-check the values in `terraform.tfvars` against what was provided when you created the API keys.

#### "Invalid signature" error

This could indicate a timestamp synchronization issue between your system and the OVH API servers. Ensure your system clock is accurate.

#### "Access denied" error

This means your credentials are valid, but you don't have permission to access the requested resource. Review the permissions you granted when creating the API keys.

### Getting Help

If you continue to experience issues:

1. Consult the [OVH API Documentation](https://api.us.ovhcloud.com/console/)
2. Contact [OVH Support](https://www.ovhcloud.com/en/support/) for assistance with API-related issues

## Security Best Practices

1. Never share your API credentials
2. Don't commit your `terraform.tfvars` file to version control
3. Consider using environment variables instead of storing credentials in files
4. Rotate your credentials periodically, especially for production environments
5. Use the minimum permissions necessary for the tasks you need to perform

## Next Steps

After successfully updating your OVH API credentials:

1. Run `terraform init` to initialize Terraform with your new credentials
2. Create a plan using `terraform plan -out=tfplan`
3. Apply the plan with `terraform apply tfplan`