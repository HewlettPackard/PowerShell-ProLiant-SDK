########################################################
#Configuring the BIOS processor power
###################################################----#

<#
.Synopsis
    This script allows user to configure processor power for Proliant servers (Gen9 and Gen10)

.DESCRIPTION
    This script allows user to configure processor power.Following features can be configured.
    Minimum Processor Idle Power Core State
    Minimum Processor Idle Power Package State
    Dynamic Power Savings Mode Response 
    Collaborative Power Control
    Energy Performance Bias
    Intel DMI Link Frequency
    
    Note :- for multiple server all the input servers should be of same generation.

.EXAMPLE
    ConfigureProcessorPower.ps1
    This mode of exetion of script will prompt for 
     Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
     Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
     MinimumProcessorIdlePowerCoreState 
     MinimumProcessorIdlePowerPackageState 
     DynamicPowerSavingsModeResponse 
     CollaborativePowerControl 
     EnergyPerformanceBias 
     IntelDMILinkFrequency  
.EXAMPLE
    ConfigureProcessorPower.ps1 -Address "10.20.30.40" -Credential $userCrdential -MinimumProcessorIdlePowerCoreState C3State -MinimumProcessorIdlePowerPackageState Package_C6_State -EnergyPerformanceBias Balanced_Performance -CollaborativePowerControl Enabled -DynamicPowerSavingsModeResponse Fast -IntelDMILinkFrequency GEN1Speed

    This mode of script have input parameters for Address, Credential and ResetBIOSSetting
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- Use this parameter to sepcify user credential.#In case of multiple servers use same credential for all the servers
    -MinimumProcessorIdlePowerCoreState 
    -MinimumProcessorIdlePowerPackageState 
    -DynamicPowerSavingsModeResponse 
    -CollaborativePowerControl  
    -EnergyPerformanceBias 
    -IntelDMILinkFrequency  

    
.NOTES
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential 
    MinimumProcessorIdlePowerCoreState
    MinimumProcessorIdlePowerPackageState
    DynamicPowerSavingsModeResponse
    CollaborativePowerControl
    EnergyPerformanceBias
    IntelDMILinkFrequency

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
    [string[]]$MinimumProcessorIdlePowerCoreState,
    [string[]]$MinimumProcessorIdlePowerPackageState,
    [string[]]$DynamicPowerSavingsModeResponse,
    [string[]]$CollaborativePowerControl,
    [string[]]$EnergyPerformanceBias,
    [string[]]$IntelDMILinkFrequency
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

#Decribe what script does to the user

Write-Host "This script allows user to configure processor power. User can configure followings."
Write-HOst ""
Write-Host "Minimum Processor Idle Power Core State"
Write-Host "Minimum Processor Idle Power Package State"
Write-Host "Dynamic Power Savings Mode Response "
Write-Host "Collaborative Power Control"
Write-Host "Energy Performance Bias"
Write-Host "Intel DMI Link Frequency"

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

    if($connection -ne $null)
    {
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        Write-Host ""
        $connection
        if($connection.ProductName.Contains("Gen10") -or $connection.ProductName.Contains("Gen9"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "This script file is not supported on the target Server $($connection.ProductName) :  $($connection.IP)"
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
    Write-Host "Exit"
    Write-Host ""
    exit
}

# Get current processor power configuration

Write-Host ""
Write-Host "Current processor power configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
    $result = $serverConnection | Get-HPEBIOSProcessorPower
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}

# Get the valid value list fro each parameter
$parameterMetaData = $(Get-Command -Name Set-HPEBIOSProcessorPower).Parameters
$processorCoreStateValidValues =  $($parameterMetaData["MinimumProcessorIdlePowerCoreState"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$processorPOwerPackageStateValidValues = $($parameterMetaData["MinimumProcessorIdlePowerPackageState"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$energyPerformanceBiasValidValues = $($parameterMetaData["EnergyPerformanceBias"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$dynamicPowerSavingValidValues = $($parameterMetaData["DynamicPowerSavingsModeResponse"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$collaborativePowerValidValues = $($parameterMetaData["CollaborativePowerControl"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$dmiLinkFrequencyVallidValues = $($parameterMetaData["IntelDMILinkFrequency"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

#Prompt for User input if it is not given as script  parameter 
if($MinimumProcessorIdlePowerCoreState.Count -eq 0)
{
    
    $tempMinimumProcessorIdlePowerCoreState = Read-Host "Enter MinimumProcessorIdlePowerCoreState [Accepted values : ($($processorCoreStateValidValues -join ","))]."
    Write-Host ""
    $MinimumProcessorIdlePowerCoreState = $tempMinimumProcessorIdlePowerCoreState.Trim().Split(',')
    if($MinimumProcessorIdlePowerCoreState.Count -eq 0){
        Write-Host "MinimumProcessorIdlePowerCoreState is not provided`nExit......."
        exit
    }
}

if($MinimumProcessorIdlePowerPackageState.Count -eq 0)
{
    $tempMinimumProcessorIdlePowerPackageState = Read-Host "Enter MinimumProcessorIdlePowerPackageState [Accepted Values : ($($processorPOwerPackageStateValidValues -join ","))]."
    Write-Host ""
    $MinimumProcessorIdlePowerPackageState = $tempMinimumProcessorIdlePowerPackageState.Trim().Split(',')
    if($MinimumProcessorIdlePowerPackageState.Count -eq 0){
        Write-Host "MinimumProcessorIdlePowerPackageState is not provided`nExit......."
        exit
    }
}

if($EnergyPerformanceBias.Count -eq 0)
{
    $tempEnergyPerformanceBias = Read-Host "Enter EnergyPerformanceBias [Accepted values : ($($energyPerformanceBiasValidValues -join ","))]."
    Write-Host ""
    $EnergyPerformanceBias = $tempEnergyPerformanceBias.Trim().Split(',')
    if($EnergyPerformanceBias.Count -eq 0){
        Write-Host "EnergyPerformanceBias is not provided`nExit......."
        exit
    }
}

if(($ListOfConnection | Where {$_.ProductName.Contains("Gen9")}) -ne $null)
{
    if($DynamicPowerSavingsModeResponse.Count -eq 0)
    {
        $tempDynamicPowerSavingsModeResponse = Read-Host "Enter DynamicPowerSavingsModeResponse [Accepted values : ($($dynamicPowerSavingValidValues -join ","))]."
        Write-Host ""
        $DynamicPowerSavingsModeResponse = $tempDynamicPowerSavingsModeResponse.Trim().Split(',')
        if($DynamicPowerSavingsModeResponse.Count -eq 0){
            Write-Host "DynamicPowerSavingsModeResponse is not provided`nExit......."
            exit
        }
    }
}

if($CollaborativePowerControl.Count -eq 0)
{
    $tempCollaborativePowerControl = Read-Host "Enter CollaborativePowerControl [Accepted values : ($($collaborativePowerValidValues -join ","))]."
    Write-Host ""
    $CollaborativePowerControl = $tempCollaborativePowerControl.Trim().Split(',')
    if($CollaborativePowerControl.Count -eq 0){
        Write-Host "CollaborativePowerControl is not provided`nExit......."
        exit
    }
}


if($IntelDMILinkFrequency.Count -eq 0)
{
    $tempIntelDMILinkFrequency = Read-Host "Enter IntelDMILinkFrequency [Accepted values : ($($dmiLinkFrequencyVallidValues -join ","))]."
    Write-Host ""
    $IntelDMILinkFrequency = $tempIntelDMILinkFrequency.Trim().Split(',')
    if($IntelDMILinkFrequency.Count -eq 0){
    Write-Host "IntelDMILinkFrequency is not provided`nExit......."
    exit
    }
}



for($i = 0; $i -lt $MinimumProcessorIdlePowerCoreState.Count ;$i++)
{
     
    if($($processorCoreStateValidValues | where {$_ -eq $MinimumProcessorIdlePowerCoreState[$i]}) -eq $null)
    {
        Write-Host "Inavlid value for MinimumProcessorIdlePowerCoreState"
        Write-Host "Exit...."
        exit
    }
}    

for($i = 0; $i -lt $MinimumProcessorIdlePowerPackageState.Count ;$i++)
{
    if($($processorPOwerPackageStateValidValues | where {$_ -eq $MinimumProcessorIdlePowerPackageState[$i]}) -eq $null)
    {
        Write-Host "Inavlid value for MinimumProcessorIdlePowerPackageState"
        Write-Host "Exit...."
        exit
    }
    
}

for($i = 0; $i -lt $EnergyPerformanceBias.Count ;$i++)
{
    if($($energyPerformanceBiasValidValues | where {$_ -eq $EnergyPerformanceBias[$i]}) -eq $null)
    {
        Write-Host "Inavlid value for EnergyPerformanceBias"
        Write-Host "Exit...."
        exit
    }
}    

for($i = 0; $i -lt $DynamicPowerSavingsModeResponse.Count ;$i++)
{
    if($($dynamicPowerSavingValidValues | where {$_ -eq $DynamicPowerSavingsModeResponse[$i]}) -eq $null)
    {
        Write-Host "Invalid value for DynamicPowerSavingsModeResponse"
        Write-Host "Exit...."
        exit
    }
}    
    
for($i = 0; $i -lt $CollaborativePowerControl.Count ;$i++)
{
    if($($collaborativePowerValidValues | where {$_ -eq $CollaborativePowerControl[$i]}) -eq $null)
    {
        Write-Host "Invalid value for CollaborativePowerControl"
        Write-Host "Exit...."
        exit
    }
    
}
    
for($i = 0; $i -lt $dmiLinkFrequencyList.Count ;$i++)
{
    if($($dmiLinkFrequencyVallidValues | where {$_ -eq $dmiLinkFrequencyList[$i]}) -eq $null)
    {
        Write-Host "Invalid value for IntelDMILinkFrequency"
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing processor power configuration....." -ForegroundColor Green

$failureCount = 0

$inputObject = New-Object -TypeName PSObject
$inputObject | Add-Member MinimumProcessorIdlePowerCoreState $MinimumProcessorIdlePowerCoreState
$inputObject | Add-Member MinimumProcessorIdlePowerPackageState $MinimumProcessorIdlePowerPackageState
$inputObject | Add-Member EnergyPerformanceBias $EnergyPerformanceBias
$inputObject | Add-Member CollaborativePowerControl $CollaborativePowerControl
$inputObject | Add-Member IntelDMILinkFrequency $IntelDMILinkFrequency

if($DynamicPowerSavingsModeResponse.Count -ne 0)
{
    $inputObject | Add-Member DynamicPowerSavingsModeResponse $DynamicPowerSavingsModeResponse
}


if($ListOfConnection.Count -ne 0)
{
        
    $setResult = $inputObject | Set-HPEBIOSProcessorPower -Connection $ListOfConnection
        
    foreach($result in $setResult)
    {
        if($result.Status -ne "OK")
        {
            Write-Host ""
            Write-Host "Processor power configuration Cannot be changed"
            Write-Host "Server : $($result.IP)"
            Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
			Write-Host "`nStatusInfo.Message : $($result.StatusInfo.Message)"
			Write-Host "`n=====StatusInfo.AffectedAttribute======"
            $($result.StatusInfo.AffectedAttribute) | fl
            $failureCount++
        }
    }
}


#Get the processor power configuration after set
if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "Processor power configuration changed successfully" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $result = $serverConnection | Get-HPEBIOSProcessorPower
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