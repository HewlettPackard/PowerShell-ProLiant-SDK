##############################################################
#Configuring the TPM (Trusted Platform Module)
##########################################################----#

<#
.Synopsis
    This Script allows user to configure TPM configuration for HPE ProLiant Gen10 servers.

.DESCRIPTION
    This script allows user to configure TPM2.0 configuration.Following features can be configured.
    TPMOperation
    TPMVisibility
    TPMUEFIOptionROMMeasurement

    Note :- This script is only supported on Gen10 servers with TPM20

.EXAMPLE
    ConfigureTPM20.ps1
    This mode of exetion of script will prompt for 
    
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    TPMOperation   :- Accepted values are Clear and NoAction.
    
    TPMVisibility :- Accepted values Hidden and Visible.
    
    TPMUEFIOptionROMMeasurement :- Accepted values Enabled and Disabled.

.EXAMPLE
    ConfigureTPM20.ps1 -Address "10.20.30.40" -Credential $userCredential -TPMOperation "NoAction" -TPMVisibility Visible -TPMUEFIOptionROMMeasurement Enabled

    This mode of script have input parameter for Address, Credential, ThermalConfiguration, FanFailurePolicy and FanInstallationRequirement
   
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to sepcify user Credential.In the case of multiple servers use same credential for all the servers
    
    -TPMOperation :- Use this Parameter to specify TPM operation.
    
    -TPMVisibility :- Use this parameter to specify TPM visibility.
    
    -TPMUEFIOptionROMMeasurement :- Use this parameter to specify UEFI option ROM measurement
    

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.0.0.0
    Date    : 20/07/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    TPMOperation
    TPMVisibility
    TPMUEFIOptionROMMeasurement

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
    #Use this Parameter to specify TPM operation. 
    [String[]]$TPMOperation,
    #Use this parameter to specify TPM visibility.
    [String[]]$TPMVisibility,
    #Use this parameter to specify UEFI option ROM measurement
    [string[]]$TPMUEFIOptionROMMeasurement
    
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

Write-Host "This script allows user to configure TPM (Trusted Platform Module).Following features can be configured."
Write-Host "TPMOperation"
Write-Host "TPMVisibility"
Write-Host "TPMUEFIOptionROMMeadurement"
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
       
        if($connection.ProductName.Contains("Gen10"))
        {
            $tpmInfo = Get-HPEBIOSTPMChipInfo -Connection $connection
            if($tpmInfo.TPMType -eq "TPM20"){
                $connection
                $ListOfConnection += $connection
            }
            elseif($tpmInfo.TPMType -eq "NoTPM")
            {
                Write-Host "TPM20 chip not installed on the targer server : $($connection.IP)" -ForegroundColor Red
            }
        }
        else{
            Write-Host "This script is not supported on Server $($connection.ProductName)  : $($connection.IP) "
            Write-Host "This script is only supported on Gen10"
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
    exit
}

# Get current WorkloadProfile

Write-Host ""
Write-Host "Current TPM configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
        $result = $serverConnection | Get-HPEBIOSTPMConfiguration
        $Tpm20Result = New-Object -TypeName PSObject 
        $Tpm20Result | Add-Member "IP" $result.IP
        $Tpm20Result | Add-Member "Hostname" $result.Hostname
        $Tpm20Result | Add-Member "TPMoperation" $result.TPM20Operation
        $Tpm20Result | Add-Member "TPMVisibility" $result.TPMVisibility
        $Tpm20Result | Add-Member "TPMUEFIOptionROMMeasurement" $result.TPMUEFIOptionROMMeasurement
        
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $Tpm20Result
        $CurrentTPMConfiguration += $Tpm20Result
        $counter++
}

# Get the valid value list fro each parameter
$TPMCmdletParameterMetaData = $(Get-Command -Name Set-HPEBIOSTPMConfiguration).Parameters
$TPMOperationValidValues = $($TPMCmdletParameterMetaData["TPM20Operation"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$TPMVisibilityValidValues = $($TPMCmdletParameterMetaData["TPMVisibility"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$TPMUEFIOptionROMMeasurementValidValues = $($TPMCmdletParameterMetaData["TPMUEFIOptionROMMeasurement"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

if($TPMOperation.Count -eq 0)
{
    $tempTPMOperation = Read-Host "Enter TPM20 operation [Accepted values : ($($TPMOperationValidValues -join ","))]"
    Write-Host ""
    $TPMOperation = $tempTPMOperation.Split(',')
}

if($TPMVisibility.count -eq 0)
{
    $tempTPMVisibility = Read-Host "Enter TPM20 visibility [Accepted values : ($($TPMVisibilityValidValues -join ","))]"
    $TPMVisibility = $tempTPMVisibility.Split(',')
    Write-Host ""
}

if($TPMUEFIOptionROMMeasurement.Count -eq 0)
{
   $tempTPMUEFIOptionROMMeasurement = Read-Host "Enter UEFI option ROM measurement [Accepted values : ($($TPMUEFIOptionROMMeasurementValidValues -join ","))]"
   $TPMUEFIOptionROMMeasurement = $tempTPMUEFIOptionROMMeasurement.Split(',')
   Write-Host ""
}


if(($TPMOperation.Count -eq 0) -and ($TPMVisibility.Count -eq 0) -and($TPMUEFIOptionROMMeasurement.Count -eq 0))
{
    Write-Host "You have not entered value for any parameter"
    Write-Host "Exit....."
    exit
}

for($i = 0 ; $i -lt $TPMOperation.Count ;$i++)
{
    
    #validate user input for TPMOperation
    if($($TPMOperationValidValues | where{$_ -eq $TPMOperation[$i] }) -eq $null)
    {
        Write-Host "Invalid value for TPMOperation" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

for($i = 0 ; $i -lt $TPMVisibility.Count ;$i++)
{
    
    #validate user input for TPMVisibility
    if($($TPMVisibilityValidValues | where{$_ -eq $TPMVisibility[$i] }) -eq $null)
    {
        Write-Host "Invalid value for TPMVisibility" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

for($i = 0 ; $i -lt $TPMUEFIOptionROMMeasurement.Count ;$i++)
{
    #validate user input for TPMUEFIOptionROMMeasurement
    if($($TPMUEFIOptionROMMeasurementValidValues | where{$_ -eq $TPMUEFIOptionROMMeasurement[$i] }) -eq $null)
    {
        Write-Host "Invalid value for TPMUEFIOptionROMMeasurement" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing TPM20 configuration ....." -ForegroundColor Green  
$failureCount = 0

if($ListOfConnection.Count -ne 0)
{
    $setResult = Set-HPEBIOSTPMConfiguration -Connection $ListOfConnection -TPM20Operation $TPMOperation -TPMVisibility $TPMVisibility -TPMUEFIOptionROMMeasurement $TPMUEFIOptionROMMeasurement
     
    foreach($result in $setResult)
    {       
        if($result -ne $null -and $setResult.Status -eq "Error")
        {
            Write-Host ""
            Write-Host "TPM configuration cannot be cannot be changed"
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
    Write-host "TPM configuration successfully changed" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $result = $serverConnection | Get-HPEBIOSTPMConfiguration
        $Tpm20Result = New-Object -TypeName PSObject 
        $Tpm20Result | Add-Member "IP" $result.IP
        $Tpm20Result | Add-Member "Hostname" $result.Hostname
        $Tpm20Result | Add-Member "TPMoperation" $result.TPM20Operation
        $Tpm20Result | Add-Member "TPMVisibility" $result.TPMVisibility
        $Tpm20Result | Add-Member "TPMUEFIOptionROMMeasurement" $result.TPMUEFIOptionROMMeasurement
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $Tpm20Result
        $counter ++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit
