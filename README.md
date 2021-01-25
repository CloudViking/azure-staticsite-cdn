# Static Website POC

## What is this?
A small demonstration of how to host a static website out of Azure Storage, deploy it using CI/CD patterns via Azure DevOps, and integrate it with Azure CDN.

- **Azure Storage Account**
    - Static Site Enabled
    - Deployed via ARM

- **Static Website Content**
    - Packaged and deployed via Azure DevOps
    - Simple site for demo purposes

- **Integrate with Azure CDN**
    - CDN Profile
    - CDN Endpoint established
    - Compression Enabled

## Running the sample

### Steps to deploy infrastructure:

- Clone repo down to local machine
- Fill in your variable values in `deployParams.json` file, make sure to save
- Run `deploy.ps1` from project root

### Steps to tear down the deployment:
- Run `teardown.ps1` from project root
    - Script will use values from the `deployParams.json` file


