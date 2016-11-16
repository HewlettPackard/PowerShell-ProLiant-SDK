<#
.Synopsis
    This script allows user to add/Remove Federation Group with full priviliges,get/set the federation group and multicast details.

.DESCRIPTION
    This script allows user to to add/Remove Federation Group with full priviliges,get/set the federation group and multicast details.
    GroupName :- Use this option to add the federation group. 
    GroupKey:- Use this option to add the federation group key.
    NewGroupName:- Use this option to change the existing federation group name.
    AdminPriv:- Use this option to Enable or disable the administrator priviliges.
    MulticastScope:- Use this option to set the multicastscope to Site,Link or organisation
    DiscoveryAuthentication :- Use this option to enable or disable the discovery authentication.

.EXAMPLE
    ConfigureFederationGroupSettings.ps1
    This mode of exetion of script will prompt for 
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    GroupName :- it will prompt for GroupName to add the federation group. 
    GroupKey:- it will prompt for GroupKey to add the federation group key.
    NewGroupName:- it will prompt for NewGroupName to change the existing federation group name.
    AdminPriv:- it will prompt for AdminPriviliges to Enable or disable the administrator priviliges.
    MulticastScope:- it will prompt for MulticastScope to set the multicastscope to Site,Link or organisation
    DiscoveryAuthentication :- it will prompt for DiscoverAuthentication to enable or disable the discovery authentication.

.EXAMPLE
    ConfigureFederationGroupSettings.ps1 -Address "10.20.30.40" -Credential $userCredential -GroupName $GroupName -GroupKey $GroupKey -NewGroupName $NewGroupName -AdminPriv $AdminPriv -MulticastScope $MulticastScope -DiscoveryAuthentication $DiscoveryAuthentication

    This mode of script have input parameter for Address Credential and BootMode
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- Use this parameter to sepcify user credential.
    -GroupName :- Use this option to add the federation group. 
    -GroupKey:- Use this option to add the federation group key.
    -NewGroupName:- Use this option to change the existing federation group name.
    -AdminPriv:- Use this option to Enable or disable the administrator priviliges.
    -MulticastScope:- Use this option to set the multicastscope to Site,Link or organisation
    -DiscoveryAuthentication :- Use this option to enable or disable the discovery authentication.

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 1.4.0.0
        
.INPUTS
    Inputs to this script file
    Address
    Credential
    GroupName
    GroupKey
    NewGroupName
    AdminPriv
    MulticastScope
    DiscoveryAuthentication

.OUTPUTS
    None (by default)

.LINK
    http://www.hpe.com/servers/powershell
#>

#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential,
    [String]$GroupName,  
    [String]$GroupKey,
    [String]$NewGroupName,
    [String]$AdminPriv,
    [String]$MulticastScope,
    [String]$DiscoveryAuthentication
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

Write-Host "This script allows user to get the federation group and federation multicast settings, configure them and add/remove new group to the federation group.`n"

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
if([string]::IsNullOrEmpty($GroupName))
{
    $GroupName = Read-Host "Enter New Federation group to be added"

}
if([string]::IsNullOrEmpty($Groupkey))
{
    $Groupkey = Read-Host "`nEnter group key to be added for the group name specified"

}
#  Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

# create connection object
for($i=0;$i -lt $ListOfAddress.Count;$i++)
{

    Write-Host ("`nAdding Federation group to the server {0}" -f $ListOfAddress[$i]) -ForegroundColor Yellow
    $result= Add-HPiLOFederationGroup -Server $ListOfAddress[$i] -Credential $Credential -GroupName $GroupName -GroupKey $Groupkey -AdminPriv Enable -RemoteConsolePriv Enable -ConfigiLOPriv Enable -LoginPriv Enable -ResetServerPriv Enable -VirtualMediaPriv Enable -DisableCertificateAuthentication
    if($result.STATUS_TYPE -eq "Error")
    {
        Write-Host "`nFailed to add the federation group"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.STATUS_MESSAGE)"
    }
    else
    {
        Write-Host ("`nFederation group added successfully") -ForegroundColor Green
    }
    Write-Host ("`nGetting Federation group details of the server {0}" -f ($IPAddress)) -ForegroundColor Yellow
    $result= Get-HPiLOFederationGroup -Server $ListOfAddress[$i] -Credential $Credential -DisableCertificateAuthentication
    $result
   
    Write-Host ("`nGetting Federation multicast details of the server {0}" -f ($IPAddress)) -ForegroundColor Yellow
    $result= Get-HPiLOFederationMulticast -Server $ListOfAddress[$i] -Credential $Credential  -DisableCertificateAuthentication
    $result
}

$parameterMetaData = $(Get-Command -Name Set-HPiLOFederationGroup).Parameters
$parameterValidValues = $($parameterMetaData["AdminPriv"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

#Prompt for User input if it is not given as script  parameter 
Write-Host "`nInput Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
if([string]::IsNullOrEmpty($NewGroupName))
{
    $NewGroupName = Read-Host "Enter new Federation group name to modify the added group"
}

if([string]::IsNullOrEmpty($AdminPriv))
{
    $AdminPriv = Read-Host "`nEnter Admin priviliges[Accepted values : ($($parameterValidValues -join ","))]."
}
$inputGroupName =  ($NewGroupName.Trim().Split(','))
$inputAdminPriv =  ($AdminPriv.Trim().Split(','))

$parameterMetaData = $(Get-Command -Name Set-HPiLOFederationMulticast).Parameters
$parameterMulticastValues = $($parameterMetaData["MulticastScope"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$parameterFederationAuthentication = $($parameterMetaData["DiscoveryAuthentication"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

if([string]::IsNullOrEmpty($MulticastScope))
{
    $MulticastScope = Read-Host "Enter MulticastScope value for setting FederationMulticast[Accepted values : ($($parameterMulticastValues -join ","))]."
}

if([string]::IsNullOrEmpty($DiscoveryAuthentication))
{
    $DiscoveryAuthentication = Read-Host "`nEnter DiscoveryAuthentication value for setting FederationMulticast[Accepted values : ($($parameterFederationAuthentication -join ","))]."
}
$inputMulticastScope =  ($MulticastScope.Trim().Split(','))
$inputDiscoveryAuthentication =($DiscoveryAuthentication.Trim().Split(','))

for($i = 0;$i -lt $ListOfAddress.Count ;$i++)
{
    if(-not(($($parameterValidValues | where {$_ -eq $inputAdminPriv[$i]}) -ne $null) -or ($($parameterMulticastValues | where {$_ -eq $inputMulticastScope[$i]}) -ne $null) -or ($($parameterFederationAuthentication | where {$_ -eq $inputFederationAuthentication[$i]}) -ne $null)))
    {
        Write-Host "`nInvalid parameter value" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing Federation group name and admin privileges and Federation multicast settings....." -ForegroundColor Green

$failureCount = 0
for($i=0;$i -lt $ListOfAddress.Count;$i++)
{
    if($ListOfAddress.Count -eq 1)
    {

       $result= Set-HPiLOFederationGroup -Server $ListOfAddress[$i] -Credential $Credential -GroupName $GroupName -NewGroupName $inputGroupName[$i] -AdminPriv $inputAdminPriv[$i] -DisableCertificateAuthentication
       $resMulticastSettings=Set-HPiLOFederationMulticast -Server $ListOfAddress[$i] -Credential $Credential -MulticastScope $inputMulticastScope[$i]  -DiscoveryAuthentication $inputDiscoveryAuthentication[$i] -DisableCertificateAuthentication
    }
    else
    {
        $result= Set-HPiLOFederationGroup -Server $ListOfAddress[$i] -Credential $Credential -GroupName $GroupName[$i] -NewGroupName $inputGroupName[$i] -Admin $inputAdminPriv[$i] -DisableCertificateAuthentication
        $resMulticastSettings=Set-HPiLOFederationMulticast -Server $ListOfAddress[$i] -Credential $Credential -MulticastScope $inputMulticastScope[$i] -FederationAuthentication $inputFederationAuthentication[$i] -DiscoveryAuthentication $inputDiscoveryAuthentication[$i] -DisableCertificateAuthentication
    }
    if($result.STATUS_TYPE -eq "Error" -or $resMulticastSettings.STATUS_TYPE -eq "Error" -or $result.STATUS_TYPE -eq "Warning" -or $resMulticastSettings.STATUS_TYPE -eq "Warning")
    {
        if($result.STATUS_TYPE -eq "Error")
        {
            Write-Host "`nSet-HPiloFederationGroup failed to execute"
        }
        elseif($resMulticastSettings.STATUS_TYPE -eq "Error")
        {
            Write-Host "`nSet-HPiloFederationMulticast failed to execute"
        }
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.STATUS_MESSAGE)"
        $failureCount++
    }
    else
    {
        Write-host "`nValue changed successfully" -ForegroundColor Green

    }
}

if($failureCount -ne $ListOfAddress.Count)
{
    for($i=0;$i -lt $ListOfAddress.Count;$i++)
    {
        Write-Host ("`nGetting Federation group details of the server {0}" -f ($ListOfAddress[$i])) -ForegroundColor Yellow
        $result= Get-HPiLOFederationGroup -Server $ListOfAddress[$i] -Credential $Credential -ListAll -DisableCertificateAuthentication
        $result

        Write-Host ("`nGetting Federation multicast details of the server {0}" -f ($IPAddress)) -ForegroundColor Yellow
        $result= Get-HPiLOFederationMulticast -Server $ListOfAddress[$i] -Credential $Credential  -DisableCertificateAuthentication
        $result

        Write-Host ("`nRemoving Federation group from the server {0}" -f $ListOfAddress[$i]) -ForegroundColor Yellow
        $result= Remove-HPiLOFederationGroup -Server $ListOfAddress[$i] -Credential $Credential -GroupName $inputGroupName[$i] -DisableCertificateAuthentication
        if($result.STATUS_TYPE -eq "Error")
        {
            Write-Host "`nFailed to remove the federation group"
            Write-Host "Server : $($result.IP)"
            Write-Host "Error : $($result.STATUS_MESSAGE)"
        }
        else
        {
            Write-Host ("`nGetting Federation group details of the server {0}" -f ($ListOfAddress[$i])) -ForegroundColor Yellow
            $result= Get-HPiLOFederationGroup -Server $ListOfAddress[$i] -Credential $Credential -DisableCertificateAuthentication
            $result
        }
    }
}
$ErrorActionPreference = "Continue"
$WarningPreference ="Continue"
Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
exit