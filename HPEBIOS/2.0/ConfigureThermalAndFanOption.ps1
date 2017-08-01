##############################################################
#Configuring the thermal option and fan
##########################################################----#
<#
.Synopsis
    This Script allows user to configure thermal and fan failure policy for HPE Proliant Gen 9 servers

.DESCRIPTION
    This script allows user to configure fan cooling and fan failure policy.Following features can be configured.
    ThermalConfiguration       :-  Use this option to set fan cooling
    ExtendedAmbientTemperatureSupport :- Use this option to enable the server to work at higer ambient temprature.
    FanFailurePolicy   :- Use this option to configure how server will behave when fan fail.
    FanInstallationRequirement :- Use this option to configure how server reacts when all required fans are not installed.
    ThermalShutdown :- option to configure the system to shut down when a fan failure occurs in non-redundant fan mode 

.EXAMPLE
    ConfigureThermalAndFanOption.ps1
    This mode of exetion of script will prompt for 
    
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    ThermalConfiguration   :- Accepted values are IncreasedCooling , MaximumCooling and OptimalCooling.
    
    ExtendedAmbientTemperatureSupport :- Accepted values are ASHRAE4, ASHARE3 and Disabled.
    
    FanFailurePolicy :-  Accepted values are "Allow" and "Shutdown" 
    
    FanInstallationRequirement :- Accepted values are EnableMessaging and DisableMessaging.
    
    ThermalShutdown :- Accepted values are "Enabled" and "Disabled".

.EXAMPLE
    ConfigureThermalAndFanOption.ps1 -Address "10.20.30.40" -Credential $userCredential -ThermalConfiguration OptimalCooling -ExtendedAmbientTemperatureSupport ASHRAE3 -FanInstallationRequirement EnableMessaging -FanFailurePolicy Shutdown

    This mode of script have input parameter for Address, Credential, ThermalConfiguration, FanFailurePolicy and FanInstallationRequirement
    
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user Credential.In the case of multiple servers use same credential for all the servers
    
    -ThermalConfiguration :- Use this Parameter to specify thermal configuration. Accepted values are IncreasedCooling , MaximumCooling and OptimalCooling.
    
    -ExtendedAmbientTemperatureSupport :- Use this parameter to specify extended ambient temprature.Accepted values are ASHRAE4,ASHARE3 and Disabled. 
    
    -FanFailurePolicy :- Use this parameter to specify fan failure policy.  Accepted values are Allow and Shutdown 
    
    -FanInstallationRequirement :- Use this parameter to specify fan installation requirement.Accepted values are EnableMessaging and DisableMessaging.
    
    -ThermalShutdown :- use this parameter to specify thermal shutdown.

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    ThermalConfiguration
    ExtendedAmbientTemperatureSupport
    FanFailurePolicy
    FanInstallationRequirement
    ThermalShutdown

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
    #In the case of multiple servers it use same credential for all the servers
    [PSCredential]$Credential,
    #Use this Parameter to specify thermal configuration. Accepted values are IncreasedCooling , MaximumCooling and OptimalCooling. 
    [String[]]$ThermalConfiguration, 
    #Use this parameter to specify extended ambient temprature.Accepted values are ASHRAE4,ASHARE3 and Disabled. 
    [string[]]$ExtendedAmbientTemperatureSupport,
    #Use this parameter to specify fan failure policy.  Accepted values are Allow and Shutdown 
    [string[]]$FanFailurePolicy,
    #Use this parameter to specify fan installation requirement.Accepted values are EnableMessaging and DisableMessaging.
    [string[]]$FanInstallationRequirement,
    #use this parameter to specify thermal shutdown.
    [string[]]$ThermalShutdown 
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

Write-Host "This script allows user to configure fan cooling and fan failure policy.Following features can be configured."
Write-Host "Thermal Configuration"
Write-Host "Extended Ambient Temperature Support"
Write-Host "Fan Failure Policy"
Write-Host "Fan Installation Requirement"
Write-Host "Thermal Shutdown"
Write-Host ""

#dont shoe error in scrip

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
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

#Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

#Create connection object
[array]$ListOfConnection = @()
$connection = $null
[int] $connectionCount = 0

foreach($IPAddress in $ListOfAddress)
{
    
    Write-Host ""
    Write-Host "Connecting to server  : $IPAddress"
    $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential
    
     #Retry connection if it is failed because  of invalid certificate with -DisableCertificateAuthentication switch parameter
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
            Write-Host "This script is not supported on the target server $($connection.IP)"
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

# Get current thermal configuration and fan failure policy

Write-Host ""
Write-Host "Current thermal and fan failure configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
        $thermalResult = $serverConnection | Get-HPEBIOSThermalOption
        $fanResult = $serverConnection | Get-HPEBIOSFanOption
        
        $returnObject = New-Object psobject
        $returnObject | Add-Member NoteProperty IP         $thermalResult.IP
        $returnObject | Add-Member NoteProperty Hostname   $thermalResult.Hostname
        $returnObject | Add-Member NoteProperty ThermalConfiguration  $thermalResult.ThermalConfiguration
        $returnObject | Add-Member NoteProperty  ExtendedAmbientTemperatureSupport $thermalResult.ExtendedAmbientTemperatureSupport
        $returnObject | Add-Member NoteProperty  ThermalShutdown $thermalResult.ThermalShutdown
        $returnObject | Add-Member NoteProperty  FanFailurePolicy $fanResult.FanFailurePolicy
        $returnObject | Add-Member NoteProperty  FanInstallationRequirement $fanResult.FanInstallationRequirement

        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $returnObject
        $CurrentThermalFanConfiguration += $returnObject
        $counter++
}

# Get the valid value list fro each parameter
$thermalParameterMetaData = $(Get-Command -Name Set-HPEBIOSThermalOption).Parameters
$thermalConfigurationValidValue = $($thermalParameterMetaData["ThermalConfiguration"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$ExtendedAmbientValidValue = $($thermalParameterMetaData["ExtendedAmbientTemperatureSupport"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$ThermalShutdownValidValue = $($thermalParameterMetaData["ThermalShutdown"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

$FanFailureParameterMetaData = $(Get-Command -Name Set-HPEBIOSFanOption).Parameters
$FanFailurePolicyValidValue = $($FanFailureParameterMetaData["FanFailurePolicy"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$FanInstallationRequirementValidValue = $($FanFailureParameterMetaData["FanInstallationRequirement"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

if($ThermalConfiguration.Count -eq 0)
{
    $tempThermalConfiguration = Read-Host "Enter ThermalConfiguration [Accepted values : ($($thermalConfigurationValidValue -join ","))]"
    $ThermalConfiguration = $tempThermalConfiguration.Trim().Split(',')
    IF($ThermalConfiguration.Count -eq 0){
        Write-Host "ThermalConfiguration value is not provided`nExit....."
        Exit
    }
}

if($ExtendedAmbientTemperatureSupport.Count -eq 0)
{
     $tempExtendedAmbientTemperatureSupport = Read-Host "Enter ExtendedAmbientTemperatureSupport [Accepted values : ($($ExtendedAmbientValidValue -join ","))]"
     $ExtendedAmbientTemperatureSupport = $tempExtendedAmbientTemperatureSupport.Trim().Split(',')
     if($ExtendedAmbientTemperatureSupport.Count -eq 0){
         Write-Host "ExtendedAmbientTemperatureSupport value is not provided`nExit....."
            Exit
     }
}

if($FanFailurePolicy.Count -eq 0)
{
    $tempFanFailurePolicy = Read-Host "Enter FanFailurePolicy [Accepted values ($($FanFailurePolicyValidValue -join ","))]"
    $FanFailurePolicy = $tempFanFailurePolicy.Trim().Split(',')
    if($FanFailurePolicy.Count -eq 0){
        Write-Host "FanFailurePolicy value is not provided`nExit....."
            Exit
    }
}

if($FanInstallationRequirement.Count -eq 0)
{
    $tempFanInstallationRequirement = Read-Host "Enter FanInstallationRequirement [Accepted values : ($($FanInstallationRequirementValidValue -join ","))]"
    $FanInstallationRequirement = $tempFanInstallationRequirement.Trim().Split(',')
    if($FanInstallationRequirement -eq 0){
            Write-Host "FanInstallationRequirement value is not provided`nExit....."
            Exit
    }
}

if($ThermalShutdown.Count -eq 0)
{
    $tempThermalShutDown = Read-Host "Enter ThermalShutdown [Accepted values : ($($ThermalShutdownValidValue -join ","))"
    $ThermalShutdown = $tempThermalShutDown.Trim().Split(',')
    if($ThermalShutdown.Count -eq 0){
        Write-Host "ThermalShutdown value is not provided`nExit....."
            Exit
    }
}


for($i = 0 ; $i -lt $ThermalConfiguration.Count ;$i++)
{
    
    #validate Thermal configuration
    if($($thermalConfigurationValidValue | where{$_ -eq $ThermalConfiguration[$i] }) -eq $null)
    {
       Write-Host "Invalid value for ThermalConfiguration" -ForegroundColor Red
       Write-Host "Exit...."
       exit
    }
}

for($i =0 ;$i -lt $ExtendedAmbientTemperatureSupport.Count; $i++ )
{
    #validate extended ambient temprature
    if($($ExtendedAmbientValidValue | where {$_ -eq $ExtendedAmbientTemperatureSupport[$i]}) -eq $null)
    {
        Write-Host "Invalid value for ExtendedAmbientTemperatureSupport" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

for($i =0 ;$i -lt $FanFailurePolicy.Count; $i++ )
{
    #validate fan failure values
    if($($FanFailurePolicyValidValue | where {$_ -eq $FanFailurePolicy[$i]}) -eq $null)
    {
         Write-Host "Invalid value for FanFailurePolicy" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}
 
for($i =0 ;$i -lt $FanInstallationRequirement.Count; $i++ )
{
    #validate fan installation requirement values
    if($($FanInstallationRequirementValidValue | where {$_ -eq $FanInstallationRequirement[$i]}) -eq $null)
    {
        Write-Host "Invalid value for FanIinstallationRequirement" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}   

for($i =0 ;$i -lt $ThermalShutdown.Count; $i++ )
{
    #validate thermal shutdown values
    if($($ThermalShutdownValidValue | where {$_ -eq $ThermalShutdown[$i]}) -eq $null)
    {
        Write-Host "Invalid value for ThermalShutdown" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing thermal and fan failure configuration....." -ForegroundColor Green  
$failureCount = 0

if($ListOfConnection.Count -ne 0)
{
    $setThermalResult =  Set-HPEBIOSThermalOption -Connection $ListOfConnection -ThermalConfiguration $ThermalConfiguration -ExtendedAmbientTemperatureSupport $ExtendedAmbientTemperatureSupport -ThermalShutdown $ThermalShutdown
    $setFanResult  =  Set-HPEBIOSFanOption -Connection $ListOfConnection -FanInstallationRequirement $FanInstallationRequirement -FanFailurePolicy $FanFailurePolicy
    
    for($i = 0; $i -lt $setThermalResult.Count ; $i++)
    {    
        if(($setThermalResult[$i].Status -eq "Error"))
        {
            Write-Host ""
            Write-Host "Thermal and fan configuration cannot be changed"
            Write-Host "Server : $($setThermalResult[$i].IP)"
            Write-Host "Error : $($($setThermalResult[$i]).StatusInfo)"
		    Write-Host "StatusInfo.Category : $($setThermalResult[$i].StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($setThermalResult[$i].StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($setThermalResult[$i].StatusInfo.AffectedAttribute)"
            $failureCount++
        }

        if(($setFanResult[$i].Status -eq "Error"))
        {
            Write-Host ""
            Write-Host "Fan configuration cannot be changed"
            Write-Host "Server : $($setFanResult[$i].IP)"
            Write-Host "Error : $($($setFanResult[$i]).StatusInfo)"
		    Write-Host "StatusInfo.Category : $($setFanResult[$i].StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($setFanResult[$i].StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($setFanResult[$i].StatusInfo.AffectedAttribute)"
        }

    }
}


if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "Thermal and fan failure configuration successfully changed" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $thermalResult = $serverConnection | Get-HPEBIOSThermalOption
        $fanResult = $serverConnection | Get-HPEBIOSFanOption
       
        $returnObject = New-Object psobject
        $returnObject | Add-Member NoteProperty IP         $thermalResult.IP
        $returnObject | Add-Member NoteProperty Hostname   $thermalResult.Hostname
        $returnObject | Add-Member NoteProperty ThermalConfiguration  $thermalResult.ThermalConfiguration
        $returnObject | Add-Member NoteProperty  ExtendedAmbientTemperatureSupport $thermalResult.ExtendedAmbientTemperatureSupport
        $returnObject | Add-Member NoteProperty  ThermalShutdown $thermalResult.ThermalShutdown
        $returnObject | Add-Member NoteProperty  FanFailurePolicy $fanResult.FanFailurePolicy
        $returnObject | Add-Member NoteProperty  FanInstallationRequirement $fanResult.FanInstallationRequirement
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $returnObject
        $counter ++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit
