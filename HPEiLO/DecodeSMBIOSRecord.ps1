<#
.Synopsis
    This script allows user to read the SMBIOS record and displays some of the record values.

.DESCRIPTION
    This script decodes the SMBIOS records that is encoded in base64 format and displays some of the record values.
     

.EXAMPLE
    DecodeSMBIOSRecord.ps1
    This mode of execution of script will prompt for 
    Address    :- accept IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    Credential :-Use this parameter to sepcify user credential.In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials

.EXAMPLE
    DecodeSMBIOSRecord.ps1 -Address "10.20.30.40,10.20.30.1" -Credential $Credential

    This mode of script have input parameter for Address,Username, Password and location
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :-Use this parameter to sepcify user credential.In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials

.NOTES
    Company : Hewlett Packard Enterprise
    Version : 1.4.0.0
    
.INPUTS
    Inputs to this script file
    Address
    Username
    Password
    Location

.OUTPUTS
    None (by default)

.LINK
    
    http://www.hpe.com/servers/powershell
#>

#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential 
    
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
        Write-Host "`nServer $serverAddress is not reachable. Please check network connectivity"
        $pingFailureCount ++
       }
}

if($pingFailureCount -eq $ListOfAddress.Count)
{
    Write-Host "`nServer(s) are not reachable please check network conectivity"
    exit
}
return $PingedServerList
}
#clear host
Clear-Host

# script execution started
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "This script displays some of the decoded SMBIOS records that is encoded in base64 format.`n"

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference ="SilentlyContinue"
#check powershell support
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "3")
{
    Write-Host "Your powershell version : $($PSVersionTable.PSVersion) is valid to execute this script`n"
}
else
{
    Write-Host "This script required PowerSehll 3 or above"
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
        Write-Host "`nHPiLOCmdlets module cannot be loaded. Please fix the problem and try again`n"
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstallediLOModule  =  Get-Module -Name "HPiLOCmdlets"
    Write-Host "HPiLOCmdlets Module Version : $($InstallediLOModule.Version) is installed on your machine.`n"
}

# check for IP(s) or Hostname(s) Input. if not available prompt for Input

if($Address -eq "")
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
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

foreach($IPAddress in $ListOfAddress)
{
    
    $result = Get-HPiLOHostData -Server $IPAddress -Credential $Credential -DisableCertificateAuthentication
    Write-Host ("`nDecoding the SMBIOS Record for the server {0}" -f ($IPAddress)) -ForegroundColor Yellow
    $record= $result | Read-HPiLOSMBIOSRecord
     foreach ($field in $record) {
     
     #if ([string]::IsNullOrEmpty($field.BIOS_VERSION) -or [string]::IsNullOrEmpty($field.PRODUCT_NAME) -or [string]::IsNullOrEmpty($field.SERIAL_NUMBER) -or [string]::IsNullOrEmpty($field.PROCESSOR_MANUFACTURER) -or [string]::IsNullOrEmpty($field.BOOT_UP_STATE) -or [string]::IsNullOrEmpty($field.POWER_SUPPLY_STATE) -or [string]::IsNullOrEmpty($field.THERMAL_STATE)) {
     if(-Not [string]::IsNullOrEmpty($field.BIOS_VERSION))
     {
        $name="BIOS_VERSION";$value=$field.BIOS_VERSION
        Write-Host $("SMBIOS Record Type = " + $field.SMBIOS_RECORD_TYPE + ", " + $name + " = " + $value)
     }
     if(-Not [string]::IsNullOrEmpty($field.PRODUCT_NAME))
     {
        $name="PRODUCT_NAME";$value=$field.PRODUCT_NAME
        Write-Host $("SMBIOS Record Type = " + $field.SMBIOS_RECORD_TYPE + ", " + $name + " = " + $value)
     }
     if(-Not [string]::IsNullOrEmpty($field.SERIAL_NUMBER))
     {
        $name="SERIAL_NUMBER";$value=$field.SERIAL_NUMBER
        Write-Host $("SMBIOS Record Type = " + $field.SMBIOS_RECORD_TYPE + ", " + $name + " = " + $value)
     }
     if(-Not [string]::IsNullOrEmpty($field.BOOT_UP_STATE))
     {
        $name="BOOT_UP_STATE";$value=$field.BOOT_UP_STATE
        Write-Host $("SMBIOS Record Type = " + $field.SMBIOS_RECORD_TYPE + ", " + $name + " = " + $value)
     }
     if(-Not [string]::IsNullOrEmpty($field.POWER_SUPPLY_STATE))
     {
        $name="POWER_SUPPLY_STATE";$value=$field.POWER_SUPPLY_STATE
        Write-Host $("SMBIOS Record Type = " + $field.SMBIOS_RECORD_TYPE + ", " + $name + " = " + $value)
     }
     if(-Not [string]::IsNullOrEmpty($field.THERMAL_STATE))
     {
        $name="THERMAL_STATE";$value=$field.THERMAL_STATE
        Write-Host $("SMBIOS Record Type = " + $field.SMBIOS_RECORD_TYPE + ", " + $name + " = " + $value)
        
     }
     
                }
 
       
}
$WarningPreference ="Continue"
$ErrorActionPreference = "Continue"
Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
exit