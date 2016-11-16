<#
.Synopsis
    This script allows user to update the ROM/CPLD/Power PIC firmware on servers with iLO 4.

.DESCRIPTION
    This script allows user to update the ROM/CPLD/Power PIC firmware on servers with iLO 4.
    location :- Use this option to set the location of the firmware. 

.EXAMPLE
    ServerFirmwareUpdate.ps1
    This mode of execution of script will prompt for 
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    Credential :- prompts for username and password. In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials
    location   :- file with extension .full/.flash/.vme/.hex.

.EXAMPLE
    ServerFirmwareUpdate.ps1 -Address "10.20.30.40,10.20.30.40.1" -Credential $Credential -Location $location

    This mode of script have input parameter for Address,Username, Password and location
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- prompts for username and password. In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials
    -Location :- Use this parameter to specify the location.

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
    [PSCredential]$Credential,
    $Location  
    
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
Write-Host "`n****** Script execution started ******" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "`nThis script allows user to update the firmware of the server"

#$ErrorActionPreference = "SilentlyContinue"
$WarningPreference="SilentlyContinue"
#check powershell support
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "3")
{
    Write-Host "`nYour powershell version : $($PSVersionTable.PSVersion) is valid to execute this script`n"
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
        Write-Host "`nHPiLOCmdlets module cannot be loaded. Please fix the problem and try again`n"
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstallediLOModule  =  Get-Module -Name "HPiLOCmdlets"
    Write-Host "HPiLOCmdlets Module Version : $($InstallediLOModule.Version) is installed on your machine."
}

# check for IP(s) or Hostname(s) Input. if not available prompt for Input

if($Address -eq "")
{
    $Address = Read-Host "`nEnter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}
    
[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)`n"
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
    $result = Get-HPiLOFirmwareInfo -Server $IPAddress -Credential $Credential -DisableCertificateAuthentication
         
    Write-Host ("Current Firmware Version information for the server {0}" -f ($IPAddress)) -ForegroundColor Yellow
    if($null -ne $result)
    {
        $tmpObj = New-Object PSObject
        $tmpObj | Add-Member NoteProperty "IP" $result.IP
        $tmpObj | Add-Member NoteProperty "HOSTNAME" $result.Hostname
        $tmpObj | Add-Member NoteProperty "STATUS_TYPE" "OK"
        for($i=0;$i -lt $result.FirmwareInfo.Count ;$i++)
        {
            if($result.FirmwareInfo[$i].FIRMWARE_NAME -match "System ROM" -or $result.FirmwareInfo[$i].FIRMWARE_NAME -match "Redundant System ROM" -or $result.FirmwareInfo[$i].FIRMWARE_NAME -match "Power Management Controller Firmware" -or $result.FirmwareInfo[$i].FIRMWARE_NAME -match "System Programmable Logic Device")
            {
                $tmpObj | Add-Member NoteProperty $result.FirmwareInfo[$i].FIRMWARE_NAME $result.FirmwareInfo[$i].FIRMWARE_VERSION
            }
        }
        $tmpObj
    }
    else
    {
        Write-Host "`nUnable to retrieve Server Firmware information"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.STATUS_MESSAGE)"
    }
}

if([string]::IsNullOrEmpty($Location))
{
    $Location = Read-Host "`nEnter firmware file location"
}

$inputLocationList =  ($Location.Trim().Split(','))

if($inputLocationList.Count -eq 0)
{
    Write-Host "You have not enterd location"
    Write-Host "Exit....."
    exit
}

$failureCount = 0

for($i=0;$i -lt $ListOfAddress.Count;$i++)
{
      
    $inputLocationList[$i]=$inputLocationList[$i].replace('"',"")
    $Extension=[System.IO.Path]::GetExtension($inputLocationList[$i])

    if( -not (Test-Path $inputLocationList[$i] -PathType Leaf)){
				        $tmpObj = New-Object PSObject
                        $tmpObj | Add-Member NoteProperty "IP" $result.IP
                        $tmpObj | Add-Member NoteProperty "STATUS_TYPE" "ERROR"
                        $tmpObj | Add-Member NoteProperty "STATUS_MESSAGE" "Invalid image location."
                        $tmpObj
    }
    
    elseif(($Extension -eq ".full" -or $Extension -eq ".flash" -or $Extension -eq ".vme" -or $Extension -eq ".hex"))
    {
        Write-Host ("`nFirmware Upgrade for server {0} In Progress, this might take some time" -f $ListOfAddress[$i]) -ForegroundColor Green
        $result= Update-HPiLOServerFirmware -Server $ListOfAddress[$i] -Credential $Credential -Location $inputLocationList[$i] -DisableCertificateAuthentication
        $result
    }
    else
    {
                        $tmpObj = New-Object PSObject
                        $tmpObj | Add-Member NoteProperty "IP" $result.IP
                        $tmpObj | Add-Member NoteProperty "STATUS_TYPE" "ERROR"
                        $tmpObj | Add-Member NoteProperty "STATUS_MESSAGE" "Firmware image must be `".full/.flash/.vme/.hex`" file."
                        $tmpObj
    }
    
}
$ErrorActionPreference = "Continue"
$WarningPreference ="Continue"
Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
exit