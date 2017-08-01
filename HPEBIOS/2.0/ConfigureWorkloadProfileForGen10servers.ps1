##############################################################
#Configuring Workload profile
##########################################################----#

<#
.Synopsis
    This Script allows user to configure work load profile for HPE Proliant Gen10  servers

.DESCRIPTION
    This script allows user to configure work load profile.Following features can be configured.
    WorkloadProfile

.EXAMPLE
    ConfigureWorkloadProfileForGen10.ps1
    This mode of exetion of script will prompt for 
    
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    WorkloadProfile   :- Accepted values are GeneralPowerEfficientCompute, GeneralPeakFrequencyCompute, GeneralThroughputCompute, VirtualizationPowerEfficient, VirtualizationMaximumPerformance, LowLatency, MissionCritical, TransactionalApplicationProcessing, HighPerformanceCompute, DecisionSupport, GraphicProcessing, IOThroughput, WebE-Commerce, ExtremeEfficientCompute, and Custom.
   

.EXAMPLE
    ConfigureWorkloadProfileForGen10.ps1 -Address "10.20.30.40" -Credential $userCredential -WorkloadProfile Custom

    This mode of script have input parameter for Address, Credential, ThermalConfiguration, FanFailurePolicy and FanInstallationRequirement
    
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user Credential.In the case of multiple servers use same credential for all the servers
    
    -WorkloadProfile :- Use this Parameter to specify Workload profile.
    

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 20/07/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    WorkloadProfile

.OUTPUTS
    None (by default)

.LINK
    
   http://www.hpe.com/servers/powershell
   https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    [string[]]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # In the case of multiple servers it use same credential for all the servers
    [String[]]$WorkloadProfile
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

Write-Host "This script allows user to configure Workload profile.Following features can be configured."
Write-Host "Workload Profile"
Write-Host ""

#dont show error in scrip

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
        if($connection.ProductName.Contains("Gen10"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "WorkloadProfile  is not supported on Server $($connection.IP)"
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

# Get current WorkloadProfile

Write-Host ""
Write-Host "Current workload profile" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
        $result = $serverConnection | Get-HPEBIOSWorkloadProfile
        
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $CurrentWorkloadProfile += $result
        $counter++
}

# Get the valid value list fro each parameter
$workloadProfileParameterMetaData = $(Get-Command -Name Set-HPEBIOSWorkloadProfile).Parameters
$workloadProfileValidValues = $($workloadProfileParameterMetaData["WorkloadProfile"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

if($WorkloadProfile.Count -eq 0)
{
    $tempWorkloadProfile = Read-Host "Enter Workload profile [Accepted values : ($($workloadProfileValidValues -join ","))]"
    Write-Host ""
    $WorkloadProfile = $tempWorkloadProfile.Trim().Split(',')

}

if($WorkloadProfile.Count -eq 0)
{
    Write-Host "You have not entered value for parameters"
    Write-Host "Exit....."
    exit
}

for($i = 0 ; $i -lt $WorkloadProfile.Count ;$i++)
{
    
    #validate user input workload profile
    if($($workloadProfileValidValues | where{$_ -eq $WorkloadProfile[$i] }) -eq $null)
    {
        Write-Host "Invalid value for workload profile" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing workload profile ....." -ForegroundColor Green  
$failureCount = 0

if($ListOfConnection.Count -ne 0)
{
    $setResult = Set-HPEBIOSWorkloadProfile -Connection $ListOfConnection -WorkloadProfile $WorkloadProfile
    
    for($i =0; $i -lt $ListOfConnection.Count ; $i++)
    {        
        if(($setResult[$i].Status -eq "Error"))
        {
            Write-Host ""
            Write-Host "Workload profile cannot be changed"
            Write-Host "Server : $($setResult[$i].IP)"
            Write-Host "Error : $($setResult[$i].StatusInfo)"
		    Write-Host "StatusInfo.Category : $($setResult[$i].StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($setResult[$i].StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($setResult[$i].StatusInfo.AffectedAttribute)"
            $failureCount++
        }
    }
}


if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "Workload profile successfully changed" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $workloadProfileResult = $serverConnection | Get-HPEBIOSWorkloadProfile
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $workloadProfileResult
        $counter ++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit
