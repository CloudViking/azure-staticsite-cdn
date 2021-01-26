#################################################################
#
# STATIC SITE DEPLOY SCRIPT
# F5 Poc 
#
#################################################################

# Intake and set script parameters
$parameters = Get-Content ./deployParams.json | ConvertFrom-Json
$Name = $parameters.Name.ToLower()
$location = $parameters.location
$logFile = "./deploy_$(get-date -format `"yyyyMMddhhmmsstt`").log"

# Set preference variables
$ErrorActionPreference = "Stop"

# Validate the Name parameter
Function ValidateName {
    param (
        [ValidateLength(5, 17)]
        [ValidatePattern('^(?!-)(?!.*--)[a-z]')]
        [parameter(Mandatory = $true)]
        [string]
        $Name
    )
    write-host "INFO: Name is"$Name -ForegroundColor Green
}

ValidateName $Name

# Retrieve CDN-Endpoint NAme availability
Write-Host "INFO: Checking to see if CDN Endpoint name is available..." -ForegroundColor Green
$availability = Get-AzCdnEndpointNameAvailability -EndpointName "$($Name)cdnendpoint"

If($availability.NameAvailable) { 
    Write-Host "INFO: Endpoint name is available. Proceeding with deployment" -ForegroundColor Green

    # Validate Location
    $validLocations = Get-AzLocation
    Function ValidateLocation {
        Write-Host "INFO: Validating location selected is valid Azure Region" -ForegroundColor Green
        if ($location -in ($validLocations | Select-Object -ExpandProperty Location)) {
            foreach ($l in $validLocations) {
                if ($location -eq $l.Location) {
                    $script:locationName = $l.DisplayName
                }
            }
        }
        else {
            Write-Host "ERROR: Location provided is not a valid Azure Region!" -ForegroundColor red
            exit
        }
    }

    ValidateLocation $location

    # Create resource group if it doesn't already exist
    $rgcheck = Get-AzResourceGroup -Name "$Name-rg" -ErrorAction SilentlyContinue
    if (!$rgcheck) {
        Write-Host "INFO: Creating new resource group: $Name-rg" -ForegroundColor green
        Write-Verbose -Message "Creating new resource group: $Name-rg"
        New-AzResourceGroup -Name "$Name-rg" -Location $location | Out-Null
    }
    else {
        Write-Warning -Message "Resource Group: $Name-rg already exists. Continuing with deployment..."
    }

    # Deploy Storage Account infrastructure template
    try {
        Write-Host "INFO: Deploying ARM template to create Storage Account and CDN Profile" -ForegroundColor green
        Write-Verbose -Message "Deploying ARM template to create Storage Account and CDN Profile"
        $autoscaleParams = @{
            'storageAccountName' = "$($Name)stgacct";
            'cdnProfileName'     = "cdn-profile-$Name"
        }
        $res = New-AzResourceGroupDeployment `
            -ResourceGroupName "$Name-rg" `
            -TemplateFile ./arm-templates/infra.json `
            -TemplateParameterObject $autoscaleParams
    }
    catch {
        $_ | Out-File -FilePath $logFile -Append
        Write-Host "ERROR: Unable to deploy autoscale function infrastructure ARM template due to an exception, see $logFile for detailed information!" -ForegroundColor red
        exit

    }

    # Get storage account context for artifact upload
    Write-Host "INFO: Obtaining Storage Account context for Static Site upload..." -ForegroundColor green
    Write-Verbose -Message "Obtaining Storage Account context for Static Site upload..."
    $storageAccount = Get-AzStorageAccount -ResourceGroupName "$Name-rg" -Name "$($Name)stgacct"

    if (!$storageAccount) {
        Write-Host "ERROR: Unable to obtain storage context, exiting script!" -ForegroundColor red
        exit

    } 
    else {
        try {
            Write-Host "INFO: Enabling static website in Storage Account: $($storageAccount.StorageAccountName)" -ForegroundColor Green
            Write-Verbose -Message "Enabling static website in Storage Account: $($storageAccount.StorageAccountName)"
            Enable-AzStorageStaticWebsite `
                -Context $storageAccount.Context `
                -IndexDocument index.html `
                -ErrorDocument404Path errorPage.html
        }
        catch {
            $_ | Out-File -FilePath $logFile -Append
            Write-Host "ERROR: Unable to enable static website frontend in Storage Account due to an exception, see $logFile for detailed information!" -ForegroundColor red
            exit

        }

        try {
            Write-Host "INFO: Uploading static website content to Storage Account: $($storageAccount.StorageAccountName)" -ForegroundColor Green
            Write-Verbose -Message "Uploading static website content to Storage Account: $($storageAccount.StorageAccountName)"
            Get-ChildItem `
                -File `
                -Path ./site-contents/ | `
                ForEach-Object {
                Set-AzStorageBlobContent `
                    -Container `$web `
                    -File "$_" `
                    -Blob "$($_.Name)" `
                    -Context $storageAccount.Context `
                    -Properties @{"ContentType" = "text/html" } | `
                    Out-Null
            }
            Write-Host "INFO: Static Website URL is: $($storageAccount.PrimaryEndpoints.Web)" -ForegroundColor green

        }
        catch {
            $_ | Out-File -FilePath $logFile -Append
            Write-Host "ERROR: Unable to upload static website content to Storage Account due to an exception, see $logFile for detailed information!" -ForegroundColor red
            exit
        }

    }

    # Enable CDN on Static Site
    # If available, write a message to the console.
    try {
        Write-Host "INFO: Creating CDN Endpoint for static website: $($storageAccount.PrimaryEndpoints.Web)" -ForegroundColor Green
        Write-Verbose -Message "INFO: Creating CDN Endpoint for static website: $($storageAccount.PrimaryEndpoints.Web)"
        $ori = ($storageAccount.PrimaryEndpoints.Web -replace "https://").Trim('/')
        $cdn = az cdn endpoint create `
        -g "$Name-rg" `
        -l "$location" `
        -n "$($Name)cdnendpoint" `
        --profile-name "cdn-profile-$Name" `
        --origin "$ori" `
        --origin-host-header "$ori" `
        --enable-compression

    }
    catch {
        $_ | Out-File -FilePath $logFile -Append
        Write-Host "ERROR: Unable to create CDN endpoint for static website due to an exception, see $logFile for detailed information!" -ForegroundColor red
        exit
    }
}
Else { 
    Write-Host "ERROR: That endpoint name is not available, please select a new name and try again" -ForegroundColor Red
    exit
}

$cdnHost = ($cdn | ConvertFrom-Json).hostName
Write-Host "INFO: Deployment is complete! If using GitHub Actions, please refer to the following values for GitHub secrets:" -ForegroundColor Green
Write-Host "Resource Group Name: $Name-rg" -ForegroundColor Green
Write-Host "Storage Account Name: $($Name)stgacct" -ForegroundColor Green
Write-Host "Website URL via CDN: $cdnHost" -ForegroundColor Green
Write-Host "CDN Profile Name: 'cdn-profile-$Name'" -ForegroundColor Green
Write-Host "CDN Endpoint Name: $($Name)cdnendpoint" -ForegroundColor Green


