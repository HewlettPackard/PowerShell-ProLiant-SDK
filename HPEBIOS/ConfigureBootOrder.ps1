########################################################
#Change UEFI BootOrder
###################################################----#

<#
.Synopsis
    This script allows user to change boot order of HPE Proliant Gen 9 servers

.DESCRIPTION
    This script demonstrates how the cmdlet Set-HPBIOSUEFIBootOrder and Get-HPBIOSUEFIBootOrder is used to 
    get the current UEFI boot order list and set the UEFI Boot Order user to change the boot order.
    -UEFIBootOrder :- sets the UEFI boot order list
    
.EXAMPLE
     ConfigureBootOrder.ps1
     This mode of execution of script will prompt for 
     Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
     Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
     UEFIBootOrder :- it will prompt to enter Boot order to set. The user has to enter the index values separated with  comma for the boot order to set

.EXAMPLE
    ConfigureBootOrder.ps1 -Address "10.20.30.40,10.25.35.45" -Credential $userCrdential -UEFIBootOrder "3,1,2 | 2,1"

    This mode of script have input parameter for Address and UEFIBootOrder
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -UEFIBootOrder :- Use this Parameter to specify boot order.Only the number of UEFI configured options available for a particular server can be entered as UEFIBootOrder parameter values.
    The index values can be entered by refering the Current boot order settings.
    -Credential :- Use this parameter to sepcify user credential.

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 1.1.0.0
    Date    : 8/8/2016
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    UEFIBootOrder

.OUTPUTS
    None (by default)

.LINK
.LINK
    http://www8.hp.com/in/en/products/server-software/product-detail.html?oid=5440657
#>



#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # all server should have same ceredntial (in case of multiple addresses)
    [String]$UEFIBootOrder  # Boot Order (UEFI or LegacyBIOS)
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

Write-Host "This script demonstrate how to change UEFI boot order for Gen9 server.The parameters it accepts are \n"
Write-Host "UEFIBootOrder:-The index values to change the boot order"

#dont show error in script

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"
$ErrorActionPreference = "SilentlyContinue"


#check powershell support
    <#Write-Host "Checking PowerShell version support"
    Write-Host ""#>
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
    <#Write-Host "Checking HPBIOSCmdlets module"
    Write-Host ""#>

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
    $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential
    
    #Retry connection if it is failed because  of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "iLO SSL Certificate is not valid")
    {
       $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        $connection
        if($connection.ConnectionInfo.ServerPlatformNumber -eq 9)
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "UEFI Boot Order is not supported on Server $($connection.IP)"
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


# Get current boot order
if($ListOfConnection.Count -ne 0)
{
    Write-Host ""
    Write-Host "Current Boot Order configuration" -ForegroundColor Yellow
    Write-Host ""
    for($i=0; $i -lt $ListOfConnection.Count; $i++)
    {
            $result = $ListOfConnection[$i] | Get-HPBIOSUEFIBootOrder
            Write-Host  ("----------Server {0} ----------" -f ($i+1))  -ForegroundColor DarkYellow
            $result.UEFIBootOrder | Format-Table -AutoSize 
    }
}

# Take user input for Boot Order
Write-Host "Input Hint : For multiple server please enter parameter values seprated by vertical bar (|)" -ForegroundColor Yellow
Write-Host ""
if($UEFIBootOrder -eq "")
{
    $UEFIBootOrder = Read-Host "Enter Boot Order."
    Write-Host ""
}

$inputBootOrderList =  ($UEFIBootOrder.Trim().Split('|'))

if($inputBootOrderList.Count -eq 0)
{
    Write-Host "You have not enterd boot order"
    Write-Host "Exit....."
    exit
}

Write-Host "Changing UEFI Boot order....." -ForegroundColor Green

$failureCount = 0
for($i=0; $i -lt $ListOfConnection.Count ;$i++)
{
    
    $result = $ListOfConnection[$i] | Set-HPBIOSUEFIBootOrder -UEFIBootOrder $inputBootOrderList[$i]
      
    if($result.StatusType -eq "Error")
    {
        Write-Host ""
        Write-Host "Boot Order cannot be changed"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.StatusMessage)"
        $failureCount++
    }
   
} 

 if($failureCount -ne $ListOfConnection.Count)
 {
        Write-Host ""
        Write-host "Boot Order changed successfully" -ForegroundColor Green
        Write-Host ""
 }

 if($ListOfConnection.Count -ne 0)
 {
        for($i=0; $i -lt $ListOfConnection.Count; $i++)
        {
            $result = $ListOfConnection[$i] | Get-HPBIOSUEFIBootOrder
            Write-Host  ("----------Server {0} ----------" -f ($i+1))  -ForegroundColor DarkYellow
            $result.UEFIBootOrder | Format-Table -AutoSize 
        }
 }
Disconnect-HPBIOSAllConnection    
$ErrorActionPreference = "Continue"
Write-Host "******Script execution completed******" -ForegroundColor Green
exit





