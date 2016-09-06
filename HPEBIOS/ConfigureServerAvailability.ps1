<#
.Synopsis
    This script allows user to configure server availability for HPE Proliant servers (Gen 9 and Gen 8)

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
    ConfigureServerAvailability.ps1 -Address "10.20.30.40,10.25.35.45" -Credential $userCrdential -ASR "Enabled,Disabled" -ASRTimeOut "10_Minutes,15_Minutes" -AutomaticPowerOn "Always_Power_On,Always_Power_On" -PowerOnDelay "15_Second,30_Second" -PowerButton "Enabled,Enabled" -POSTF1Prompt "Delayed2Sec,Delayed2Sec" -WakeOnLAN "Enabled,Enabled"

    This mode of script have input parameters for Address, Credential and ResetBIOSSetting
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- Use this parameter to sepcify user credential.
    -ASR 
    -ASRTimeout 
    -AutomaticPoweron 
    -PostF1Prompt  
    -PowerOnDelay  
    -WakeOnLAN  
    -PowerButton 
    
.NOTES
    Company : Hewlett Packard Enterprise
    Version : 1.1.0.0
    Date    : 9/8/2016
    
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
    
    http://www8.hp.com/in/en/products/server-software/product-detail.html?oid=5440657
#>

#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # all server should have same ceredntial (in case of multiple addresses)
    [string]$ASR,
    [string]$ASRTimeout,
    [string]$AutomaticPoweron,
    [string]$PowerButton,
    [string]$PostF1Prompt,
    [string]$PowerOnDelay,
    [string]$WakeOnLAN
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

# check for IP(s) or Hostname(s)

if($Address -eq "")
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
    $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential

    #Retry connection if it is failed because of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "iLO SSL Certificate is not valid")
    {
       $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
    {
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        Write-Host ""
        $connection
        $ListOfConnection += $connection
    }
    else
    {
         Write-Host "Connection cannot be eastablished to the server : $IPAddress" -ForegroundColor Red
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
    $result = $serverConnection | Get-HPBIOSServerAvailability
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}

# Get the valid value list fro each parameter
$parameterMetaData = $(Get-Command -Name Set-HPBIOSServerAvailability).Parameters
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
if($ASR -eq "")
{
    
    $ASR = Read-Host "Enter ASR [Accepted values ($($ASRValidValues -join ","))]."
    Write-Host ""
}

if($ASRTimeout -eq "")
{
    $ASRTimeout = Read-Host "Enter ASR timeout[Accepted Values ($($ASRTimeoutValidValues -join ","))]."
    Write-Host ""
}

if($AutomaticPoweron -eq "")
{
    $AutomaticPoweron = Read-Host "Enter AutomaticPoweron [Accepted values ($($AutomaticPoweronValidValues -join ","))]."
    Write-Host ""
}

if($PowerButton -eq "")
{
    $PowerButton = Read-Host "Enter PowerButton [Accepted values ($($PowerButtonValidValues -join ","))]."
    Write-Host ""
}

if($PostF1Prompt -eq "")
{
    $PostF1Prompt = Read-Host "Enter PostF1Prompt [Accepted values ($($PostF1PromptValidValues -join ","))]."
    Write-Host ""
}

if($PowerOnDelay -eq "")
{
    $PowerOnDelay = Read-Host "Enter PowerOnDelay [Accepted values ($($PowerOnDelayVallidValues -join ","))]."
    Write-Host ""
}

if($WakeOnLAN -eq "")
{
    $WakeOnLAN = Read-Host "Enter WakeOnLAN [Accepted values ($($WakeOnLANValidValues -join ","))]."
    Write-Host ""
}


# split the input value.
$ASRInputList = ($ASR.Trim().Split(','))
$ASRTimeoutList = ($ASRTimeout.Trim().Split(','))
$PostF1PromptList = ($PostF1Prompt.Trim().Split(','))
$WakeOnLANList = ($WakeOnLAN.Trim().Split(','))
$AutomaticPoweronList = ($AutomaticPoweron.Trim().Split(','))
$PowerOnDelayList = ($PowerOnDelay.Trim().Split(','))
$PowerButtonList = ($PowerButton.Trim().Split(','))

#Validate user input and add to ToSet List to set the values
[array]$ASRToSet = @()
[array]$ASRTimeoutToSet = @()
[array]$PostF1PromptToSet = @()
[array]$WakeOnLANToSet = @()
[array]$AutomaticPoweronToSet = @()
[array]$PowerOnDelayToSet = @()
[array]$PowerButtonToSet = @()

if(($ASRInputList.Count -eq 0)  -and ($ASRTimeoutList.Count -eq 0) -and ($PostF1PromptList.Count -eq 0) -and ($WakeOnLANList.Count -eq 0))
{
    Write-Host "You have not enterd parameter value"
    Write-Host "Exit....."
    exit
}


for($i = 0; $i -lt $ListOfConnection.Count ;$i++)
{
     
    if($($ASRValidValues | where {$_ -eq $ASRInputList[$i]}) -ne $null)
    {
        $ASRToSet += $ASRInputList[$i]
    }
    else
    {
        Write-Host "Inavlid value for ASR".
        Write-Host "Exit...."
        exit
    }

    if($($ASRTimeoutValidValues | where {$_ -eq $ASRTimeoutList[$i]}) -ne $null)
    {
        $ASRTimeoutToSet += $ASRTimeoutList[$i]
    }
    else
    {
        Write-Host "Inavlid value for ASRTimeout".
        Write-Host "Exit...."
        exit
    }


    if($($PostF1PromptValidValues | where {$_ -eq $PostF1PromptList[$i]}) -ne $null)
    {
        $PostF1PromptToSet += $PostF1PromptList[$i]
    }
    else
    {
        Write-Host "Inavlid value for PostF1Prompt".
        Write-Host "Exit...."
        exit
    }

    if($($PowerButtonValidValues | where {$_ -eq $PowerButtonList[$i]}) -ne $null)
    {
        $PowerButtonToSet += $PowerButtonList[$i]
    }
    else
    {
        Write-Host "Invalid value for PowerButton"
        Write-Host "Exit...."
        exit
    }
    
    if($($PowerOnDelayVallidValues | where {$_ -eq $PowerOnDelayList[$i]}) -ne $null)
    {
        $PowerOnDelayToSet += $PowerOnDelayList[$i]
    }
    else
    {
        Write-Host "Invalid value for PowerOnDelay"
        Write-Host "Exit...."
        exit
    }

    if($($AutomaticPoweronValidValues | where {$_ -eq $AutomaticPoweronList[$i]}) -ne $null)
    {
        $AutomaticPoweronToSet += $AutomaticPoweronList[$i]
    }
    else
    {
        Write-Host "Invalid value for AutomaticPowerOn"
        Write-Host "Exit...."
        exit
    }

    if($($WakeOnLANValidValues | where {$_ -eq $WakeOnLANList[$i]}) -ne $null)
    {
        $WakeOnLANToSet += $WakeOnLANList[$i]
    }
    else
    {
        Write-Host "Invalid value for WakeonLAN"
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing server availability configuration....." -ForegroundColor Green

$failureCount = 0
for ($i = 0 ;$i -lt $ListOfConnection.Count ; $i++)
{
        if($ListOfConnection[$i].ConnectionInfo.ServerPlatformNumber -eq 9)
        {
            $setResult = $ListOfConnection[$i] | Set-HPBIOSServerAvailability -ASR $ASRToSet[$i] -ASRTimeout $ASRTimeoutToSet[$i] -POSTF1Prompt $PostF1PromptToSet[$i] -WakeOnLAN $WakeOnLANToSet[$i] -PowerButton $PowerButtonToSet[$i] -PowerOnDelay $PowerOnDelayToSet[$i] -AutomaticPowerOn $AutomaticPoweronToSet[$i]
        }
        else
        {
             $setResult = $ListOfConnection[$i] | Set-HPBIOSServerAvailability -ASR $ASRToSet[$i] -ASRTimeout $ASRTimeoutToSet[$i] -POSTF1Prompt $PostF1PromptToSet[$i] -WakeOnLAN $WakeOnLANToSet[$i] -PowerButton $PowerButtonToSet[$i] -PowerOnDelay $PowerOnDelayToSet[$i] -AutomaticPowerOn $AutomaticPoweronToSet[$i]
        }

        if($setResult.StatusType -eq "Error")
        {
            Write-Host ""
            Write-Host "server security Cannot be changed"
            Write-Host "Server : $($setResult.IP)"
            Write-Host "Error : $($setResult.StatusMessage)"
            $failureCount++
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
        $result = $serverConnection | Get-HPBIOSServerAvailability
        Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $counter++
    }
}
    
Disconnect-HPBIOSAllConnection    
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit