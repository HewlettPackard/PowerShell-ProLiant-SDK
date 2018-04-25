<#
.Synopsis
    This script allows user to install the language pack on servers with iLO 4.

.DESCRIPTION
    This script allows user to install the language pack.
    location :- Use this option to set the location of the langugage pack. 

.EXAMPLE
    LanguagePackInstallation.ps1
    This mode of execution of script will prompt for 
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    Credential :- prompts for username and password. In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials
    location   :- file with extension .lpk.

.EXAMPLE
    LanguagePackInstallation.ps1 -Address "10.20.30.40,10.20.30.1" -Credential $Credential -Location "C:\Program Files\HewletPAckard\OA401-20130823-ja.lpk","C:\Program Files\HewletPAckard\OA401-20130823-ja.lpk"

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
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "This script allows user to Install the language pack on the server`n"

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference="SilentlyContinue"
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

Write-Host ("`nLanguages available for the server") -ForegroundColor Yellow
$result = Get-HPiLOLanguage -Server $ListOfAddress -Credential $Credential -DisableCertificateAuthentication
$result

if([string]::IsNullOrEmpty($Location))
{
    $Location = Read-Host "`nEnter language pack location"
}

$inputLocationList =  ($Location.Trim().Split(','))

if($inputLocationList.Count -eq 0)
{
    Write-Host "`nYou have not enterd location"
    Write-Host "Exit....."
    exit
}

Write-Host "`nInstalling the Language Pack. This might take some time" -ForegroundColor Green

$failureCount = 0

for($i=0;$i -lt $ListOfAddress.Count;$i++)
{
    $inputLocationList[$i]=$inputLocationList[$i].replace('"',"")
    if( -not (Test-Path $inputLocationList[$i] -PathType Leaf)){
                        $tmpObj = New-Object PSObject
                        $tmpObj | Add-Member NoteProperty "IP" $result.IP
                        $tmpObj | Add-Member NoteProperty "STATUS_TYPE" "Error"
                        $tmpObj | Add-Member NoteProperty "STATUS_MESSAGE" "Invalid image location."
                        $tmpObj
			}

       
    elseif(([System.IO.Path]::GetExtension($inputLocationList[$i]) -ne ".lpk")){
                        $tmpObj = New-Object PSObject
                        $tmpObj | Add-Member NoteProperty "IP" $result.IP
                        $tmpObj | Add-Member NoteProperty "STATUS_TYPE" "Error"
                        $tmpObj | Add-Member NoteProperty "STATUS_MESSAGE" "Firmware image must be `"lpk`" file"
                        $tmpObj
                        }
    else
    {    
        $result= Install-HPiLOLanguagePack -Server $ListOfAddress[$i] -Credential $Credential -Location $inputLocationList[$i] -DisableCertificateAuthentication
        Start-Sleep -Seconds 120
    }

    if($result.STATUS_TYPE -eq "Error")
    {
        Write-Host "`nLanguage pack installation failed`n"
        $result
        $failureCount++
    }
    else
    {
        Write-host "`nLanguage pack successfully installed" -ForegroundColor Green
    }
    
}

if($failureCount -ne $ListOfAddress.Count)
{
    Write-Host ("`nLanguages available for the server") -ForegroundColor Yellow
    $result = Get-HPiLOLanguage -Server $ListOfAddress -Credential $Credential -DisableCertificateAuthentication
    $result

}
$ErrorActionPreference = "Continue"
$WarningPreference ="Continue"
Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
exit