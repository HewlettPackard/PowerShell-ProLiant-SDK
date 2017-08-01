########################################################
#Configuring BIOS administrator password
###################################################----#

<#
.Synopsis
    This script allows user to sets the BIOS administrator password of HPE Proliant Gen9 and Gen10 servers. 

.DESCRIPTION
    This script allows user to set the BIOS administrator password.It sets the admin password first time, means when no previous passowrd is set. 
    After configuring administrator password target server can be restart using RestartServer switch parameter.
	
.EXAMPLE
    ConfigureBIOSAdminPassword.ps1
    This mode of execution of script will prompt for 
    
    Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
    
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
       
    AdminPassword :- it will prompt to enter a admin password.
    
.EXAMPLE
    ConfigureBIOSAdminPassword.ps1 -Address "10.20.30.40,10.25.35.45" -Credential $userCrdential -RestartServer

    This mode of script needs following parameters
    
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user credential.# In case of multiple servers use same credential for all the servers

    -RestartServer :- use this switch parameter to restart the server.
    
    -AdminPassword :- it will prompt to enter a new admin password.

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
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    # IP(s) or Hostname(s).Multiple addresses seperated by comma(,).
    [string[]]$Address,   
    #In case of multiple servers it use same credential for all the servers.
    [PSCredential]$Credential,
    #Specify the admin password to set . Note :- This will set the admin password first time only.
    [string[]]$AdminPassword,
    # When this switch parameter is present target server will restart after configuring BIOS administrator password.
    [Switch]$RestartSever
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

Write-Host "This script demonstrate how to set a new AdminPassword. A new AdminPassword can be set,an existing administrator password can be modified or the administrator password can be cleared/removed or reset."
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

if($Address.Count -eq 0)
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
$connection = $null
[int] $connectionCount = 0
[array]$OldAdminPassword=@()
for($i=0;$i -lt $ListOfAddress.Count; $i++)
{
    Write-Host ""
    Write-Host ("Connecting to server  : {0}" -f $ListOfAddress[$i])
    Write-Host ""
    
    $connection = Connect-HPEBIOS -IP $ListOfAddress[$i] -Credential $Credential

    if($Error[0] -match "The underlying connection was closed")
    {
       $connection = Connect-HPEBIOS -IP $ListOfAddress[$i] -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host ("Connection established to the server {0}") -f $ListOfAddress[$i] -ForegroundColor Green
        $connection
        if($connection.ProductName.Contains("Gen9") -or $connection.ProductName.Contains("Gen10"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "BIOS Admin Password is not supported on Server $($connection.IP)"
            Disconnect-HPEBIOS -Connection $connection
        }
    }
    else
    {
        Write-Host "Connection cannot be eastablished to the server : $($ListOfAddress[$i])" -ForegroundColor Red
    }
} 

if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit.."
    Write-Host ""
    exit
}
# Take user input for AdminPassword

if($AdminPassword.Count -eq 0)
{
    $tempAdminPassword = Read-Host "Enter admin password"
    $AdminPassword = $tempAdminPassword.Split(',')
    if($AdminPassword.Count -eq 0)
    {
        Write-host "Admin password is not provided`n Exit....."
        Exit
    }
}


Write-Host "Configuring the AdminPassword....." -ForegroundColor Green
Write-Host " "

$failureCount = 0
if($ListOfConnection.Count -ne 0)
{
   
   $setResult =  Set-HPEBIOSAdminPassword -Connection $ListOfConnection -OldAdminPassword "" -NewAdminPassword $AdminPassword -ErrorAction Continue
   
   foreach($result in $setResult)
   {
    if($result.Status -eq "Information")
    {
        $result
         Write-host "AdminPassword set successfully {0}" $($result.IP)  -ForegroundColor Green
        if($RestartSever){
            $serverRestart = Reset-HPiLOServer -Server $($ListOfConnection[$i].IP) -Credential $Credential -DisableCertificateAuthentication

            if($serverRestart.STATUS_MESSAGE -contains "Server being reset."){
                Write-Host "Server $($ListOfConnection[$i].IP) being reset....." -ForegroundColor Green
                Write-Host ""
            }
        }
    }
    elseif($result.Status -eq "Error")
    {
        Write-Host ""
        Write-Host "AdminPassword cannot be set"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.StatusInfo)"
		Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
        $failureCount++
    }
   }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "******Script execution completed******" -ForegroundColor Green
exit




