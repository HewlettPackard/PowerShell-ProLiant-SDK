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
    BootMode   :- Accepted values are Legacy_BIOS_Mode or UEFI_Mode.For multiple servers values should be separated by comma(,)

.EXAMPLE
    ConfigureBootMode.ps1 -Address "10.20.30.40" -Credential $userCredential -BootMode "UEFI legacy"

    This mode of script have input parameter for Address Credential and BootMode
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- Use this parameter to sepcify user credential.
    -BootMode :- Use this Parameter to specify boot mode. Accepted values are Legacy_BIOS_Mode or UEFI_Mode

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 1.1.0.0
    Date    : 8/8/2016
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    BootMode

.OUTPUTS
    None (by default)

.LINK
    
    http://www8.hp.com/in/en/products/server-software/product-detail.html?oid=5440657
#>



#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # all server should have same ceredntial (in case of multiple addresses)
    [String]$BootMode  # Boot mode (UEFI or LegacyBIOS)
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

# check for IP(s) or Hostname(s) Input. if not available prompt for Input

if($Address -eq "")
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
    $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential
    
    #Retry connection if it is failed because  of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "iLO SSL Certificate is not valid")
    {
       $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        $connection
        if($connection.ConnectionInfo.ServerPlatformNumber -eq 9)
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "Boot mode is not supported on Server $($connection.IP)"
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
    $result = $serverConnection | Get-HPBIOSBootMode
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}
# Get the valid value list fro each parameter
$parameterMetaData = $(Get-Command -Name Set-HPBIOSBootMode).Parameters
$bootModeValidValues = $($parameterMetaData["BootMode"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""
if($BootMode -eq "")
{
    $BootMode = Read-Host "Enter Boot Mode [Accepted values : ($($bootModeValidValues -join ","))]."
    #$BootMode = $BootMode -replace '\s+'
    Write-Host ""
}

$inputBootModeList =  ($BootMode.Trim().Split(','))

if($inputBootModeList.Count -eq 0)
{
    Write-Host "You have not enterd boot mode"
    Write-Host "Exit....."
    exit
}

[array]$BootModeToset = @()
for($i = 0;$i -lt $ListOfConnection.Count ;$i++)
{
    if($($bootModeValidValues | where {$_ -eq $inputBootModeList[$i]}) -ne $null)
    {
        $BootModeToset += $inputBootModeList[$i]
    }
    else
    {
        Write-Host "Invalid Boot mode" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing Boot mode....." -ForegroundColor Green

$failureCount = 0
if($ListOfConnection.Count -eq 1)
{
    $result = $ListOfConnection[0] | Set-HPBIOSBootMode -BootMode $BootModeToset[0]
    if($result.StatusType -eq "Error")
    {
        Write-Host ""
        Write-Host "Boot mode Cannot be changed"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.StatusMessage)"
        $failureCount++
    }
}
else
{
    if($BootModeToset.Count -eq 1)
    {
        $resultList = $ListOfConnection | Set-HPBIOSBootMode -BootMode $BootModeToset[0]
    }
    else
    {
        $resultList = $ListOfConnection | Set-HPBIOSBootMode -BootMode $BootModeToset
    }
        
        foreach($result in $resultList)
        {
        
        if($result.StatusType -eq "Error")
        {
            Write-Host ""
            Write-Host "Boot mode Cannot be changed"
            Write-Host "Server : $($result.IP)"
            Write-Host "Error : $($result.StatusMessage)"
            $failureCount++
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
        $result = $serverConnection | Get-HPBIOSBootMode
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