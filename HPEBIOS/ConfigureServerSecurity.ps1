<#
.Synopsis
    This script allows user to configure server security for HPE Proliant servers(Gen 8 and Gen 9)

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
    -Credential :- Use this parameter to sepcify user credential.
    -IntelligentProvisioningF10Prompt :- specify Intelligent provisioning.Accepted values are Enabled and Disabled 
    -F11BootMenuPrompt :-  specify boot menu prompt. Accepted values are Enabled and Disabled
    -ProcessorAESNISupport :- specify Advanced Encryption standards.Accepted values are Enabled and Disabled
    
.NOTES
    Company : Hewlett Packard Enterprise
    Version : 1.1.0.0
    Date    : 9/8/2016
    
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
    
    http://www8.hp.com/in/en/products/server-software/product-detail.html?oid=5440657
#>

#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # all server should have same ceredntial (in case of multiple addresses)
    [string]$IntelligentProvisioningF10Prompt,
    [string]$F11BootMenuPrompt,
    [string]$ProcessorAESNISupport 
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

#Load HPBIOSCmdlets module
#Write-Host "Checking HPBIOSCmdlets module"
#Write-Host ""

$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPBIOSCmdlets"))
{
    Write-Host "Loading module :  HPBIOSCmdlets"
    Import-Module HPBIOSCmdlets
    if(($(Get-Module -Name "HPBIOSCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPBIOSCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstalledBiosModule  =  Get-Module -Name "HPBIOSCmdlets"
    Write-Host "HPBIOSCmdlets Module Version : $($InstalledBiosModule.Version) is installed on your machine."
    Write-host ""
}


# check for IP(s) or Hostname(s)

if($Address -eq "")
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
    $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential

    #Retry connection if it is failed because  of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "iLO SSL Certificate is not valid")
    {
       $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
    {
        
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        Write-Host ""
        $connection
        $ListOfConnection += $connection
    }
    else
    {
         Write-Host "Connection cannot be eastablished to the server : $IPAddress" -ForegroundColor Red
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
    $result = $serverConnection | Get-HPBIOSServerSecurity
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}

# Get the valid value list fro each parameter
$ParamtersMetaData = $(Get-Command -Name Set-HPBIOSServerSecurity).Parameters
$IntelligentProvisioningF10PromptValidValues = $($ParamtersMetaData["IntelligentProvisioningF10Prompt"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$F11BootMenuPromptValidValues = $($ParamtersMetaData["F11BootMenuPrompt"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$ProcessorAESNISupportValidValues = $($ParamtersMetaData["ProcessorAESNISupport"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

#Prompt for User input if it is not given as script  parameter 
if($IntelligentProvisioningF10Prompt -eq "")
{
    
    $IntelligentProvisioningF10Prompt = Read-Host "Enter IntelligentProvisioningF10Prompt [Accpeted Values : ($($IntelligentProvisioningF10PromptValidValues -join ","))]"
    Write-Host ""
}

if($F11BootMenuPrompt -eq "")
{
    $F11BootMenuPrompt = Read-Host "Enter F11BootMenuPrompt [Accepted values : ($($F11BootMenuPromptValidValues -join ","))]"
    Write-Host ""
}


if($ListOfConnection[$i].ConnectionInfo.ServerPlatformNumber -eq 9)
{

    if($ProcessorAESNISupport -eq "")
    {
        $ProcessorAESNISupport = Read-Host "Enter ProcessorAES-NI Suppott [Accepted values : ($($ProcessorAESNISupportValidValues -join ","))]."
        Write-Host ""
    }

}
# split the user input value
$IntelligentProvisioningF10PromptList =  ($IntelligentProvisioningF10Prompt.Trim().Split(','))
$F11BootMenuPromptList = ($F11BootMenuPrompt.Trim().Split(','))
$ProcessorAESNISupportList = ($ProcessorAESNISupport.Trim().Split(','))

if(($IntelligentProvisioningF10PromptList.Count -eq 0)  -and ($F11BootMenuPromptList.Count -eq 0))
{
    Write-Host "You have not enterd parameter value"
    Write-Host "Exit....."
    exit
}

#Validate user input and add to ToSet List to set the values
[array]$IntelligentProvisioningF10PromptToSet = @()
[array]$F11BootMenuPromptToSet = @()
[array]$ProcessorAESNISupportToSet = @()

for($i = 0; $i -lt $ListOfConnection.Count ;$i++)
{
    if($($IntelligentProvisioningF10PromptValidValues | where {$_ -eq $IntelligentProvisioningF10PromptList[$i]}) -ne $null)
    {
        $IntelligentProvisioningF10PromptToSet += $IntelligentProvisioningF10PromptList[$i];
    }
    else
    {
        Write-Host "Invalid value for IntelligentProvisioningF10Prompt" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }


    if($($F11BootMenuPromptValidValues | where {$_ -eq $F11BootMenuPromptList[$i]}) -ne $null)
    {
        $F11BootMenuPromptToSet += $F11BootMenuPromptList[$i];
    }
    else
    {
        Write-Host "Invalid value for F11BootMenuPrompt " -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }


    
    if($ListOfConnection[$i].ConnectionInfo.ServerPlatformNumber -eq 9)
    {

        if($($ProcessorAESNISupportValidValues | where {$_ -eq $ProcessorAESNISupportList[$i]}) -ne $null)
        {
            $ProcessorAESNISupportToSet += $ProcessorAESNISupportList[$i];
        }
        else
        {
            Write-Host "Invalid value for ProcessorAESNISupport " -ForegroundColor Red
            Write-Host "Exit...."
            exit
        }
    }
}

Write-Host "Changing server security configuration....." -ForegroundColor Green

$failureCount = 0
for ($i = 0 ;$i -lt $ListOfConnection.Count ; $i++)
{
        if($ListOfConnection[$i].ConnectionInfo.ServerPlatformNumber -eq 8)
        {
            $result = $ListOfConnection[$i] | Set-HPBIOSServerSecurity -IntelligentProvisioningF10Prompt $IntelligentProvisioningF10PromptToSet[$i] -F11BootMenuPrompt $F11BootMenuPromptToSet[$i]
        }
        else
        {
             $result = $ListOfConnection[$i] | Set-HPBIOSServerSecurity -IntelligentProvisioningF10Prompt $IntelligentProvisioningF10PromptToSet[$i] -F11BootMenuPrompt $F11BootMenuPromptToSet[$i] -ProcessorAESNISupport $ProcessorAESNISupportToSet[$i]
        }
        if($result.StatusType -eq "Error")
        {
            Write-Host ""
            Write-Host "server security Cannot be changed"
            Write-Host "Server : $($result.IP)"
            Write-Host "Error : $($result.StatusMessage)"
            $failureCount++
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
        $result = $serverConnection | Get-HPBIOSServerSecurity
        Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $counter++
    }
    }
    
Disconnect-HPBIOSAllConnection    
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit