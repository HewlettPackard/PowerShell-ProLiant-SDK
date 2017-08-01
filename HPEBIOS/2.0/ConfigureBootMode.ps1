########################################################
#Configuring BIOS boot mode
###################################################----#

<#
.Synopsis
    This script allows user to change boot mode (UEFI / Legacy) of HPE Proliant Gen 9 servers

.DESCRIPTION
    This script allows user to change the boot mode.
    BootMode :- Use this option to set the boot mode for the system. HP ProLiant Gen9 servers provide two boot mode 
    configurations: UEFI Mode and Legacy BIOS Mode.

.EXAMPLE
    ConfigureBootMode.ps1
    This mode of exetion of script will prompt for 
    
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    BootMode   :- Accepted values are LegacyBIOSMode or UEFIMode.For multiple servers values should be separated by comma(,)

.EXAMPLE
    ConfigureBootMode.ps1 -Address "10.20.30.40" -Credential $userCredential -BootMode "UEFIMode"

    This mode of script have input parameter for Address Credential and BootMode
    
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user credential.#In case of multiple servers use same credential for all the servers
    
    -BootMode :- Use this Parameter to specify boot mode. Accepted values are LegacyBIOSMode or UEFIMode

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    BootMode

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
    #In case of multiple servers it use same credential for all the servers
    [PSCredential]$Credential, 
    # Boot mode (UEFI or LegacyBIOS)
    [String[]]$BootMode  
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

Write-Host "This script allows user to change boot mode."
Write-Host ""

#dont shoe error in scrip

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

# check for IP(s) or Hostname(s) Input. if not available prompt for Input

if($Address.Count -eq 0)
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}
    
[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)"
    Write-Host ""
    Write-Host "Exit..."
    exit
}

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password(Use same credential for multiple servers)"
    Write-Host ""
}

#  Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

# create connection object
[array]$ListOfConnection = @()

foreach($IPAddress in $ListOfAddress)
{
    
    Write-Host ""
    Write-Host "Connecting to server  : $IPAddress"
    $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential
    
    #Retry connection if it is failed because  of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "The underlying connection was closed")
    {
       $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        $connection
        if($connection.ProductName.Contains("Gen9") -or $connection.ProductName.Contains("Gen10"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "Boot mode is not supported on Server $($connection.IP)"
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
    Write-Host "Exit..."
    Write-Host ""
    exit
}

# Get current boot mode

Write-Host ""
Write-Host "Current Boot Mode configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
    $result = Get-HPEBIOSBootMode -Connection $serverConnection
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}
# Get the valid value list fro each parameter
$parameterMetaData = $(Get-Command -Name Set-HPEBIOSBootMode).Parameters
$bootModeValidValues = $($parameterMetaData["BootMode"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""
if($BootMode.Count -eq 0)
{
    $tempBootMode = Read-Host "Enter Boot Mode [Accepted values : ($($bootModeValidValues -join ","))]."
    $BootMode = $tempBootMode.Trim().Split(',')
    if($BootMode.Count -eq 0)
    {
        Write-Host "BootMode is not provided`n Exit......."
        exit
    }
}


for($i = 0;$i -lt $ListOfConnection.Count ;$i++)
{
	if($($bootModeValidValues | where {$_ -eq $BootMode[$i]}) -eq $null)
	{
		Write-Host "Invalid Boot mode" -ForegroundColor Red
		Write-Host "Exit...."
		exit
	}
}

Write-Host "Changing Boot mode....." -ForegroundColor Green

$failureCount = 0
if($ListOfConnection.Count -ne 0)
{
	$setResult =  Set-HPEBIOSBootMode -Connection $ListOfConnection -BootMode $BootMode
    foreach($result in $setResult)
    {
	    if($result.Status -eq "Error")
	    {
		    Write-Host ""
		    Write-Host "Boot mode Cannot be changed"
		    Write-Host "Server : $($result.IP)"
		    Write-Host "Error : $($result.StatusInfo)"
		    Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
		    $failureCount++
	    }
	    elseif($result.Status -eq "Warning")
	    {
		    Write-Host ""
		    Write-Host "Server : $($result.IP)"
		    Write-Host "Status : $($result.Status)"
		    Write-Host "StatusInfo : $($result.StatusInfo)"
		    Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
	    }
    }
}

if($failureCount -ne $ListOfConnection.Count)
{
	Write-Host ""
	Write-host "Boot mode changed successfully" -ForegroundColor Green
	Write-Host ""
	$counter = 1
	foreach($serverConnection in $ListOfConnection)
	{
		$result = Get-HPEBIOSBootMode -Connection $serverConnection
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
