<#
.Synopsis
    This script allows user to configure processor power for Proliant servers (Gen 9 and Gen 8 Intel)

.DESCRIPTION
    This script allows user to configure processor power.Following features can be configured.
    Minimum Processor Idle Power Core State
    Minimum Processor Idle Power Package State
    Dynamic Power Savings Mode Response 
    Collaborative Power Control
    Energy Performance Bias
    Intel DMI Link Frequency
    

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
    -Credential :- Use this parameter to sepcify user credential.
    -MinimumProcessorIdlePowerCoreState 
    -MinimumProcessorIdlePowerPackageState 
    -DynamicPowerSavingsModeResponse 
    -CollaborativePowerControl  
    -EnergyPerformanceBias 
    -IntelDMILinkFrequency  

    
.NOTES
    Company : Hewlett Packard Enterprise
    Version : 1.1.0.0
    Date    : 9/8/2016
    
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
    
    http://www8.hp.com/in/en/products/server-software/product-detail.html?oid=5440657
#>

#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # all server should have same ceredntial (in case of multiple addresses)
    [string]$MinimumProcessorIdlePowerCoreState,
    [string]$MinimumProcessorIdlePowerPackageState,
    [string]$DynamicPowerSavingsModeResponse,
    [string]$CollaborativePowerControl,
    [string]$EnergyPerformanceBias,
    [string]$IntelDMILinkFrequency
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
        if($connection.ConnectionInfo.ProcessorInfo -match "Intel")
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "This script file is not supported on AMD Server $($connection.IP)"
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
    $result = $serverConnection | Get-HPBIOSProcessorPower
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}

# Get the valid value list fro each parameter
$parameterMetaData = $(Get-Command -Name Set-HPBIOSProcessorPower).Parameters
$processorCoreStateValidValues =  $($parameterMetaData["MinimumProcessorIdlePowerCoreState"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$processorPOwerPackageStateValidValues = $($parameterMetaData["MinimumProcessorIdlePowerPackageState"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$energyPerformanceBiasValidValues = $($parameterMetaData["EnergyPerformanceBias"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$dynamicPowerSavingValidValues = $($parameterMetaData["DynamicPowerSavingsModeResponse"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$collaborativePowerValidValues = $($parameterMetaData["CollaborativePowerControl"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$dmiLinkFrequencyVallidValues = $($parameterMetaData["IntelDMILinkFrequency"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

#Prompt for User input if it is not given as script  parameter 
if($MinimumProcessorIdlePowerCoreState -eq "")
{
    
    $MinimumProcessorIdlePowerCoreState = Read-Host "Enter MinimumProcessorIdlePowerCoreState [Accepted values : ($($processorCoreStateValidValues -join ","))]."
    Write-Host ""
}

if($MinimumProcessorIdlePowerPackageState -eq "")
{
    $MinimumProcessorIdlePowerPackageState = Read-Host "Enter MinimumProcessorIdlePowerPackageState [Accepted Values : ($($processorPOwerPackageStateValidValues -join ","))]."
    Write-Host ""
}

if($EnergyPerformanceBias -eq "")
{
    $EnergyPerformanceBias = Read-Host "Enter EnergyPerformanceBias [Accepted values : ($($energyPerformanceBiasValidValues -join ","))]."
    Write-Host ""
}

if($DynamicPowerSavingsModeResponse -eq "")
{
    $DynamicPowerSavingsModeResponse = Read-Host "Enter DynamicPowerSavingsModeResponse [Accepted values : ($($dynamicPowerSavingValidValues -join ","))]."
    Write-Host ""
}

if($CollaborativePowerControl -eq "")
{
    $CollaborativePowerControl = Read-Host "Enter CollaborativePowerControl [Accepted values : ($($collaborativePowerValidValues -join ","))]."
    Write-Host ""
}

if($ListOfConnection[$i].ConnectionInfo.ServerPlatformNumber -eq 9)
{
    if($IntelDMILinkFrequency -eq "")
    {
        $IntelDMILinkFrequency = Read-Host "Enter IntelDMILinkFrequency [Accepted values : ($($dmiLinkFrequencyVallidValues -join ","))]."
        Write-Host ""
    }
}

# split the input value.
$processorCoreStateList = ($MinimumProcessorIdlePowerCoreState.Trim().Split(','))
$processorPowerPackageList = ($MinimumProcessorIdlePowerPackageState.Trim().Split(','))
$energyPeroformanceBiasList = ($EnergyPerformanceBias.Trim().Split(','))
$dynamicPowerSavingList = ($DynamicPowerSavingsModeResponse.Trim().Split(','))
$collaborativePowerList = ($CollaborativePowerControl.Trim().Split(','))
$dmiLinkFrequencyList = ($IntelDMILinkFrequency.Trim().Split(','))
$PowerButtonList = ($PowerButton.Trim().Split(','))

#Validate user input and add to ToSet List to set the values
[array]$processorCoreStateToSet = @()
[array]$processorPowerPackageToSet = @()
[array]$energyPeroformanceBiasToSet = @()
[array]$dynamicPowerSavingToSet = @()
[array]$collaborativePowerToSet = @()
[array]$dmiLinkFrequencyToSet = @()


if(($processorCoreStateList.Count -eq 0)  -and ($processorPowerPackageList.Count -eq 0) -and ($energyPeroformanceBiasList.Count -eq 0) -and ($dynamicPowerSavingList.Count -eq 0) -and ($collaborativePowerList.Count -eq 0) -and ($dmiLinkFrequencyList.Count -eq 0))
{
    Write-Host "You have not enterd parameter value"
    Write-Host "Exit....."
    exit
}


for($i = 0; $i -lt $ListOfConnection.Count ;$i++)
{
     
    if($($processorCoreStateValidValues | where {$_ -eq $processorCoreStateList[$i]}) -ne $null)
    {
        $processorCoreStateToSet += $processorCoreStateList[$i]
    }
    else
    {
        Write-Host "Inavlid value for MinimumProcessorIdlePowerCoreState"
        Write-Host "Exit...."
        exit
    }

    if($($processorPOwerPackageStateValidValues | where {$_ -eq $processorPowerPackageList[$i]}) -ne $null)
    {
        $processorPowerPackageToSet += $processorPowerPackageList[$i]
    }
    else
    {
        Write-Host "Inavlid value for MinimumProcessorIdlePowerPackageState"
        Write-Host "Exit...."
        exit
    }


    if($($energyPerformanceBiasValidValues | where {$_ -eq $energyPeroformanceBiasList[$i]}) -ne $null)
    {
        $energyPeroformanceBiasToSet += $energyPeroformanceBiasList[$i]
    }
    else
    {
        Write-Host "Inavlid value for EnergyPerformanceBias"
        Write-Host "Exit...."
        exit
    }

    if($($dynamicPowerSavingValidValues | where {$_ -eq $dynamicPowerSavingList[$i]}) -ne $null)
    {
        $dynamicPowerSavingToSet += $dynamicPowerSavingList[$i]
    }
    else
    {
        Write-Host "Invalid value for DynamicPowerSavingsModeResponse"
        Write-Host "Exit...."
        exit
    }
    
    if($($collaborativePowerValidValues | where {$_ -eq $collaborativePowerList[$i]}) -ne $null)
    {
        $collaborativePowerToSet += $collaborativePowerList[$i]
    }
    else
    {
        Write-Host "Invalid value for CollaborativePowerControl"
        Write-Host "Exit...."
        exit
    }

    if($ListOfConnection[$i].ConnectionInfo.ServerPlatformNumber -eq 9)
    {
        if($($dmiLinkFrequencyVallidValues | where {$_ -eq $dmiLinkFrequencyList[$i]}) -ne $null)
        {
            $dmiLinkFrequencyToSet += $dmiLinkFrequencyList[$i]
        }
        else
        {
            Write-Host "Invalid value for IntelDMILinkFrequency"
            Write-Host "Exit...."
            exit
        }
    }
}

Write-Host "Changing processor power configuration....." -ForegroundColor Green

$failureCount = 0
for ($i = 0 ;$i -lt $ListOfConnection.Count ; $i++)
{
        if($ListOfConnection[$i].ConnectionInfo.ServerPlatformNumber -eq 9)
        {
            $setResult = $ListOfConnection[$i] | Set-HPBIOSProcessorPower -MinimumProcessorIdlePowerCoreState $processorCoreStateToSet[$i] -MinimumProcessorIdlePowerPackageState $processorPowerPackageToSet[$i] -EnergyPerformanceBias $energyPeroformanceBiasToSet[$i] -DynamicPowerSavingsModeResponse $dynamicPowerSavingToSet[$i] -CollaborativePowerControl $collaborativePowerToSet[$i] -IntelDMILinkFrequency $dmiLinkFrequencyToSet[$i]
        }
        else
        {
             $setResult = $ListOfConnection[$i] | Set-HPBIOSProcessorPower -MinimumProcessorIdlePowerCoreState $processorCoreStateToSet[$i] -MinimumProcessorIdlePowerPackageState $processorPowerPackageToSet[$i] -EnergyPerformanceBias $energyPeroformanceBiasToSet[$i] -DynamicPowerSavingsModeResponse $dynamicPowerSavingToSet[$i] -CollaborativePowerControl $collaborativePowerToSet[$i]
        }

        if($setResult.StatusType -eq "Error")
        {
            Write-Host ""
            Write-Host "Processor power configuration Cannot be changed"
            Write-Host "Server : $($setResult.IP)"
            Write-Host "Error : $($setResult.StatusMessage)"
            $failureCount++
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
        $result = $serverConnection | Get-HPBIOSProcessorPower
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