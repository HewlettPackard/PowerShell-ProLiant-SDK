########################################################
#Resetting BIOS Administrator Password
###################################################----#

<#
.Synopsis
    This script allows user to reset or remove the BIOS administrator password. 

.DESCRIPTION
    This script allows user to reset or remove the BIOS administrator password.

.EXAMPLE
    ResetBIOSAdminPassword.ps1
    This mode of execution of script will prompt for 
    Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    AdminPassword :- it will prompt to enter current AdminPassword that is already set for the server.

.EXAMPLE
    ResetBIOSAdminPassword.ps1 -Address "10.20.30.40,10.25.35.45" -AdminPassword "test123,admin123"

    This mode of script have input parameter for Address and AdminPassword
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- Use this parameter to specify user credential.
    -AdminPassword :- Use this Parameter to specify current AdminPassword.
    
.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 1.1.0.0
    Date    : 8/8/2016
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    AdminPassword

.OUTPUTS
    None (by default)

.LINK
    
    http://www8.hp.com/in/en/products/server-software/product-detail.html?oid=5440657
#>



#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # all server should have same ceredntial (in case of multiple addresses)
    [String]$AdminPassword  # AdminPassword
    
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
         Write-Host "Server $serverAddress pinged successfully."
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

Write-Host "This script demonstrate how to reset or remove the BIOS administrator password that is already set.The Parameters it accepts are\n"
Write-Host "AdminPassword :- The current BIOS administrator password that is set for the server"
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
    $Credential = Get-Credential -Message "Enter username and password(Use same credential for multiple servers)"
    Write-Host ""
}

#  Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

# create connection object
[array]$ListOfConnection = @()
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow

if($AdminPassword -eq "")
{
    $AdminPassword = Read-Host "Enter the current BIOS administrator password"
    Write-Host ""
}

$inputAdminPasswordList =  ($AdminPassword.Trim().Split(','))

if($inputAdminPasswordList.Count -eq 0)
{
    Write-Host "You have not entered the administrator password"
    Write-Host "Exit..."
    exit
}
for($i=0;$i -lt $ListOfAddress.Count; $i++)
{
    Write-Host ""
    Write-Host ("Connecting to server  : {0}" -f $ListOfAddress[$i])
    Write-Host ""
    
    $connection = Connect-HPBIOS -IP $ListOfAddress[$i] -Credential $Credential -AdminPassword $inputAdminPasswordList[$i].ToString()

    if($Error[0] -match "iLO SSL Certificate is not valid")
    {
       $connection = Connect-HPBIOS -IP $ListOfAddress[$i] -Credential $Credential -DisableCertificateAuthentication -AdminPassword $inputAdminPasswordList[$i].ToString()
    } 

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host ("Connection established to the server {0}") -f $ListOfAddress[$i] -ForegroundColor Green
        $connection
        if($connection.ConnectionInfo.ServerPlatformNumber -eq 9)
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "BIOS administrator password is not supported on Server $($connection.IP)"
        }
    }
    else
    {
        Write-Host "Connection cannot be eastablished to the server : $ListOfAddress[$i]" -ForegroundColor Red
    }
} 


if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit..."
    Write-Host ""
    exit
}

#Prompt for  user input for AdminPassword

Write-Host "Resetting the AdminPassword....." -ForegroundColor Green
Write-Host " "

$failureCount = 0
for($i=0; $i -lt $ListOfConnection.Count ;$i++)
{
    $result = $ListOfConnection[$i] | Reset-HPBIOSAdminPassword -AdminPassword $inputAdminPasswordList[$i]
              
    if($result.StatusType -eq "Warning")
    {
        $result
        $serverRestart = Reset-HPiLOServer -Server $($ListOfConnection[$i].IP) -Credential $Credential -DisableCertificateAuthentication
        if($serverRestart.STATUS_MESSAGE -contains "Server being reset.")
        {
                Write-Host "Server $($ListOfConnection[$i].IP) being reset....." -ForegroundColor Green
                Write-Host " "
                Write-Host "Please wait for some time until server is completly up" -ForegroundColor Yellow
                Write-Host " "
        }
    }
    if($result.StatusType -eq "Error")
    {
        Write-Host ""
        Write-Host "BIOS administrator password cannot be Reset"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.StatusMessage)"
        $failureCount++
    }
}

if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "BIOS administrator password reset successfully" -ForegroundColor Green
    Write-Host ""
}

Disconnect-HPBIOSAllConnection    
$ErrorActionPreference = "Continue"
Write-Host "******Script execution completed******" -ForegroundColor Green
exit





