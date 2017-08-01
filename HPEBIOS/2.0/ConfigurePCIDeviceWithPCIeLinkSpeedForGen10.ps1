########################################################
#Configure PCI Device on Gen10 servers
###################################################----#

<#
.Synopsis
    This Script allows user to configure PCI device for HPE Proliant Gen10 servers

.DESCRIPTION
    This script allows user to configure PCI device.Following features can be configured. This script works for single server at a time.
    PCIDeviceEnable/PCIDeviceDisable
    PCIeLinkSpeed
    
.EXAMPLE
    ConfigurePCIDeviceWithPCIeLinkSpeedForGen10.ps1
    This mode of exetion of script will prompt for 
   
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
   
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
   
    PCIDevice   :- Accepted values are listed under enum [HPE.BIOS.PCIDeviceForGen10].
   
    PCIeLinkSpeed :- Accepted values are listed under enum [HPE.BIOS.PCIeLinkSpeed].
      

.EXAMPLE
    ConfigurePCIDeviceWithPCIeLinkSpeedForGen10.ps1 -Address "10.20.30.40" -Credential $userCredential -PCIDevice @(,@("EmbeddedNIC","EmbeddedSAS1")) -PCIeLinkSpeed @(,@("Auto")) -EnablePCIDevice

    This mode of script have input parameter for Address, Credential, ThermalConfiguration, FanFailurePolicy and FanInstallationRequirement
   
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server.
   
    -Credential :- Use this parameter to sepcify user Credential.
   
    -PCIDevice :- Use this Parameter to specify PCIDevice.
   
    -PCIeLinkSpeed : - This parameter to specify PCIeLinkSpeed.
   
    -EnablPCIDevice :- Switch parameter to enable PCI device.
   
    -DisablePCIDevice :- Switch parameter to disable PCI device.
       
    

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 21/07/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    PCIDevice
    PCIeLinkSpeed
    

.OUTPUTS
    None (by default)

.LINK
    
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s),
    [PSCredential]$Credential, # credential for server
    [String[]]$PCIDevice,
    [String[]]$PCIeLinkSpeed,
    [Switch]$EnablePCIDevice,
    [Switch]$DisablePCIDevice
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

Write-Host "This script allows user to configure PCI Device on one target server.Following features can be configured."
Write-Host "Enabled and Disabled the PCI device"
Write-Host "Configure the PCIeLinkSpeed for the input PCIDevice"
Write-Host ""
Write-Host "This script works for single server at a time." -ForegroundColor Yellow

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

if($Address -eq "")
{
    $tempAddress = Read-Host "Enter single Server address (IP or Hostname)."

    if($tempAddress -ne "")
    {
        $Address = $tempAddress.Split(',')
    }
    else{
        Write-Host "You have not entered IP(s) or Hostname(s)"
        Write-Host "`nExit ..."
        exit
    }

}
    

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password"
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
            Write-Host "Get/Set-HPEBIOSPCIDeviceConfiguration  is not supported on server $($connection.IP)"
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
    Write-Host "`nExit"
    exit
}

# Get current PCIDeviceConfiguration

Write-Host "`nCurrent PCI Device Configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
        $getResult = $serverConnection | Get-HPEBIOSPCIDeviceConfiguration
        
        Write-Host "-------------------Server $($getResult.IP) -------------------" -ForegroundColor Yellow
        Write-Host ""
        $getResult.PCIDevice
        $CurrentPCIDeviceConfiguration += $getResult
        $counter++
}


# Get the valid value list fro each parameter
$workloadProfileParameterMetaData = $(Get-Command -Name Set-HPEBIOSWorkloadProfile).Parameters
$workloadProfileValidValues = $($workloadProfileParameterMetaData["WorkloadProfile"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

$PCIDeviceValidValues = [System.Enum]::GetNames([HPE.BIOS.PCIDeviceForGen10])
$PCIeLInkSpeedValidValues = [System.Enum]::GetNames([HPE.BIOS.PCIeLinkSpeed])

if($PCIDevice.Count -eq 0)
{
    $tempPCIDevice = Read-Host "Enter PCI device name [Accepted values : $($getResult.PCIDevice.Name -join ",")] "
    Write-Host ""
    if($tempPCIDevice -ne "")
    {
        $PCIDevice = $tempPCIDevice.Split(',')
    }
    else{
        Write-Host "No PCI device is provided"
        Write-Host "Exit....."
        exit
    }
}

if($PCIeLinkSpeed.Count -eq 0)
{
    $tempPCIeLinkSpeed = Read-Host "Enter PCIe link speed [Accepted values : $($PCIeLInkSpeedValidValues -join ",")]"
    Write-Host ""
    if($tempPCIeLinkSpeed -ne "")
    {
        $PCIeLinkSpeed = $tempPCIeLinkSpeed.Split(',')
    }
}


for($i = 0 ; $i -lt $PCIDevice.Count ;$i++)
{
    
    #validate user input PCIDevice
    if($($PCIDeviceValidValues | where{$_ -eq $PCIDevice[$i] }) -eq $null)
    {
        Write-Host "Invalid PCI device name" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

for($i = 0 ; $i -lt $PCIeLinkSpeed.Count ;$i++)
{
    #validate user input PCIeLinkSpeed
    if($($PCIeLInkSpeedValidValues | where{$_ -eq $PCIeLinkSpeed[$i] }) -eq $null)
    {
        Write-Host "Invalid PCIeLinkSpeed value" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Configuring PCIDevice ....." -ForegroundColor Green  
$failureCount = 0
$cmdletInput = New-Object -TypeName psobject

if($PCIeLinkSpeed.Count -ne 0)
{
    $cmdletInput | Add-Member "PCIDevice" @(,$PCIDevice)
    $cmdletInput | Add-Member "PCIeLinkSpeed" @(,$PCIeLinkSpeed)
}
else
{
   $cmdletInput | Add-Member "PCIDevice" @(,$PCIDevice) 
}

if($ListOfConnection.Count -ne 0)
{
    if($EnablePCIDevice){

        $setResult = $cmdletInput | Set-HPEBIOSPCIDeviceConfiguration -Connection $ListOfConnection -EnablePCIDevice
    }
    elseif($DisablePCIDevice){

        $setResult = $cmdletInput | Set-HPEBIOSPCIDeviceConfiguration -Connection $ListOfConnection -DisablePCIDevice
    }
    else
    {
        $setResult = Set-HPEBIOSPCIDeviceConfiguration -Connection $ListOfConnection
    }
    
        if($setResult -ne $null -and ($setResult.Status -eq "Error"))
        {
            Write-Host ""
            Write-Host "PCI device configuration cannot be changed"
            Write-Host "Server : $($setResult.IP)"
            Write-Host "Error : $($setResult.StatusInfo)"
		    Write-Host "StatusInfo.Category : $($setResult.StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($setResult.StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($setResult.StatusInfo.AffectedAttribute)"
            $failureCount++
        }
}


if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "PCI device configuration successfully changed" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $getResult = $serverConnection | Get-HPEBIOSPCIDeviceConfiguration
        Write-Host "-------------------Server $($getResult.IP)-------------------" -ForegroundColor Yellow
        Write-Host ""
        $getResult.PCIDevice
        $counter ++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit
