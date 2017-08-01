##############################################################
#Configuring the server availability 
##########################################################----#

<#
.Synopsis
    This script allows user to configure server availability for HPE Proliant servers (Gen9 and Gen10)

.DESCRIPTION
    This script allows user to configure server availability.Following features can be configured
    ASR (Automatic Server Recovery)
    ASRTimeout (Automatic Server Recovery) timeout
    Automatic Power-On
    Power-On Delay
    Power Button Mode
    POST F1 Prompt
    Wake-On LAN

.EXAMPLE
     ConfigureServerAvailability.ps1
     This mode of exetion of script will prompt for 
     Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
     Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
     ASR :- option to enable or disable ASR (Automatic Server Recovery).
     ASRTimeout :- set the time to wait before rebooting the server in the event of an operating system crash or server lockup
     AutomaticPoweron :- option to configure the server to automatically power on when AC power is applied to the system
     PostF1Prompt :- option to configure how the system displays the F1 key in the server POST screen
     PowerOnDelay :- option to set whether or not to delay the server from turning on for a specified time
     WakeOnLAN :-  option to enable or disable the ability of the server to power on remotely when it receives a special packet
     PowerButton :- option to enable or disable momentary power button functionality
.EXAMPLE
    ConfigureServerAvailability.ps1 -Address "10.20.30.40,10.25.35.45" -Credential $userCrdential -ASR "Enabled,Disabled" -ASRTimeOut "10Minutes,15Minutes" -AutomaticPowerOn "AlwaysPowerOn,AlwaysPowerOff" -PowerOnDelay "15Second,30Second" -PowerButton "Enabled,Enabled" -POSTF1Prompt "Delayed2Sec,Delayed2Sec" -WakeOnLAN "Enabled,Disabled"

    This mode of script have input parameters for Address, Credential and ResetBIOSSetting
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- Use this parameter to sepcify user credential.#In case of multiple servers use same credential for all the servers
    -ASR 
    -ASRTimeout 
    -AutomaticPoweron 
    -PostF1Prompt  
    -PowerOnDelay  
    -WakeOnLAN  
    -PowerButton 
    
.NOTES
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    ASR
    ASRTimeout
    AutomaticPoweron
    PostF1Prompt
    PowerOnDelay
    WakeOnLAN
    PowerButton

.OUTPUTS
    None (by default)

.LINK
    
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>

#Command line parameters
Param(
    # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [string[]]$Address,   
    #In case of multiple servers it use same credential for all the servers
    [PSCredential]$Credential, 
    [string[]]$ASR,
    [string[]]$ASRTimeout,
    [string[]]$AutomaticPoweron,
    [string[]]$PowerButton,
    [string[]]$PostF1Prompt,
    [string[]]$PowerOnDelay,
    [string[]]$WakeOnLAN
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

Write-Host "This script allows user to configure server availability. User can configure followings "
Write-host "ASR (Automatic Server Recovery)"
Write-Host "ASRTimeout (Automatic Server Recovery) timeout"
Write-Host "Automatic Power-On"
Write-Host "Power-On Delay"
Write-Host "Power Button Mode"
Write-Host "POST F1 Prompt"
Write-Host "Wake-On LAN"
Write-Host ""

#dont show error in scrip

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

# check for IP(s) or Hostname(s)

if($Address.Count -eq 0)
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}

[array]$ListOfAddress = ($Address.split(",")).Trim()

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)"
    Write-Host ""
    Write-Host "Exit..."
    exit
}

if($Credential -eq $null)
{
    Write-Host "Enter User Credentials"
    Write-Host ""
    $Credential = Get-Credential -Message "Enter user Credentials"
}

# Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

[array]$ListOfConnection = @()

# create connection object
foreach($IPAddress in $ListOfAddress)
{
    
    Write-Host "Connecting to server  : $IPAddress"
    Write-Host ""
    $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential

    #Retry connection if it is failed because of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "The underlying connection was closed")
    {
       $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection.ProductName.Contains("Gen10") -or $connection.ProductName.Contains("Gen9"))
    {
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        Write-Host ""
        $connection
        $ListOfConnection += $connection
    }
    else
    {
         Write-Host "Connection cannot be eastablished to the server : $IPAddress" -ForegroundColor Red
		 Disconnect-HPEBIOS -Connection $connection
    }
}


if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit"
    Write-Host ""
    exit
}

# Get current server availability

Write-Host ""
Write-Host "Current server availability configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
    $result = $serverConnection | Get-HPEBIOSServerAvailability
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}

# Get the valid value list fro each parameter
$parameterMetaData = $(Get-Command -Name Set-HPEBIOSServerAvailability).Parameters
$ASRValidValues =  $($parameterMetaData["ASR"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$ASRTimeoutValidValues = $($parameterMetaData["ASRTimeout"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$PostF1PromptValidValues = $($parameterMetaData["POSTF1Prompt"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$WakeOnLANValidValues = $($parameterMetaData["WakeOnLAN"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$PowerButtonValidValues = $($parameterMetaData["PowerButton"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$PowerOnDelayVallidValues = $($parameterMetaData["PowerOnDelay"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$AutomaticPoweronValidValues = $($parameterMetaData["AutomaticPowerOn"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

#Prompt for User input if it is not given as script  parameter 
if($ASR.Count -eq 0)
{
    $tempASR = Read-Host "Enter ASR [Accepted values ($($ASRValidValues -join ","))]."
    Write-Host ""
    $ASR = $tempASR.Trim().Split(',')
    if($ASR.Count -eq 0){
        Write-Host "ASR is provided`nExit....."
        exit
    }
}

if($ASRTimeout.Count -eq 0)
{
    $tempASRTimeout = Read-Host "Enter ASR timeout[Accepted Values ($($ASRTimeoutValidValues -join ","))]."
    Write-Host ""
    $ASRTimeout = $tempASRTimeout.Trim().Split(',')
    if($ASRTimeout.Count -eq 0){
        Write-Host "ASRTimeout is provided`nExit....."
        exit
    }
}

if($AutomaticPoweron.Count -eq 0)
{
    $tempAutomaticPoweron = Read-Host "Enter AutomaticPoweron [Accepted values ($($AutomaticPoweronValidValues -join ","))]."
    Write-Host ""
    $AutomaticPoweron = $tempAutomaticPoweron.Trim().Split(',')
    if($AutomaticPoweron.Count -eq 0){
        Write-Host "AutomaticPoweron is provided`nExit....."
        exit
    }
}

if($PowerButton.Count -eq 0)
{
    $tempPowerButton = Read-Host "Enter PowerButton [Accepted values ($($PowerButtonValidValues -join ","))]."
    Write-Host ""
    $PowerButton = $tempPowerButton.Trim().Split(',')
    if($PowerButton.Count -eq 0){
        Write-Host "PowerButton is provided`nExit....."
        exit
    }
}

if($PostF1Prompt.Count -eq 0)
{
    $tempPostF1Prompt = Read-Host "Enter PostF1Prompt [Accepted values ($($PostF1PromptValidValues -join ","))]."
    Write-Host ""
    $PostF1Prompt = $tempPostF1Prompt.Trim().Split(',')
    if($PostF1Prompt.Count -eq 0){
        Write-Host "PostF1Prompt is provided`nExit....."
        exit
    }
}

if($PowerOnDelay.Count -eq 0)
{
    $tempPowerOnDelay = Read-Host "Enter PowerOnDelay [Accepted values ($($PowerOnDelayVallidValues -join ","))]."
    Write-Host ""
    $PowerOnDelay = $tempPowerOnDelay.Trim().Split(',')
    if($PowerOnDelay.Count -eq 0){
        Write-Host "PowerOnDelay is provided`nExit....."
        exit
    }
}

if($WakeOnLAN.Count -eq 0)
{
    $tempWakeOnLAN = Read-Host "Enter WakeOnLAN [Accepted values ($($WakeOnLANValidValues -join ","))]."
    Write-Host ""
    $WakeOnLAN = $tempWakeOnLAN.Trim().Split(',')
    if($WakeOnLAN.Count -eq 0){
        Write-Host "WakeOnLAN is provided`nExit....."
        exit
    }
}

#Validate user input and add to ToSet List to set the values

for($i = 0; $i -lt $ASR.Count ;$i++)
{
    if($($ASRValidValues | where {$_ -eq $ASR[$i]}) -eq $null)
    {
        Write-Host "Inavlid value for ASR".
        Write-Host "Exit...."
        exit
    }
}

for($i = 0; $i -lt $ASRTimeout.Count ;$i++)
{
    if($($ASRTimeoutValidValues | where {$_ -eq $ASRTimeout[$i]}) -eq $null)
    {
       Write-Host "Inavlid value for ASRTimeout".
        Write-Host "Exit...."
        exit
    }
}    

for($i = 0; $i -lt $PostF1Prompt.Count ;$i++)
{
    if($($PostF1PromptValidValues | where {$_ -eq $PostF1Prompt[$i]}) -eq $null)
    {
        Write-Host "Inavlid value for PostF1Prompt".
        Write-Host "Exit...."
        exit
    }
}    

for($i = 0; $i -lt $PowerButton.Count ;$i++)
{
    if($($PowerButtonValidValues | where {$_ -eq $PowerButton[$i]}) -eq $null)
    {
        Write-Host "Invalid value for PowerButton"
        Write-Host "Exit...."
        exit
    }
}    
    
for($i = 0; $i -lt $PowerOnDelay.Count ;$i++)
{
    if($($PowerOnDelayVallidValues | where {$_ -eq $PowerOnDelay[$i]}) -eq $null)
    {
        Write-Host "Invalid value for PowerOnDelay"
        Write-Host "Exit...."
        exit
    }
}

for($i = 0; $i -lt $AutomaticPoweron.Count ;$i++)
{   

    if($($AutomaticPoweronValidValues | where {$_ -eq $AutomaticPoweron[$i]}) -eq $null)
    {
        Write-Host "Invalid value for AutomaticPowerOn"
        Write-Host "Exit...."
        exit
    }
}    

for($i = 0; $i -lt $WakeOnLAN.Count ;$i++)
{ 
    if($($WakeOnLANValidValues | where {$_ -eq $WakeOnLAN[$i]}) -eq $null)
    {
        Write-Host "Invalid value for WakeonLAN"
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing server availability configuration....." -ForegroundColor Green

$failureCount = 0

$inputObject = New-Object -TypeName PSObject
$inputObject | Add-Member ASR $ASR
$inputObject | Add-Member ASRTimeout $ASRTimeout
$inputObject | Add-Member POSTF1Prompt $PostF1Prompt
$inputObject | Add-Member WakeOnLAN $WakeOnLAN
$inputObject | Add-Member PowerButton $PowerButton
$inputObject | Add-Member PowerOnDelay $PowerOnDelay
$inputObject | Add-Member AutomaticPowerOn $AutomaticPoweron


if($ListOfConnection.Count -ne 0)
{
       
       $setResult = $inputObject | Set-HPEBIOSServerAvailability -Connection $ListOfConnection
       
       foreach($result in $setResult)
       {
            if($result.Status -eq "Error")
            {
                Write-Host ""
                Write-Host "server security Cannot be changed"
                Write-Host "Server : $($result.IP)"
                Write-Host "`nStatusInfo.Category : $($result.StatusInfo.Category)"
			    Write-Host "`nStatusInfo.Message : $($result.StatusInfo.Message)"
			    Write-Host "`n=====StatusInfo.AffectedAttribute=======" 
                $($result.StatusInfo.AffectedAttribute) | fl
                $failureCount++
            }
        }
}

#Get server availability configuration after set
if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "Server availability configuration changed successfully" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $result = $serverConnection | Get-HPEBIOSServerAvailability
        Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $counter++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit