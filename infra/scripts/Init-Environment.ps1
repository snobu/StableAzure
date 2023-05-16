<#

# .SYNOPSIS

Install all required resources for Azure Stable approach

.DESCRIPTION
 
This script will install all required resources for Azure Demo Monitoring Basics from scratch
with the use of Bicep templates. It will also install Bicep and Azure CLI if selected and get environment 
variables from local.env file. It will compile containers and push them to Azure Container Registry. 
It will configure AKS cluster to use Azure Container Registry, deploy VM with script to install all 
software on VM to be ready for deployment.  
  
.EXAMPLE

PS > Init-Environment -Location "WestEurope" -InstallModules -InstallBicep -UseEnvFile
install modules, bicep and deploy resources to West Europe

.EXAMPLE

PS > Init-Environment  -Location "WestEurope" 
install all required resources to West Europe
 
. LINK

http://github.com/vrhovnik
 
#>
param(
    [Parameter(Mandatory = $false)]
    $Location = "WestEurope",
    [Parameter(Mandatory = $false)]
    $EnvFileToReadFrom = "local.env",
    [Parameter(Mandatory = $false)]
    [switch]$InstallModules,
    [Parameter(Mandatory = $false)]
    [switch]$InstallBicep,
    [Parameter(Mandatory = $false)]
    [switch]$InstallAzCli,
    [Parameter(Mandatory = $false)]
    [switch]$UseEnvFile,
    [Parameter(Mandatory = $false)]
    [switch]$InstallKubectl
)

$ProgressPreference = 'SilentlyContinue';
Start-Transcript -Path "$HOME/Downloads/bootstrapper.log" -Force
# Write-Output "Sign in to Azure account." 
# login to Azure account
# Connect-AzAccount

if ($InstallModules)
{
    Write-Output "Install Az module and register providers."
    #install Az module
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    Install-Module -Name Az.App

    #register providers
    Register-AzResourceProvider -ProviderNamespace Microsoft.App
    # add support for log analytics
    Register-AzResourceProvider -ProviderNamespace Microsoft.OperationalInsights
    Write-Output "Modules installed and registered, continuing to Azure deployment nad if selected, Bicep install."
}

if ($InstallBicep)
{
    # install bicep
    Write-Output "Installing Bicep."
    # & Install-Bicep.ps1
    Start-Process powershell.exe -FilePath Install-Bicep.ps1 -NoNewWindow -Wait
    Write-Output "Bicep installed, continuing to Azure deployment."
}

if ($InstallAzCli)
{
    Write-Output "Installing Azure CLI."

    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi;
    Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet';
    ## cleanup of Azure CLI
    Remove-Item .\AzureCLI.msi
    Write-Output "Az CLI installed, continuing to Azure deployment."
}

if ($InstallKubectl){
    Write-Output "Installing kubectl via PowerShell"
    # install kubectl
    #Invoke-WebRequest -Uri https://dl.k8s.io/release/v1.21.0/bin/windows/amd64/kubectl.exe -OutFile .\kubectl.exe;
    # https://learn.microsoft.com/en-us/powershell/module/az.aks/install-azaksclitool?view=azps-9.6.0
    Install-AzAksCliTool 
    Write-Output "Kubectl installed, continuing to Azure deployment."
}

if ($UseEnvFile)
{
    Get-Content $EnvFileToReadFrom | ForEach-Object {
        $name, $value = $_.split('=')
        Set-Content env:\$name $value
        Write-Information "Writing $name to environment variable with $value."
    }
}

# create resource group if it doesn't exist with bicep file stored in bicep folder
$groupNameExport = New-AzSubscriptionDeployment -Location $Location -TemplateFile "..\AzureUI\rg.bicep" -TemplateParameterFile "..\AzureUI\rg.parameters.json" -Verbose
Write-Information $groupNameExport
$groupName = $groupNameExport.Outputs.rgName.Value

Write-Verbose "The resource group name is $groupName"
# deploy log analytics file if not already deployed
New-AzResourceGroupDeployment -ResourceGroupName $groupName -TemplateFile "..\AzureUI\registry.bicep" -TemplateParameterFile "..\AzureUI\registry.parameters.json" -Verbose
## deploy azure storage file if not already deployed
New-AzResourceGroupDeployment -ResourceGroupName $groupName -TemplateFile "..\AzureUI\Main.bicep" -TemplateParameterFile "..\AzureUI\Main.parameters.json" -Verbose

Stop-Transcript

# open file for viewing
Start-Process notepad.exe -ArgumentList "$HOME/Downloads/bootstrapper.log"
