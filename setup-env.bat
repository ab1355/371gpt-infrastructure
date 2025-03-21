@echo off
REM Windows equivalent to openrc.sh

REM Set OpenStack environment variables
set OS_AUTH_URL=https://auth.cloud.ovh.us/v3
set OS_IDENTITY_API_VERSION=3
set OS_USER_DOMAIN_NAME=Default
set OS_PROJECT_DOMAIN_NAME=Default
set OS_TENANT_ID=acca8e7f68114f649bddd5c7f85bceb1
set OS_TENANT_NAME=7455318769964354
set OS_USERNAME=user-CjvMvzGGHsd5
set OS_REGION_NAME=US-EAST-VA

REM Set Terraform variables
set TF_VAR_ovh_application_key=RQyaicscFXHbV3HY
set TF_VAR_ovh_application_secret=CJ0eywHJwxhTvsH3rLoDUDXumMOHW10k
set TF_VAR_ovh_consumer_key=Yz64pG4gpSJavzYZHT6S64UtNgg93z5w
set TF_VAR_os_tenant_id=%OS_TENANT_ID%
set TF_VAR_os_tenant_name=%OS_TENANT_NAME%
set TF_VAR_os_username=%OS_USERNAME%

REM Prompt for password securely
echo Please enter your OpenStack Password:
set /p OS_PASSWORD=
set TF_VAR_os_password=%OS_PASSWORD%

echo Environment variables set successfully!

