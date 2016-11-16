<#
.Synopsis
    This script allows user to executes any RIBCL command and return the RIBCL response. 

.DESCRIPTION
    This script allows user to enter the RIBCL command and returns RIBCL response as PSObject for read operations and does not return anything for write operations.
    -RIBCLCommand :- Use this option to input the RIBCL command. 

.EXAMPLE
    InvokeRIBCL.ps1 -RIBCLCommand $xml
    $xml = ([string](get-content " C:\Program Files\Hewlett-Packard\RIBCL_XML\Get_AHS_Status.xml")) 
    This mode of execution of script will prompt for 
    -Address    :- accpet IP(s) or Hostname(s). For multiple iLO IP(s) or Hostname(s) should be separated by comma(,)
    -Credential :- prompts for username and password. In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials
  
.EXAMPLE
    InvokeRIBCL.ps1 -Address "10.20.30.40,10.20.30.1" -Credential $Credential -RIBCLCommand $xml

    This mode of script have input parameter for Address,Username, Password and location
    -Address    :- accpet IP(s) or Hostname(s). For multiple iLO IP(s) or Hostname(s) should be separated by comma(,)
    -Credential :- prompts for username and password. In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials
    -RIBCLCommand :- Use this option to input the RIBCL command. 

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
    $RIBCLCommand
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

Write-Host "`nThis script allows user to executes any RIBCL command and get the RIBCL response"

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference ="SilentlyContinue"

#check powershell support
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "3")
{
    Write-Host "`nYour powershell version : $($PSVersionTable.PSVersion) is valid to execute this script"
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
    Write-Host "`nLoading module :  HPiLOCmdlets"
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

if($null -eq $RIBCLCommand)
{
    Write-Host "`nYou have not provided the RIBCL command"
    Write-Host "`nExit..."
    exit
}

#  Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

for($i=0 ;$i -lt $ListOfAddress.Count;$i++)
{
    $RIBCLCommand =$RIBCLCommand -replace '<!--[\s\S]*?-->',''
    if($ListOfAddress.Count -eq 1 -or $RIBCLCommand.Count -eq 1)
    {
        $result = Invoke-HPiLORIBCLCommand -Server $ListOfAddress -Credential $Credential -RIBCLCommand $RIBCLCommand  -DisableCertificateAuthentication
        $flag=$true
    }
    else
    {
        $result = Invoke-HPiLORIBCLCommand -Server $ListOfAddress[$i] -Credential $Credential -RIBCLCommand $RIBCLCommand[$i] -DisableCertificateAuthentication
    }
   
    if($null -ne $result)
    {
        $result
    }
    elseif($Error[0].ToString() -match "Invalid RIBCL file" -or $Error[0].ToString() -match "Current RIBCL command is not supported.\n Use Update-HPiLOiLOFirmware/Update-HPiLOServerFirmware/Install-HPiLOLanguagePack cmdlet for firmware upgrade/language pack installation")
    {
        $result = New-Object PSObject
        $result | Add-Member NoteProperty "IP" $result.IP
        $result | Add-Member NoteProperty "STATUS_TYPE" "Error"
        $result | Add-Member NoteProperty "STATUS_MESSAGE" $Error[0].ToString()
        $result
    }
    else
    {
        Write-Host "`nThe value has been set successfully"
    }
    if($flag)
    {
        break
    }
}

$ErrorActionPreference = "Continue"
$WarningPreference ="Continue"
Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
exit