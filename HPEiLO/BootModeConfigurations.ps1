<#
.Synopsis
    This script allows user to change boot mode (UEFI / Legacy) of HPE Proliant Gen 9 servers through iLO

.DESCRIPTION
    This script allows user to change the boot mode.
    BootMode :- Use this option to set the boot mode for the system through iLO. HP ProLiant Gen9 servers provide two boot mode 
    configurations: UEFI Mode and Legacy BIOS Mode.

.EXAMPLE
    ConfigureBootMode.ps1
    This mode of exetion of script will prompt for 
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    Credential :- prompts for username and password. In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials
    BootMode   :- Accepted values are Legacy_BIOS_Mode or UEFI_Mode.For multiple servers values should be separated by comma(,)

.EXAMPLE
    ConfigureBootMode.ps1 -Address "10.20.30.40,10.20.30.1" -Credential $userCredential -BootMode "UEFI,legacy"
    This mode of script have input parameter for Address Credential and BootMode
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- Use this parameter to sepcify user credential.
    -BootMode :- Use this Parameter to specify boot mode. Accepted values are Legacy_BIOS_Mode or UEFI_Mode

.NOTES
    Company : Hewlett Packard Enterprise
    Version : 1.4.0.0
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    BootMode

.OUTPUTS
    None (by default)

.LINK
    
    http://www.hpe.com/servers/powershell
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
            $PingedServerList += $serverAddress
           }
           else
           {
            Write-Host "`nServer $serverAddress is not reachable. Please check network connectivity"
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
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "This script allows user to change boot mode.`n"

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference ="SilentlyContinue"
#check powershell support
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "3")
{
    Write-Host "Your powershell version : $($PSVersionTable.PSVersion) is valid to execute this script"
}
else
{
    Write-Host "`nThis script required PowerSehll 3 or above"
    Write-Host "Current installed PowerShell version is $($PSVersionTable.PSVersion)"
    Write-Host "Please Update PowerShell version`n"
    Write-Host "Exit...`n"
    exit
}

#Load HPiLOCmdlets module
$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPiLOCmdlets"))
{
    Write-Host "Loading module :  HPiLOCmdlets"
    Import-Module HPiLOCmdlets
    if(($(Get-Module -Name "HPiLOCmdlets")  -eq $null))
    {
        Write-Host "`nHPiLOCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstallediLOModule  =  Get-Module -Name "HPiLOCmdlets"
    Write-Host "`nHPiLOCmdlets Module Version : $($InstallediLOModule.Version) is installed on your machine."
}

# check for IP(s) or Hostname(s) Input. if not available prompt for Input
if($Address -eq "")
{
    $Address = Read-Host "`nEnter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
    Write-Host ""
}
    
[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "`nYou have not entered IP(s) or Hostname(s)`n"
    Write-Host "Exit..."
    exit
}

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password(Use same credential for multiple servers)"
}

#  Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

Write-Host ("`nSupported Boot Mode for the server(s)") -ForegroundColor Yellow
$result= Get-HPiLOSupportedBootMode -Server $ListOfAddress -Credential $Credential -DisableCertificateAuthentication
$result 

Write-Host ("`nCurrent Boot Mode for the server(s)") -ForegroundColor Yellow
$result= Get-HPiLOCurrentBootMode -Server $ListOfAddress -Credential $Credential -DisableCertificateAuthentication
$result

Write-Host ("`nPending Boot Mode for the server(s)") -ForegroundColor Yellow
$result= Get-HPiLOPendingBootMode -Server $ListOfAddress -Credential $Credential -DisableCertificateAuthentication
$result

$parameterMetaData = $(Get-Command -Name Set-HPiLOPendingBootMode).Parameters
$bootModeValidValues = $($parameterMetaData["BootMode"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

#Prompt for User input if it is not given as script  parameter 
Write-Host "`nInput Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
if($BootMode -eq "")
{
    $BootMode = Read-Host "`nEnter Boot Mode [Accepted values : ($($bootModeValidValues -join ","))]."
}

$inputBootModeList =  ($BootMode.Trim().Split(','))

if($inputBootModeList.Count -eq 0)
{
    Write-Host "`nYou have not enterd boot mode"
    Write-Host "`nExit....."
    exit
}

Write-Host "`nChanging Boot mode....." -ForegroundColor Green

$failureCount = 0

for($i=0;$i -lt $ListOfAddress.Count;$i++)
{
    if($ListOfAddress.Count -eq 1)
    {
        $result= Set-HPiLOPendingBootMode -Server $ListOfAddress[$i] -Credential $Credential -BootMode $BootModeToset -DisableCertificateAuthentication
    }
    else
    {
        $result= Set-HPiLOPendingBootMode -Server $ListOfAddress[$i] -Credential $Credential -BootMode $BootModeToset[$i] -DisableCertificateAuthentication
    }
    if($result.STATUS_TYPE -eq "Error")
    {
        Write-Host "`nBoot mode Cannot be changed"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.STATUS_MESSAGE)"
        $failureCount++
    }
    else
    {
    Write-host "`nBoot mode changed successfully" -ForegroundColor Green
    Write-Host "Server : $($result.IP)"
    Write-Host "WARNING : $($result.STATUS_MESSAGE)"
    }
}

if($failureCount -ne $ListOfAddress.Count)
{
        Write-Host ("`nPending Boot Mode for the server(s)") -ForegroundColor Yellow
        $result= Get-HPiLOPendingBootMode -Server $ListOfAddress -Credential $Credential -DisableCertificateAuthentication
        $result
}
$ErrorActionPreference = "Continue"
$WarningPreference ="Continue"
Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
exit