########################################################
#Configuring the BIOS Power On Password
###################################################----#

<#
.Synopsis
    This script allows user to sets the PowerOnPassword of HPE Proliant Gen 9 servers. 

.DESCRIPTION
    This script allows user to set the PowerOnPassword. A new PowerOn password can be set,an existing PowerOn password 
    can be modified or the PowerOn password can be cleared/removed or reset.

.EXAMPLE
    ConfigurePoweOnPassword.ps1
    This mode of execution of script will prompt for 
    
    Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
    
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    OldPassword :- it will prompt for current password to be entered if any.
    
    NewPassword :- it will prompt to enter a new password.

.EXAMPLE
    ConfigurePoweOnPassword.ps1 -Address "10.20.30.40,10.25.35.45" -Credential $UserCredential 

    This mode of script have input parameter for Address
    
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user credential.#In case of multiple servers use same credential for all the servers
    
    OldPassword :- it will prompt for current password to be entered if any.
    
    NewPassword :- it will prompt to enter a new password.  

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential 

.OUTPUTS
    None (by default)

.LINK
.LINK   
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential #In case of multiple servers it use same credential for all the servers
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
Write-Host "******Script execution started******" -ForegroundColor Green
Write-Host ""
#Decribe what script does to the user

Write-Host "This script demonstrate how to set a new PowerOn password. A new PowerOn password can be set,an existing PowerOn password can be modified or the PowerOn password can be cleared/removed or reset."
Write-Host ""

#dont show error in script

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

if($Address -eq "")
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}
    
[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)"
    Write-Host ""
    Write-Host "Exit ..."
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
    
    #Retry connection if it is failed because of invalid certificate with -DisableCertificateAuthentication switch parameter
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
            Write-Host "BIOS PowerOn Password is not supported on Server $($connection.IP)"
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
    Write-Host "Exit.."
    Write-Host ""
    exit
}

# Take user input for PowerOnPassword

[array]$OldPowerOnPassword=@()
[array]$NewPowerOnPassword=@()
for($i=0 ;$i -lt $ListOfConnection.Count;$i++)
{
    Write-Host ("Enter password for server {0}" -f $ListofConnection[$i].IP)
    Write-Host ""
    $OldPowerOnPassword +=Read-Host "Enter the current\old password to modify the PowerOn password or empty value (Press Enter) to set a new PowerOn password"
    Write-Host ""
    $NewPowerOnPassword +=Read-Host "Enter new power on password to be set"
    Write-Host ""
    if($OldPowerOnPassword[$i] -eq "" -and $NewPowerOnPassword[$i] -eq "")
    {
        Write-Host "Invalid Input.Both old and new password cannot be empty"
        Write-Host "Exit....."
        exit
    }
}

if($NewPowerOnPassword.Count -lt 0)
{
    Write-Host "You have not entered New PowerOnPassword"
    Write-Host "Exit....."
    exit
}

Write-Host "Configuring the PowerOnPassword....." -ForegroundColor Green
Write-Host " "

$failureCount = 0
for($i=0; $i -lt $ListOfConnection.Count ;$i++)
{
    $result = $ListOfConnection[$i] | Set-HPEBIOSPowerOnPassword -OldPowerOnPassword $OldPowerOnPassword[$i].ToString() -NewPowerOnPassword $NewPowerOnPassword[$i].ToString()
              
    if($result.Status -eq "Information")
    {
        $result
        $serverRestart = Reset-HPiLOServer -Server $($ListOfConnection[$i].IP) -Credential $Credential -DisableCertificateAuthentication
        if($serverRestart.STATUS_MESSAGE -contains "Server being reset.")
        {
                Write-Host "Server $($ListOfConnection[$i].IP) being reset....." -ForegroundColor Green
                Write-Host ""
        }
    }
    if($result.Status -eq "Error")
    {
        Write-Host ""
        Write-Host "PowerOnPassword cannot be set"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.StatusInfo)"
		Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
        $failureCount++
    }
}
   
if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "PowerOnPassword set successfully" -ForegroundColor Green
    Write-Host ""
}

Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "******Script execution completed******" -ForegroundColor Green
exit





