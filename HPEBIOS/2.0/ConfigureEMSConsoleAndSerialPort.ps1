#######################################################
#Configuring VirtualSerialPort, EmbeddedSerialPort and 
# EMSConsole
###################################################----#

<#
.Synopsis
    This script allows user to configure EMS console and serial port of HPE Proliant servers (Gen 9 and Gen 8)

.DESCRIPTION
    This script allows user to configure EMS console and serial port.Following features can be configured
    Virtual Serial Port
    Embedded Serial Port
    EMS Console 

.EXAMPLE
    ConfigureEMSConsoleAndSerialPort.ps1
    This mode of exetion of script will prompt for 
     
     Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
     
     Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
     
     VirtualSerialPort :- it wll prompt for virual serial port.
     
     EmbeddedSerialPort :- it wll prompt for embedded serial port.
     
     EMSConsole  :- it wll prompt for EMS console port.

.EXAMPLE 
    ConfigureEMSConsoleAndSerialPort.ps1 -Address "10.20.30.40,10.25.35.45" -Credential $userCrdential -VirtualSerialPort "COM2_IRQ3,COM1_IRQ4" -EmbeddedSerialPort "COM1_IRQ4,COM2_IRQ3" -EMSConsole "COM2 PhysicalSerialPort"

    This mode of script have input parameters for Address, Credential and ResetBIOSSetting
    
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user credential.#In case of multiple servers use same credential for all the servers
    
    -VirtualSerialPort  :- specify virtual serial port.
    
    -EmbeddedSerialPort :- specify embedded serial port.
    
    -EMSConsole  :- specify EMS console port.
    
.NOTES
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    VirtualSerialPort
    EmbeddedSerialPort
    EMSConsole

.OUTPUTS
    None (by default)

.LINK
    
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>

#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, #In case of multiple servers it use same credential for all the servers
    [string]$VirtualSerialPort,
    [string]$EmbeddedSerialPort,
    [string]$EMSConsole
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

Write-Host "This script allows user to configure EMS console and serial port. User can configure followings."
Write-Host "Virtual Serial Port"
Write-Host "Embedded Serial Port"
Write-Host "EMS Console"
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
foreach($serverAddress in $ListOfAddress)
{
    
    Write-Host "Connecting to server  : $serverAddress"
    Write-Host ""
    $connection = Connect-HPEBIOS -IP $serverAddress -Credential $Credential 
                  
    #Retry connection if it is failed because of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "The underlying connection was closed")
    {
       $connection = Connect-HPEBIOS -IP $serverAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
    {
        Write-Host "Connection established to the server $serverAddress" -ForegroundColor Green
        Write-Host ""
        $connection
        $ListOfConnection += $connection
    }
    else
    {
        Write-Host "Connection cannot be eastablished to the server : $serverAddress" -ForegroundColor Red
		Disconnect-HPEBIOS -Connection $connection
    }
}

if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit..."
    Write-Host ""
    exit
}

# Get current EMS console and serial port configuration
Write-Host ""
Write-Host "Current EMS console and serial port configuration." -ForegroundColor Green

Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
    $getEMSResult = $serverConnection | Get-HPEBIOSEMSConsole
    $getSerialPortResult = $serverConnection | Get-HPEBIOSSerialPort
    Write-Host "------------------------Server $counter------------------------" -ForegroundColor Yellow
    Write-Host ""
    $returnObject = New-Object psobject
    $returnObject | Add-Member NoteProperty IP                        $getEMSResult.IP
    $returnObject | Add-Member NoteProperty Hostname                   $getEMSResult.Hostname
    $returnObject | Add-Member NoteProperty VirtualSerialPort          $getSerialPortResult.VirtualSerialPort
    $returnObject | Add-Member NoteProperty EmbeddedSerialPort         $getSerialPortResult.EmbeddedSerialPort
    $returnObject | Add-Member NoteProperty EMSConsole                 $getEMSResult.EMSConsole
    $returnObject
    $counter++
}

# Get the valid value list fro each parameter
$EMSParameterMetaData = $(Get-Command -Name Set-HPEBIOSEMSConsole).Parameters
$SerialPortParameterData = $(Get-Command -Name Set-HPEBIOSSerialPort).Parameters

$virtualSerialPortValidValues =  $($SerialPortParameterData["VirtualSerialPort"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$embeddedSerialPortValidValues = $($SerialPortParameterData["EmbeddedSerialPort"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$EMSValidValues = $($EMSParameterMetaData["EMSConsole"].Attributes | Where-Object {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-Host ""
#Prompt for User input if it is not given as script  parameter 
if($VirtualSerialPort -eq "")
{
    
    $VirtualSerialPort = Read-Host "Enter VirtualSerialPort [Accepted values : ($($virtualSerialPortValidValues -join ","))]."
    Write-Host ""
}

if($EmbeddedSerialPort -eq "")
{
    $EmbeddedSerialPort = Read-Host "Enter EmbeddedSerialPort [Accepted Values : ($($embeddedSerialPortValidValues -join ","))]."
    Write-Host ""
}

if($EMSConsole -eq "")
{
    $EMSConsole = Read-Host "Enter EMSConsole [Accepted values : ($($EMSValidValues -join ","))]."
    Write-Host ""
}


# split the input value.
$VirtualSerialPortList = ($VirtualSerialPort.Trim().Split(','))
$EmbeddedSerialPortList = ($EmbeddedSerialPort.Trim().Split(','))
$EMSConsoleList = ($EMSConsole.Trim().Split(','))

#Validate user input and add to ToSet List to set the values
[array]$VirtualSerialPortToSet = @()
[array]$EmbeddedSerialPortToSet = @()
[array]$EMSConsoleToSet = @()


if(($VirtualSerialPortList.Count -eq 0)  -and ($EmbeddedSerialPortList.Count -eq 0) -and ($EMSConsoleList.Count -eq 0))
{
    Write-Host "You have not enterd parameter value"
    Write-Host "Exit....."
    exit
}


for($i = 0; $i -lt $ListOfConnection.Count ;$i++)
{
     
    if($($virtualSerialPortValidValues | where {$_ -eq $VirtualSerialPortList[$i]}) -ne $null)
    {
        $VirtualSerialPortToSet += $VirtualSerialPortList[$i]
    }
    else
    {
        Write-Host "Inavlid value for VirtualSerialPort".
        Write-Host "Exit...."
        exit
    }

    if($($embeddedSerialPortValidValues | where {$_ -eq $EmbeddedSerialPortList[$i]}) -ne $null)
    {
        $EmbeddedSerialPortToSet += $EmbeddedSerialPortList[$i]
    }
    else
    {
        Write-Host "Inavlid value for EmbeddedSerialPort".
        Write-Host "Exit...."
        exit
    }


    if($($EMSValidValues | where {$_ -eq $EMSConsoleList[$i]}) -ne $null)
    {
        $EMSConsoleToSet += $EMSConsoleList[$i]
    }
    else
    {
        Write-Host "Inavlid value for EMSConsole".
        Write-Host "Exit...."
        exit
    }

}

Write-Host "Changing server EMS console and serial port configuration....." -ForegroundColor Green

$failureCount = 0
for ($i = 0 ;$i -lt $ListOfConnection.Count ; $i++)
{
        $serailPortSetResult = $ListOfConnection[$i] | Set-HPEBIOSSerialPort -EmbeddedSerialPort $EmbeddedSerialPortToSet[$i] -VirtualSerialPort $VirtualSerialPortToSet[$i]
        $EMSSetResult = $ListOfConnection[$i] | Set-HPEBIOSEMSConsole -EMSConsole $EMSConsoleToSet[$i]

        if($EMSSetResult.Status -eq "Error" -and $serailPortSetResult.Status -eq "Error")
        {
            Write-Host ""
            Write-Host "EMS console and serial port Cannot be changed"
            Write-Host "Server : $($EMSSetResult.IP)"
            Write-Host "Error : $($EMSSetResult.StatusInfo)`n $($serailPortSetResult.StatusInfo)"
            $failureCount++
        }
}

if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "Server EMS console and serial port configuration changed successfully" -ForegroundColor Green
    Write-Host ""
}

$counter = 1
foreach($serverConnection in $ListOfConnection)
{
    $getEMSResult = $serverConnection | Get-HPEBIOSEMSConsole
    $getSerialPortResult = $serverConnection | Get-HPEBIOSSerialPort
    Write-Host "------------------------Server $counter------------------------" -ForegroundColor Yellow
    Write-Host ""
    $returnObject = New-Object psobject
    $returnObject | Add-Member NoteProperty IP                        $getEMSResult.IP
    $returnObject | Add-Member NoteProperty Hostname                   $getEMSResult.Hostname
    $returnObject | Add-Member NoteProperty VirtualSerialPort          $getSerialPortResult.VirtualSerialPort
    $returnObject | Add-Member NoteProperty EmbeddedSerialPort         $getSerialPortResult.EmbeddedSerialPort
    $returnObject | Add-Member NoteProperty EMSConsole                 $getEMSResult.EMSConsole
    $returnObject
    $counter++
}

    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit