---
page_type: sample
languages:
- powershell
products:
- azure
- azure-powershell
- azure-resource-manager-templates
- azure-storage
- azure-cdn
- github-actions
description: "Sample project to demonstrate the ability to host a static webpage, fronted by Azure CDN."
---

# Static Website POC

<!-- 
Guidelines on README format: https://review.docs.microsoft.com/help/onboard/admin/samples/concepts/readme-template?branch=master

Guidance on onboarding samples to docs.microsoft.com/samples: https://review.docs.microsoft.com/help/onboard/admin/samples/process/onboarding?branch=master

Taxonomies for products and languages: https://review.docs.microsoft.com/new-hope/information-architecture/metadata/taxonomies?branch=master
-->

A small project to show how to host a static website out of Azure Storage, fronted by Azure CDN. The infrastructure is deployed via a powershell deployment script and Azure Resource Manager templates.  This project also includes the GitHub Actions yaml file to enable CI/CD workflows for this project.

## Contents

| File/folder       | Description                                |
|-------------------|--------------------------------------------|
| `.github/`        | GitHub Actions workflows.                  |
| `arm-templates/`   | Static Site Infrastructure ARM Template.  |
| `site-contents/` | Static website contents. `index.html` and `errorPage.html`.|
| `.gitignore`      | Define what to ignore at commit time.      |
| `deploy.ps1`      | PowerShell script to deploy static site.   |
| `deployParams.json`| Deployment parameters used by `deploy.ps1` and `teardown.ps1` scripts.|
| `README.md`       | This README file.                          |
| `teardown.ps1`    | PowerShell script to decommission the website. Makes testing and experimentation easy.|
| `CHANGELOG.md`    | List of changes to the sample. COMING SOON!|
| `CONTRIBUTING.md` | Guidelines for contributing to the sample. COMING SOON!|
| `LICENSE`         | The license for the sample. COMING SOON!   |


## What does this actually deploy??

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

- **GitHub Action**
    - Included YAML file 
    - Configure environment secrets to use

## Running this Project

### Steps to deploy infrastructure
- Clone/Fork repo down to local machine
- Fill in your variable values in `deployParams.json` file, make sure to save
- Run `deploy.ps1` from project root
    - Script will spit out the CDN endpoint of the deployed site, browse to the provided URL to verify deployment.
- After infrastructure deployment is complete, you can configure your GitHub Action for CI/CD functionality (covered below)


### Setting up GitHub Actions
This project contains the `main.yml` file which will allow for the static site content to be deployed via Github Actions. The GitHub Action will login to Azure, upload static site contents to `$web` container in the defined storage account. This action will also flush the CDN Endpoints to ensure they all pick up the newest changes upon deployment. The Github Actions `main.yml` file has been written to use GitHub Secrets to keep the template flexible. You will need to add the following secrets to your GitHub Repo:

**REQUIRED GITHUB SECRETS:**
- AZURE_STATICSITE_CREDENTIALS
    - You will need to create a Service Principal for GitHub Actions to use to auth against Azure and upload the static site content
    - Examples here: [Deploying Static Site to Azure with Github Actions]('https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-static-site-github-actions')
- CDN_ENDPOINT_NAME
    - Name of the CDN Endpoint you want to flush when deploying new site content
- CDN_PROFILE_NAME
    - Name of the CDN Profile associated with your static site
- RESOURCE_GROUP
    - Name of the Resource Group the Storage Account is deployed to.
- STATICSITE_SOURCE
    - Path to static site content. In this repo it is `'site-contents/'`
- STATICSITE_STGACCT
    - Name of Storage Accout to deploy to

### Steps to tear down the deployment
- Run `teardown.ps1` from project root
    - Script will use values from the `deployParams.json` file


