########################################################
#Configuring BIOS administrator information
###################################################----#

<#
.Synopsis
    This Script allows user to configure Admin contact details for HPE ProLiant Gen10/Gen9 servers.

.DESCRIPTION
    This script allows user to configure Admin contact details.Following features can be configured.
    AdminName
    AdminPhoneNumber
    AdminEmailAddress
    AdminOtherInfo

    Note :- for multiple server all servers should have same credential.

.EXAMPLE
    ConfigureAdminInfo.ps1
    This mode of exetion of script will prompt for 
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    AdminName   :- Accepts string values.
    
    AdminPhoneNumber :- Accepts string values.
    
    AdminEmailAddress :- Accepts string values.
    
    AdminOtherInfo :- Accepts string values

.EXAMPLE
    ConfigureAdminInfo.ps1 -Address "10.20.30.40" -Credential $userCredential -AdminName Mark -AdminPhoneNumber 1234567891 AdminOtherInfo "Data center admin" -AdminEmailAddress mark@domain.com
    This mode of script have input parameter for Address, Credential, ThermalConfiguration, FanFailurePolicy and FanInstallationRequirement
    
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user Credential. In case of multiple servers use same credentail for all the servers.
    
    -AdminName :- Use this Parameter to specify Admin name.
    
    -AdminPhoneNumber :- Use this parameter to specify Admin phone number.
    
    -AdminEmailAddress :- Use this parameter to specify Admin email address.
    
    -AdminOtherInfo  :- Use this parameter to specify other info
    

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 20/07/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    AdminName
    AdminPhoneNumber
    AdminEmailAddress
    AdminOtherInfo

.OUTPUTS
    None (by default)

.LINK
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    [string[]]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # In case of multiple servers it use same credential for all the servers
    [String[]]$AdminName,
    [String[]]$AdminPhoneNumber,
    [string[]]$AdminEmailAddress,
    [string[]]$AdminOtherInfo
    
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
Write-Host "****** Script execution started ******" -ForegroundColor Yellow
Write-Host ""
#Decribe what script does to the user

Write-Host "This script allows user to admin contact details.Following features can be configured."
Write-Host "AdminName"
Write-Host "AdminPhoneNumber"
Write-Host "AdminEmailAddress"
Write-Host "AdminOtherinfo"
Write-Host ""

#dont shoe error in scrip

#$ErrorActionPreference = "Stop"
#ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"
$ErrorActionPreference = "SilentlyContinue"

#check powershell support
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
    $tempAddress = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"

    $Address = $tempAddress.Split(',')
    if($Address.Count -eq 0)
    {
        Write-Host "You have not entered IP(s) or Hostname(s)"
        Write-Host "`nExit ..."
        exit
    }
}
    

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password(Use same credential for multiple servers)"
    Write-Host ""
}

#Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($Address)

#Create connection object
[array]$ListOfConnection = @()
$connection = $null
[int] $connectionCount = 0

foreach($IPAddress in $ListOfAddress)
{
    Write-Host "`nConnecting to server  : $IPAddress"
    $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential
    
     #Retry connection if it is failed because  of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "The underlying connection was closed")
    {
       $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
     {  
        Write-Host "`nConnection established to the server $IPAddress" -ForegroundColor Green
       
        if($connection.ProductName.Contains("Gen10") -or $connection.ProductName.Contains("Gen9"))
        {
            $connection
            $ListOfConnection += $connection
        }
        else{
            Write-Host "This script will is not supported on Server $($connection.IP)"
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
    Write-Host "Connection could not be established to targer server(s)."
    Write-Host "Exit"
    exit
}

#Get current Admin contact details
Write-Host ""
Write-Host "Current Admin contact details" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
        $result = $serverConnection | Get-HPEBIOSAdminInfo
                
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $CurrentAdminContactDetails += $result
        $counter++
}

#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

if($AdminName.Count -eq 0)
{
    $tempAdminName = Read-Host "Enter Admin name"
    Write-Host ""
    $AdminName = $tempAdminName.Split(',')
}

if($AdminPhoneNumber.count -eq 0)
{
    $tempAdminPhoneNumber = Read-Host "Enter Admin phone number"
    $AdminPhoneNumber = $tempAdminPhoneNumber.Split(',')
    Write-Host ""
}

if($AdminEmailAddress.Count -eq 0)
{
   $tempAdminEmailAddress = Read-Host "Enter Admin Email address"
   $AdminEmailAddress = $tempAdminEmailAddress.Split(',')
   Write-Host ""
}

if($AdminOtherInfo.Count -eq 0)
{
   $tempAdminOtherInfo = Read-Host "Enter Admin other info"
   $AdminOtherInfo = $tempAdminOtherInfo.Split(',')
   Write-Host ""
}


if(($AdminName.Count -eq 0) -and ($AdminPhoneNumber.Count -eq 0) -and($AdminEmailAddress.Count -eq 0))
{
    Write-Host "You have not entered value(s) for any parameter"
    Write-Host "Exit....."
    exit
}

Write-Host "Changing Admin contact details ....." -ForegroundColor Green  
$failureCount = 0

if($ListOfConnection.Count -ne 0)
{
    $setResult = Set-HPEBIOSAdminInfo -Connection $ListOfConnection -AdminName $AdminName -AdminPhoneNumber $AdminPhoneNumber -AdminEmailAddress $AdminEmailAddress -AdminOtherInfo $AdminOtherInfo -ErrorAction Continue
     
    foreach($result in $setResult)
    {       
        if($result -ne $null -and $setResult.Status -eq "Error")
        {
            Write-Host ""
            Write-Host "Admin info cannot be cannot be changed"
            Write-Host "Server : $($result.IP)"
            Write-Host "Error : $($result.StatusInfo)"
		    Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
            $failureCount++
        }
    }
}


if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "Admin info successfully changed" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $result = $serverConnection | Get-HPEBIOSAdminInfo
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $counter ++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit
