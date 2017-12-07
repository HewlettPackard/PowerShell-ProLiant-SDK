########################################################
#Install Windows ISO file on Gen10 servers
########################################################

<#
.Synopsis
    This script allows user to install the windows OS on target server.

.DESCRIPTION
    This script allows user to install the windows OS on target server.
    Address :- Use this option to specify the target server IP or hostname.
	
	Credential :- Use this option to specify the target server credentials.
	
	ImageURL :- Use this option to specify the windows ISO image URL path.

.EXAMPLE
    InstallWindowsOS.ps1
    This mode of execution of script will prompt for 
    
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
		
	ImageURL :- Accept the ISO image http or https URL path.
	
.EXAMPLE
	$cred = Get-Credential
	cmdlet Get-Credential at command pipeline position 1
	Supply values for the following parameters:
    InstallWindowsOS.ps1 -Address 10.20.30.1 -Credential $cred -ImageURL http://10.20.30.40/TestImage/WindowsServer2016_datacenter.iso

.EXAMPLE
	$cred = Get-Credential
	cmdlet Get-Credential at command pipeline position 1
	Supply values for the following parameters:
    InstallWindowsOS.ps1 -Address 10.20.30.1,10.20.30.2,10.20.30.3 -Credential $cred -ImageURL http://10.20.30.40/TestImage/WindowsServer2016_datacenter.iso
	
.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 1.0.0.1
    Date    : 27/11/2017
    
.INPUTS
    Inputs to this script file
    Address
	Credential
	ImageURL

.OUTPUTS
    System.Management.Automation.PSObject[]

.LINK
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEOSProvisioning    
    
#>

#Command line parameters
Param(
    [Parameter(Mandatory=$true, Position = 0, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] [string[]] $Address,
    [Parameter(Mandatory=$true, Position = 1, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] [PSCredential] $Credential,
    [Parameter(Mandatory=$true, Position = 2, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] [ValidatePattern('(^$|^https?:\/\/((?:\S+(?::\S*)?@)?(((1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])|(([^:\-\.\/\s]([^:\.\/\s]*[^:\-\.\/\s])?\.)*[a-zA-z][a-zA-Z0-9]*))(:\d{1,5})?|\[([0-9a-fA-F]{0,4}:){2,7}(:|[0-9a-fA-F]{1,4})\])\/[^\s]+\.((i|I)(s|S)(o|O))$)')] [ValidateNotNullOrEmpty()] [string] $ImageURL
)


#Check for server avaibiality
function CheckServerAvailability ($ListOfAddress)
{
    [int] $pingFailureCount = 0
    [array] $PingedServerList = @()
    foreach($serverAddress in $ListOfAddress)
    {
       if(Test-Connection $serverAddress)
       {
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

Write-Host "This script allows user to get the windows image index details in input ISO file."
Write-Host ""


#check powershell supported version
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "4")
{
    Write-Host "Your powershell version : $($PSVersionTable.PSVersion) is valid to execute this script."
    Write-Host ""
}
else
{
    Write-Host "This script required PowerSehll 3 or above."
    Write-Host "Current installed PowerShell version is $($PSVersionTable.PSVersion)."
    Write-Host "Please Update PowerShell version."
    Write-Host ""
    Write-Host "Exit..."
    Write-Host ""
    exit
}

#Load HPEOSProvisionCmdlets module

$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEOSProvisionCmdlets"))
{
    Write-Host "Loading module :  HPEOSProvisionCmdlets"
    Import-Module HPEOSProvisionCmdlets
    if(($(Get-Module -Name "HPEOSProvisionCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEOSProvisionCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
elseif($ModuleNames -like "HPEOSProvisionCmdlets")
{
   $InstalledOSPModule  =  Get-Module -Name "HPEOSProvisionCmdlets"
   Write-Host "HPEOSProvisionCmdlets Module Version : $($InstalledOSPModule.Version) is installed on your machine."
   Write-host "" 
}
else
{
    $InstalledOSPModule  =  Get-Module -Name "HPEOSProvisionCmdlets" -ListAvailable
    Write-Host "HPEOSProvisionCmdlets Module Version : $($InstalledOSPModule.Version) is installed on your machine."
    Write-host ""
}

# Check for IP(s) or Hostname(s) Input. if not available prompt for Input
if($Address.Count -eq 0)
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}

[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)"
    Write-Host ""
    Write-Host "Exit..."
    exit
}

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password(Use same credential for multiple servers)"
    Write-Host ""
}

#Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

Write-Host "Enabling HPEOSProvisioningCmdlets log"
Write-Host ""

Enable-HPEOSPLog -ErrorAction Stop


# create connection object
[array]$ListOfConnection = @()

foreach($IPAddress in $ListOfAddress)
{
    
    Write-Host ""
    Write-Host "Connecting to server  : $IPAddress"
    $connection = Connect-HPEOSP -IP $IPAddress -Credential $Credential
    
    #Retry connection if it is failed because  of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "The underlying connection was closed")
    {
       $connection = Connect-HPEOSP -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
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
            Write-Host "Boot mode is not supported on Server $($connection.IP)"
            Disconnect-HPEOSP -Connection $connection
        }
    }
    else
    {
        Write-Host "Connection cannot be eastablished to the server : $IPAddress" -ForegroundColor Red
    }
}

if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit..."
    Write-Host ""
    exit
}

Write-Host ""
Write-Host "Invoke windows image to install on target servers" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
    $result = Install-HPEOSPWindowsImage -Connection $serverConnection -ImageURL $ImageURL
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}


Write-Host "Disabling HPEOSProvisioningCmdlets log"
Write-Host ""

Disable-HPEOSPLog -ErrorAction Stop

Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit