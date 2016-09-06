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
    FanFailurePolicy :-  Accepted values are Allow and Shutdown 
    FanInstallationRequirement :- Accepted values are EnableMessaging and DisableMessaging.
    ThermalShutdown

.EXAMPLE
    ConfigureThermalAndFanOption.ps1 -Address "10.20.30.40" -Credential $userCredential -ThermalConfiguration OptimalCooling -ExtendedAmbientTemperatureSupport ASHRAE3 -FanInstallationRequirement EnableMessaging -FanFailurePolicy Shutdown

    This mode of script have input parameter for Address, Credential, ThermalConfiguration, FanFailurePolicy and FanInstallationRequirement
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- Use this parameter to sepcify user Credential.
    -ThermalConfiguration :- Use this Parameter to specify thermal configuration. Accepted values are IncreasedCooling , MaximumCooling and OptimalCooling.
    -ExtendedAmbientTemperatureSupport :- Use this parameter to specify extended ambient temprature.Accepted values are ASHRAE4,ASHARE3 and Disabled. 
    -FanFailurePolicy :- Use this parameter to specify fan failure policy.  Accepted values are Allow and Shutdown 
    -FanInstallationRequirement :- Use this parameter to specify fan installation requirement.Accepted values are EnableMessaging and DisableMessaging.
    -ThermalShutdown

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 1.1.0.0
    Date    : 8/8/2016
    
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
    
    http://www8.hp.com/in/en/products/server-software/product-detail.html?oid=5440657
#>



#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # all server should have same ceredntial (in case of multiple addresses)
    [String]$ThermalConfiguration, 
    [string]$ExtendedAmbientTemperatureSupport,
    [string]$FanFailurePolicy,
    [string]$FanInstallationRequirement,
    [string]$ThermalShutdown 
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

#Load HPBIOSCmdlets module
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
            Write-Host "Fan failure configuration is not supported on Server $($connection.IP)"
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
        $thermalResult = $serverConnection | Get-HPBIOSThermalOption
        $fanResult = $serverConnection | Get-HPBIOSFanOption
        $thermalShutdownResult = $serverConnection | Get-HPBIOSServerAvailability
        $returnObject = New-Object psobject
        $returnObject | Add-Member NoteProperty IP         $thermalResult.IP
        $returnObject | Add-Member NoteProperty Hostname   $thermalResult.Hostname
        $returnObject | Add-Member NoteProperty ThermalConfiguration  $thermalResult.ThermalConfiguration
        $returnObject | Add-Member NoteProperty  ExtendedAmbientTemperatureSupport $thermalResult.ExtendedAmbientTemperatureSupport
        $returnObject | Add-Member NoteProperty  ThermalShutdown $thermalShutdownResult.ThermalShutdown
        $returnObject | Add-Member NoteProperty  FanFailurePolicy $fanResult.FanFailurePolicy
        $returnObject | Add-Member NoteProperty  FanInstallationRequirement $fanResult.FanInstallationRequirement

        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $returnObject
        $CurrentThermalFanConfiguration += $returnObject
        $counter++
}

# Take user input for Boot mode
[array]$ThermalConfigurationToset = @()
[array]$ExtendedAmbientTempSupportToSet = @()
[array]$FanFailurePolicyToSet = @()
[array]$FanInstallationReqToSet = @()
[array]$ThermalShutDownToSet = @()

# Get the valid value list fro each parameter
$thermalParameterMetaData = $(Get-Command -Name Set-HPBIOSThermalOption).Parameters
$thermalConfigurationValidValue = $($thermalParameterMetaData["ThermalConfiguration"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$ExtendedAmbientValidValue = $($thermalParameterMetaData["ExtendedAmbientTemperatureSupport"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

$FanFailureParameterMetaData = $(Get-Command -Name Set-HPBIOSFanOption).Parameters
$FanFailurePolicyValidValue = $($FanFailureParameterMetaData["FanFailurePolicy"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$FanInstallationRequirementValidValue = $($FanFailureParameterMetaData["FanInstallationRequirement"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

$ThermalShutdownParametrMetaData = $(Get-Command -Name Set-HPBIOSServerAvailability).Parameters
$ThermalShutdownValidValue = $($ThermalShutdownParametrMetaData["ThermalShutdown"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

if($ThermalConfiguration -eq "")
{
    $ThermalConfiguration = Read-Host "Enter ThermalConfiguration [Accepted values : ($($thermalConfigurationValidValue -join ","))]"
    Write-Host ""
}

if($ExtendedAmbientTemperatureSupport -eq "")
{
     $ExtendedAmbientTemperatureSupport = Read-Host "Enter ExtendedAmbientTemperatureSupport [Accepted values : ($($ExtendedAmbientValidValue -join ","))]"
     Write-Host ""
}

if($FanFailurePolicy -eq "")
{
    $FanFailurePolicy = Read-Host "Enter FanFailurePolicy [Accepted values ($($FanFailurePolicyValidValue -join ","))]"
    Write-Host ""
}

if($FanInstallationRequirement -eq "")
{
    $FanInstallationRequirement = Read-Host "Enter FanInstallationRequirement [Accepted values : ($($FanInstallationRequirementValidValue -join ","))]"
    Write-Host ""
}

if($ThermalShutdown -eq "")
{
    $ThermalShutDown = Read-Host "Enter ThermalShutdown [Accepted values : ($($ThermalShutdownValidValue -join ","))"
    Write-Host ""
}

$ThermalConfigurationList              =  ($ThermalConfiguration.Trim().Split(','))
$ExtendedAmbientTemperatureSupportList =  ($ExtendedAmbientTemperatureSupport.Trim().Split(','))
$FanFailurePolicyList                  =  ($FanFailurePolicy.Trim().Split(','))
$FanInstallationRequirementList        =  ($FanInstallationRequirement.Trim().Split(','))
$ThermalShutDownList                   =  ($ThermalShutDown.Trim().Split(','))

if(($ThermalConfigurationList.Count -eq 0) -and ($ExtendedAmbientTemperatureSupportList.Count -eq 0) -and ($FanFailurePolicyList -eq 0) -and ($FanInstallationRequirementList -eq 0))
{
    Write-Host "You have not entered value for parameters"
    Write-Host "Exit....."
    exit
}

for($i = 0 ; $i -lt $ListOfConnection.Count ;$i++)
{
    
    #validate Thermal configuration
    if($($thermalConfigurationValidValue | where{$_ -eq $ThermalConfigurationList[$i] }) -ne $null)
    {
        $ThermalConfigurationToset += $ThermalConfigurationList[$i];
    }
    else
    {
        Write-Host "Invalid value for ThermalConfiguration" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }


    #validate extended ambient temprature
    if($($ExtendedAmbientValidValue | where {$_ -eq $ExtendedAmbientTemperatureSupportList[$i]}) -ne $null)
    {
        $ExtendedAmbientTempSupportToSet += $ExtendedAmbientTemperatureSupportList[$i]
    }
    else
    {
        Write-Host "Invalid value for ExtendedAmbientTemperatureSupport" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }

    #validate fan failure values
    if($($FanFailurePolicyValidValue | where {$_ -eq $FanFailurePolicyList[$i]}) -ne $null)
    {
        $FanFailurePolicyToSet += $FanFailurePolicyList[$i]
    }
    else
    {
        Write-Host "Invalid value for FanFailurePolicy" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }


    #validate fan installation requirement values
    if($($FanInstallationRequirementValidValue | where {$_ -eq $FanInstallationRequirementList[$i]}) -ne $null)
    {
        $FanInstallationReqToSet += $FanInstallationRequirementList[$i]
    }
    else
    {
        Write-Host "Invalid value for FanIinstallationRequirement" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }



    #validate thermal shutdown values
    if($($ThermalShutdownValidValue | where {$_ -eq $ThermalShutDownList[$i]}) -ne $null)
    {
        $ThermalShutDownToSet += $ThermalShutDownList[$i]
    }
    else
    {
        Write-Host "Invalid value for ThermalShutdown" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }

}

Write-Host "Changing thermal and fan failure configuration....." -ForegroundColor Green  
$failureCount = 0

if($ListOfConnection.Count -eq 1)
{
    $setThermalResult = $ListOfConnection[0] | Set-HPBIOSThermalOption -ThermalConfiguration $ThermalConfigurationToset[0] -ExtendedAmbientTemperatureSupport $ExtendedAmbientTempSupportToSet[0]
    $setFanResult  = $ListOfConnection[0] | Set-HPBIOSFanOption -FanInstallationRequirement $FanInstallationReqToSet[0] -FanFailurePolicy $FanFailurePolicyToSet[0]
    $setThermalShutDown = $ListOfConnection[0] | Set-HPBIOSServerAvailability -ThermalShutdown $ThermalShutDownToSet[0]
        
    if(($setThermalResult.StatusType -eq "Error") -and ($setFanResult.StatusType -eq "Error"))
    {
        Write-Host ""
        Write-Host "Thermal and fan configuration cannot be changed"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.StatusMessage)"
        $failureCount++
    }
}
else
{
    if(($ThermalConfigurationToset.Count -eq 1) -and ($ExtendedAmbientTempSupportToSet.Count -eq 1) -and ($FanInstallationReqToSet.Count -eq 1) -and (($FanFailurePolicyToSet.Count -eq 1)))
    {
       $setThermalResult = $ListOfConnection | Set-HPBIOSThermalOption -ThermalConfiguration $ThermalConfigurationToset[0] -ExtendedAmbientTemperatureSupport $ExtendedAmbientTempSupportToSet[0]
       $setFanResult  = $ListOfConnection | Set-HPBIOSFanOption -FanInstallationRequirement $FanInstallationReqToSet[0] -FanFailurePolicy $FanFailurePolicyToSet[0]
       $setThermalShutDown = $ListOfConnection | Set-HPBIOSServerAvailability -ThermalShutdown $ThermalShutDownToSet[0]
    }
    else
    {
        $setThermalResult = $ListOfConnection | Set-HPBIOSThermalOption -ThermalConfiguration $ThermalConfigurationToset -ExtendedAmbientTemperatureSupport $ExtendedAmbientTempSupportToSet
        $setFanResult  = $ListOfConnection | Set-HPBIOSFanOption -FanInstallationRequirement $FanInstallationReqToSet -FanFailurePolicy $FanFailurePolicyToSet
        $setThermalShutDown = $ListOfConnection | Set-HPBIOSServerAvailability -ThermalShutdown $ThermalShutDownToSet[0]
    }
        
     for($i = 0 ;$i -le $ListOfConnection.Count ; $i++)
     {
        if(($setThermalResultList[$i].StatusType -eq "Error") -and (setFanResultList[$i].StatusType -eq "Error") -and (setThermalShutDownList[$i].StatusType -eq "Error") )
        {
            Write-Host ""
            Write-Host "Thermal and fan configuration cannot be changed"
            Write-Host "Server : $($result.IP)"
            Write-Host "Error : $($result.StatusMessage)"
            $failureCount++
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
        $thermalResult = $serverConnection | Get-HPBIOSThermalOption
        $fanResult = $serverConnection | Get-HPBIOSFanOption
        $thermalShutdownResult = $serverConnection | Get-HPBIOSServerAvailability
        $returnObject = New-Object psobject
        $returnObject | Add-Member NoteProperty IP         $thermalResult.IP
        $returnObject | Add-Member NoteProperty Hostname   $thermalResult.Hostname
        $returnObject | Add-Member NoteProperty ThermalConfiguration  $thermalResult.ThermalConfiguration
        $returnObject | Add-Member NoteProperty  ExtendedAmbientTemperatureSupport $thermalResult.ExtendedAmbientTemperatureSupport
        $returnObject | Add-Member NoteProperty  ThermalShutdown $thermalShutdownResult.ThermalShutdown
        $returnObject | Add-Member NoteProperty  FanFailurePolicy $fanResult.FanFailurePolicy
        $returnObject | Add-Member NoteProperty  FanInstallationRequirement $fanResult.FanInstallationRequirement
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $returnObject
        $counter ++
    }
}
    
Disconnect-HPBIOSAllConnection    
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit
