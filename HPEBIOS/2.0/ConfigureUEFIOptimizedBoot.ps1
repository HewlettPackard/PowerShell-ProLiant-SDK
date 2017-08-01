##############################################################
#Configuring UEFI optimized boot
##########################################################----#

<#
.Synopsis
    Script to Enabled / Disabled UEFI optimized boot of HPE Proliant Gen 9 servers.

.DESCRIPTION
    This script is to enable or disable UEFI Optimized Boot, which controls the video settings that the system BIOS uses.
    Before changing this setting, consider the following: 
    1) If you are running Microsoft Windows 2008 or Windows 2008 R2 operating systems, and the system is configured for UEFI Mode, 
    this option must be set to disabled. Legacy BIOS Mode components are needed for video operations in Windows.
    2) Boot Mode must be set to UEFI Mode when this option is enabled. See “Boot Mode” (page 23).

.EXAMPLE
    ConfigureUEFIOptimizedBoot.ps1
    This mode of exetion of script will prompt for 
    
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    Credential :- it will prompt for user name and password. In the case of multiple servers use same credential for all the servers
    
    UEFIOptimizedBoot   :- it will prompt to eneter UEFI optimized boot to set.

.EXAMPLE
    ConfigureUEFIOptimizedBoot.ps1 -Address "10.20.30.40" -Credential $userCredential -UEFIOptimizedBoot "Enabled"

    This mode of script have input parameter for Address Credential and BootMode
    
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user credential.
    
    -UEFIOptimizedBoot :- specify UEFI optimized boot.

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    UEFIOptimizedBoot

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
     # In the case of multiple servers it use same credential for all the servers
    [PSCredential]$Credential,
    # UEFI optimized boot mode
    [String[]] $UEFIOptimizedBoot  
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

Write-Host "This script is to enable or disable UEFI Optimized Boot, which controls the video settings that the system BIOS uses."
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
            Write-Host "UEFI optimized boot is not supported on Server $($connection.IP)"
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


# Get UEFI optimized boot
if($ListOfConnection.Count -ne 0)
{
    Write-Host ""
    Write-Host "UEFI optimized boot configuration" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $result = $serverConnection | Get-HPEBIOSUEFIOptimizedBoot
        Write-Host "----------------------- Server $counter -----------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $counter++
    }
}
# Get the valid value list fro each parameter
$parameterMetaData = $(Get-Command -Name Set-HPEBIOSUEFIOptimizedBoot).Parameters
$UEFIOptimizedValidValues = $($parameterMetaData["UEFIOptimizedBoot"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

if($UEFIOptimizedBoot.Count -eq 0)
{
    $tempUEFIOptimizedBoot = Read-Host "Enter UEFIOptimizedBoot [Accepted values : ($($UEFIOptimizedValidValues -join ","))]."
    Write-Host ""
    $UEFIOptimizedBoot = $tempUEFIOptimizedBoot.Trim().Split(',')
    if($UEFIOptimizedBoot.Count -eq 0)
    {
        Write-Host "UEFIOptimizedBoot is not provided`nExit....."
        exit
    }
}

#validate the userinput value
for($i =0;$i -lt $UEFIOptimizedBoot.Count ;$i++)
{
    if($($UEFIOptimizedValidValues | where{$_ -eq $UEFIOptimizedBoot[$i]}) -eq $null)
    {
        Write-Host "Invalid value for UEFI optimized boot" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing UEFI optimized boot....." -ForegroundColor Green  
$failureCount = 0

if($ListOfConnection.Count -ne 0)
{
    $setResult = Set-HPEBIOSUEFIOptimizedBoot -Connection $ListOfConnection -UEFIOptimizedBoot $UEFIOptimizedBoot
    foreach($result in $setResult)
    {
        if($result.Status -eq "Error")
        {
            Write-Host ""
            Write-Host "UEFI optimized boot cannot be changed"
            Write-Host "Server : $($result.IP)"
            $($result.StatusInfo) | fl
            $failureCount++
        }
    }
}

if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "UEFI optimized boot successfully" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $result = $serverConnection | Get-HPEBIOSUEFIOptimizedBoot
        Write-Host "----------------------- Server $counter -----------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $counter++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit
