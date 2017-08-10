<#
.Synopsis
    This script allows user to get Memory information of HPE Proliant Gen7, Gen8 and Gen9 servers through iLO

.DESCRIPTION
    This script allows user to get Memory information.

.EXAMPLE
    Using_Get-HPiLOMemoryInfo.ps1
    This mode of exetion of script will prompt for 
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    Credential :- prompts for username and password. In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials

.EXAMPLE
    Using_Get-HPiLOMemoryInfo.ps1 -Address "10.20.30.40,10.20.30.1" -Credential $userCredential
    This mode of script have input parameter for Address Credential
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- Use this parameter to sepcify user credential.

.NOTES
    Company : Hewlett Packard Enterprise
    Version : 1.5.0.0
    
.INPUTS
    Inputs to this script file
    Address
    Credential

.OUTPUTS
    None (by default)

.LINK
    
    http://www.hpe.com/servers/powershell
#>

#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential # all server should have same ceredntial (in case of multiple addresses)
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

Write-Host "This script allows user to retrieve memory information of the server.`n"

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
    $Address = Read-Host "`nEnter Server address (IP or Hostname). Multiple entries separated by comma(,)"
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
    $Credential = Get-Credential -Message "Enter username and Password"
}

$failureCount = 0

#  Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

Write-Host ("`nThis script will do a serial processing of the input IP's") -ForegroundColor Green

for($i=0;$i -lt $ListOfAddress.Count; $i++)
{
    Write-Host ("`nMemory Info for the server - $($ListOfAddress[$i])") -ForegroundColor Yellow
    $result = Get-HPiLOMemoryInfo -Server $ListOfAddress[$i] -Credential $Credential -DisableCertificateAuthentication
    $result | fl

    if($result -ne $null -and $result.STATUS_TYPE -ne "Error")
    {
        if($result.MEMORY_COMPONENTS -eq $null)
        {
            Write-Host ("`nAdvanced Memory Protection details for the server - $($ListOfAddress[$i])") -ForegroundColor Yellow
            Write-Host ("`n`$result.ADVANCED_MEMORY_PROTECTION | ft **")
            $result.ADVANCED_MEMORY_PROTECTION | ft **
        
            for($a=0; $a -lt $result.MEMORY_DETAILS.Count; $a++)
            {
                Write-Host ("`nMemory details of CPU $($a+1) for the server - $($ListOfAddress[$i])") -ForegroundColor Yellow
                Write-Host ("`n`$result.MEMORY_DETAILS[$($a)].MemoryData | ft **")
                $result.MEMORY_DETAILS[$a].MemoryData | ft **
            }
            for($a=0; $a -lt $result.MEMORY_DETAILS_SUMMARY.Count; $a++)
            {
                Write-Host ("`nMemory details summary of CPU $($a+1) for the server - $($ListOfAddress[$i])") -ForegroundColor Yellow
                Write-Host ("`n`$result.MEMORY_DETAILS[$($a+1)].MemoryData | ft **")
                $result.MEMORY_DETAILS[$a].MemoryData | ft **
            }
        }
        else
        {
            Write-Host ("`nMemory components of CPU for the server - $($ListOfAddress[$i])") -ForegroundColor Yellow
            Write-Host ("`n`$result.MEMORY_COMPONENTS | ft **")
            $result.MEMORY_COMPONENTS | ft **
        }
        Write-host "`nMemory Info retrieved successfully" -ForegroundColor Green
        Write-Host "Server : $($result.IP)"
        Write-Host "Status : $($result.STATUS_MESSAGE)"
    }
    else
    {
        Write-Host "`nMemory Info Cannot be retrieved"
        Write-Host "Server : $($ListOfAddress[$i])"
        $failureCount++
    }
}


$ErrorActionPreference = "Continue"
$WarningPreference ="Continue"
Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
exit