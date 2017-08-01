########################################################
#Resetting BIOS user default settings
###################################################----#

<#
.Synopsis
    This script allows user to reset bios setting to factory default on Proliant Gen 9 servers

.DESCRIPTION
    This script will resets all BIOS configuration settings to their default manufacturing values and delete all UEFI non-volatile variables, 
    such as boot configuration and Secure Boot security keys (if Secure Boot is enabled). Previous changes that is made might be lost.
    This script is for HPE Proliant Gen9 servers.

.EXAMPLE
    ResetBIOSUserDefaultSettings.ps1
    This mode of exetion of script will prompt for 
     Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be seperated by comma(,)
     Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
     ResetBIOSSetting :- Use this Parameter to conform reset.
.EXAMPLE
    ResetBIOSUserDefaultSettings.ps1 -Address "10.20.30.40,10.25.35.45" -Credential $userCrdential -ResetBIOSSetting $true

    This mode of script have input parameters for Address, Credential and ResetBIOSSetting
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be seperated by comma(,)
    -Credential :- Use this parameter to sepcify user credential.In the case of multiple servers use same credential for all the servers
    -ResetBIOSSetting :- Use this Parameter to conform reset.
    
.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    ResetBIOSSetting

.OUTPUTS
    None (by default)

.LINK
    
   http://www.hpe.com/servers/powershell
   https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>

#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # In the case of multiple servers it use same credential for all the servers
    [boolean]$ResetBIOSSetting # Confirmation password to reset bios settings. 
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

Write-Host "This script will resets all BIOS configuration settings to their default manufacturing values and delete all UEFI non-volatile variables."
Write-Host "This script is for HPE Proliant Gen9 servers."
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

#Load HPILOCmdlets module
#Write-Host "Checking HPILOCmdlets module"
#Write-Host ""

$InstalledModule = Get-Module
$InstalledModuleNames = $InstalledModule.Name

if(-not($InstalledModuleNames -like "HPILOCmdlets"))
{
    Write-Host "Loading module :  HPILOCmdlets"
    Import-Module HPILOCmdlets
    if(($(Get-Module -Name "HPILOCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPILOCmdlets module cannot be loaded.Hence server cannot be restart automatically.Please do it manually" -ForegroundColor Yellow
        Write-Host ""
    }
}
else
{
    $InstalledILOModule  =  Get-Module -Name "HPILOCmdlets"
    Write-Host "HPILOCmdlets Module Version : $($InstalledILOModule.Version) is installed on your machine."
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
    $Credential = Get-Credential -Message "Enter user Credentials"
    Write-Host ""
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

    if($connection -ne $null)
    {
        
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        Write-Host ""
        $connection
        if($connection.ProductName.Contains("Gen9") -or $connection.ProductName.Contains("Gen10"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "Reset BIOS user default settings is not supported on Server $($connection.IP)" -ForegroundColor Red
			Disconnect-HPEBIOS -Connection $connection
        }
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

if(-not($ResetBIOSSetting))
{
    $readUserInput = Read-Host("Do you want to reset bios settings [Accepted values : (Yes/ No)]")
    if($readUserInput.ToLower().Equals("yes") -or $readUserInput.ToLower().Equals("y"))
    {
        $ResetBIOSSetting = $true
    }
    elseif($readUserInput.ToLower().Equals("no") -or $readUserInput.ToLower().Equals("n"))
    {
            $ResetBIOSSetting = $false   
    }
    else
    {
        Write-Host "Input value is not correct" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}
    
if($ResetBIOSSetting)
{
    $resultList = $ListOfConnection | Reset-HPEBIOSDefaultManufacturingSetting -ResetDefaultManufacturingSetting
    if($resultList -eq $null)
    {
        Write-Host ""
        Write-Host "BIOS settings reset successfully......" -ForegroundColor Green
        Write-Host ""
        
        foreach($item in $ListOfConnection)
        {
            $serverRestart = Reset-HPiLOServer -Server $($item.IP) -Credential $Credential -DisableCertificateAuthentication
            if($serverRestart.STATUS_MESSAGE -contains "Server being reset.")
            {
                Write-Host "Server $($item.IP) being reset....." -ForegroundColor Green
                Write-Host ""
            }
        }
        
    }
    else
    {
        Write-Host ""
        Write-Host "BIOS settings reset failed...."
		Write-Host "Error : $($result.StatusInfo)"
		Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
    }
}

Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit