##############################################################
#Configuring the server security
##########################################################----#
<#
.Synopsis
    This script allows user to configure server security for HPE Proliant servers(Gen9 and Gen10)

.DESCRIPTION
    This script allows user to configure server security.Following features can be configured
    IntelligentProvisioningF10Prompt :-  Use this option to control whether you can press the F10 key to access Intelligent Provisioning from
                                         the HP ProLiant POST screen.
    F11BootMenuPrompt :- Use this option to control whether you can press the F11 key to boot directly to the One-Time Boot Menu during the current boot.
                         This option does not modify the normal boot order settings.
    ProcessorAESNISupport :-  Use this option to enable or disable the Advanced Encryption Standard Instruction Set in the processor.

.EXAMPLE
    ConfigureServerSecurity.ps1
    This mode of exetion of script will prompt for 
    
     Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
    
     Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
     IntelligentProvisioningF10Prompt :- Accepted values are Enabled and Disabled
    
     F11BootMenuPrompt :- Accepted values are Enabled and Disabled
    
     ProcessorAESNISupport :- Accepted values are Enabled and Disabled
.EXAMPLE
    ConfigureServerSecurity.ps1 -Address "10.20.30.40,10.25.35.45" -Credential $userCrdential -IntelligentProvisioningF10Prompt "Enabled,Disabled" -F11BootMenuPrompt "Enabled,Disabled" -ProcessorAESNISupport "Disabled Enabled"

    This mode of script have input parameters for Address, Credential and ResetBIOSSetting
    
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user credential.#In case of multiple servers use same credential for all the servers
    
    -IntelligentProvisioningF10Prompt :- specify Intelligent provisioning.Accepted values are Enabled and Disabled 
    
    -F11BootMenuPrompt :-  specify boot menu prompt. Accepted values are Enabled and Disabled
    
    -ProcessorAESNISupport :- specify Advanced Encryption standards.Accepted values are Enabled and Disabled
    
.NOTES
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    IntelligentProvisioningF10Prompt
    F11BootMenuPrompt
    ProcessorAESNISupport

.OUTPUTS
    None (by default)

.LINK
    
   http://www.hpe.com/servers/powershell
   https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>

#Command line parameters
Param(
    # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [string[]]$Address,   
    #In the case of multiple servers it use same credential for all the server.
    [PSCredential]$Credential, 
    #specify Intelligent provisioning.Accepted values are Enabled and Disabled. 
    [string[]]$IntelligentProvisioningF10Prompt,
    #specify boot menu prompt. Accepted values are Enabled and Disabled.
    [string[]]$F11BootMenuPrompt,
    #specify Advanced Encryption standards.Accepted values are Enabled and Disabled.
    [string[]]$ProcessorAESNISupport 
    )

#Check for server avaibiality
 function CheckServerAvailability ($ListOfAddress)
 {
    [int]$pingFailureCount = 0
    [array]$PingedServerList = @()
    foreach($serverAddress in $ListOfAddress)
    {
       if(Test-Connection $serverAddress)
       {
        #Write-Host "Server $serverAddress pinged successfully."
        $PingedServerList += $serverAddress
       }
       else
       {
        Write-Host ""
        Write-Host "Server $serverAddress is not reachable. Please check network connectivity"
        $pingFailureCount ++
       }
    }

    if($pingFailureCount -eq $ListOfAddress.Count)
    {
        Write-Host ""
        Write-Host "Server(s) are not reachable please check network conectivity"
        exit
    }
    return $PingedServerList
 }

#clear host
Clear-Host

# script execution started
Write-Host "****** Script execution started ******" -ForegroundColor Yellow
Write-Host ""
#Decribe what script does to the user

Write-Host "This script allows user to configure server security. User can configure following featur"
Write-Host "One-Time Boot Menu (F11 Prompt)"
Write-host "Intelligent Provisioning (F10 Prompt)"
Write-host "Processor AES-NI Support"
Write-Host ""

#dont show error in scrip

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"
$ErrorActionPreference = "SilentlyContinue"

#check powershell support
#Write-Host "Checking PowerShell version support"
#Write-Host ""
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "3")
{
    Write-Host "Your powershell version : $($PSVersionTable.PSVersion) is valid to execute this script"
    Write-Host ""
}
else
{
    Write-Host "This script required PowerSehll 3 or above"
    Write-Host "Current installed PowerShell version is $($PSVersionTable.PSVersion)"
    Write-Host "Please Update PowerShell version"
    Write-Host ""
    Write-Host "Exit..."
    Write-Host ""
    exit
}

#Load HPEBIOSCmdlets module
#Write-Host "Checking HPEBIOSCmdlets module"
#Write-Host ""

$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEBIOSCmdlets"))
{
    Write-Host "Loading module :  HPEBIOSCmdlets"
    Import-Module HPEBIOSCmdlets
    if(($(Get-Module -Name "HPEBIOSCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEBIOSCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstalledBiosModule  =  Get-Module -Name "HPEBIOSCmdlets"
    Write-Host "HPEBIOSCmdlets Module Version : $($InstalledBiosModule.Version) is installed on your machine."
    Write-host ""
}


# check for IP(s) or Hostname(s)

if($Address.count -eq 0)
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}

[array]$ListOfAddress = ($Address.split(",")).Trim()

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)"
    Write-Host ""
    Write-Host "Exit..."
    exit
}

if($Credential -eq $null)
{
    Write-Host "Enter User Credentials"
    Write-Host ""
    $Credential = Get-Credential -Message "Enter user Credentials"
}

# Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

[array]$ListOfConnection = @()

# create connection object
foreach($IPAddress in $ListOfAddress)
{
    
    Write-Host "Connecting to server  : $IPAddress"
    Write-Host ""
    $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential

    #Retry connection if it is failed because  of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "The underlying connection was closed")
    {
       $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if(($connection.ProductName.Contains("Gen10") -or $connection.ProductName.Contains("Gen9")))
    {
        
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        Write-Host ""
        $connection
        $ListOfConnection += $connection
    }
    else
    {
         Write-Host "This script is not supported for the target server : $IPAddress" -ForegroundColor Red
		 Disconnect-HPEBIOS -Connection $connection
    }
}


if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit"
    Write-Host ""
    exit
}

# Get current server security configuration 

Write-Host ""
Write-Host "Current server security configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
    $result = $serverConnection | Get-HPEBIOSServerSecurity
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}

# Get the valid value list fro each parameter
$ParamtersMetaData = $(Get-Command -Name Set-HPEBIOSServerSecurity).Parameters
$IntelligentProvisioningF10PromptValidValues = $($ParamtersMetaData["IntelligentProvisioningF10Prompt"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$F11BootMenuPromptValidValues = $($ParamtersMetaData["F11BootMenuPrompt"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$ProcessorAESNISupportValidValues = $($ParamtersMetaData["ProcessorAESNISupport"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

#Prompt for User input if it is not given as script  parameter 
if($IntelligentProvisioningF10Prompt.Count -eq 0)
{
    
    $tempIntelligentProvisioningF10Prompt = Read-Host "Enter IntelligentProvisioningF10Prompt [Accpeted Values : ($($IntelligentProvisioningF10PromptValidValues -join ","))]"
    $IntelligentProvisioningF10Prompt = $tempIntelligentProvisioningF10Prompt.Trim().Split(',')
    if($IntelligentProvisioningF10Prompt.Count -eq 0)
    {
        Write-Host "IntelligentProvisioningF10Prompt is not provided`n Exit......"
        Exit
    }
}

if($F11BootMenuPrompt.Count -eq 0)
{
    $tempF11BootMenuPrompt = Read-Host "Enter F11BootMenuPrompt [Accepted values : ($($F11BootMenuPromptValidValues -join ","))]"
    $F11BootMenuPrompt = $tempF11BootMenuPrompt.Trim().Split(',')
    if($F11BootMenuPrompt -eq 0)
    {
        Write-Host "F11BootMenuPrompt is not provided`n Exit......"
        Exit
    }
}


if($ProcessorAESNISupport.Count -eq 0)
{
    $tempProcessorAESNISupport = Read-Host "Enter ProcessorAES-NI Suppott [Accepted values : ($($ProcessorAESNISupportValidValues -join ","))]."
    $ProcessorAESNISupport = $tempProcessorAESNISupport.Trim().Split(',')
    if($ProcessorAESNISupport.Count -eq 0)
    {
        Write-Host "ProcessorAESNISupport is not provided`n Exit......"
        Exit
    }
}

#Validate user input and add to ToSet List to set the values
for($i = 0; $i -lt $IntelligentProvisioningF10Prompt.Count ;$i++)
{
    if($($IntelligentProvisioningF10PromptValidValues | where {$_ -eq $IntelligentProvisioningF10Prompt[$i]}) -eq $null)
    {
        Write-Host "Invalid value for IntelligentProvisioningF10Prompt" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

for($i = 0 ;$i -lt $F11BootMenuPrompt.Count ; $i++)
{    
    if($($F11BootMenuPromptValidValues | where {$_ -eq $F11BootMenuPrompt[$i]}) -eq $null)
    {
        Write-Host "Invalid value for F11BootMenuPrompt " -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

for($i = 0 ;$i -lt  $ProcessorAESNISupport.Count; $i++ )
{    
    if($($ProcessorAESNISupportValidValues | where {$_ -eq $ProcessorAESNISupport[$i]}) -eq $null)
    {
        Write-Host "Invalid value for ProcessorAESNISupport " -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing server security configuration....." -ForegroundColor Green

$failureCount = 0
if($ListOfConnection.Count -ne 0)
{
        $setResult =  Set-HPEBIOSServerSecurity -Connection $ListOfConnection -IntelligentProvisioningF10Prompt $IntelligentProvisioningF10Prompt -F11BootMenuPrompt $F11BootMenuPrompt -ProcessorAESNISupport $ProcessorAESNISupport
        
        foreach($result in $setResult)
        {
            if($result.Status -eq "Error")
            {
                Write-Host ""
                Write-Host "server security Cannot be changed"
                Write-Host "Server : $($result.IP)"
                Write-Host "Error : $($result.StatusInfo)"
			    Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
			    Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
			    Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
                $failureCount++
            }
        }
}

#get the server security configuration after set
if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "Server security configuration changed successfully" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $result = $serverConnection | Get-HPEBIOSServerSecurity
        Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $counter++
    }
    }
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit