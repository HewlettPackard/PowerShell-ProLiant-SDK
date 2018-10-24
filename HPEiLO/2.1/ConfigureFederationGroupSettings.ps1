####################################################################
#Federation group management
####################################################################

<#
.Synopsis
    This script allows user to add Federation Group with full priviliges,get/set the federation multicast details.

.DESCRIPTION
    This script allows user to to add Federation Group with full priviliges,get/set the federation multicast details.
	
	The cmdlets used from HPEiLOCmdlets module in the script are stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Add-HPEiLOFederationGroup, Get-HPEiLOFederationGroup, Disconnect-HPEiLO, Set-HPEiLOFederationMulticast, Get-HPEiLOFederationMulticast, Disable-HPEiLOLog

.PARAMETER GroupName
	Specifies the federation Group Name to be added.

.PARAMETER GroupKey
	Specifies the GroupKey for the group name.

.PARAMETER iLOConfigPrivilege
	Specifes whether iLO Config privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER LoginPrivilege
	Specifes whether user has login privilege or no. Valid values are "Yes", "No". Default value is "Yes".

.PARAMETER RemoteConsolePrivilege
	Specifes whether Remote Console Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER UserConfigPrivilege
	Specifes whether User Config Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER VirtualPowerAndResetPrivilege
	Specifes whether Virtual Power And Reset Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER VirtualMediaPrivilege
	Specifes whether Virtual Media Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER HostBIOSConfigPrivilege
	Specifes whether Host BIOS Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER HostNICConfigPrivilege
	Specifes whether Host NIC Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER HostStorageConfigPrivilege
	Specifes whether Host Storage Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER SystemRecoveryConfigPrivilege
	Specifes whether System Recovery Config Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER MulticastScope
	Use this option to set the multicastscope to Site, Link or organisation.

.PARAMETER MulticastTTL
	Sets the time to live, limiting the number of switches that can be traversed before the multicast discovery is stopped

.PARAMETER DiscoveryAuthentication
	Use this option to enable or disable the discovery authentication.

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\ConfigureFederationGroupSettings.ps1 -GroupName "GroupDemo" -GroupKey "demoKey" -MulticastScope Link -DiscoveryAuthentication Yes -MulticastTTL 120
	
	This script takes the required input and creates federation group with the above settings for the given iLO's.

.INPUTS
	iLOInput.csv file in the script folder location having iLO IPv4 address, iLO Username and iLO Password.

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 2.1.0.0
    Date    : 04/15/2018 

.LINK
    http://www.hpe.com/servers/powershell
#>

#Command line parameters
Param(

    [Parameter(Mandatory=$true)]
    [string[]]$GroupName, 
    [Parameter(Mandatory=$true)]
    [string[]]$GroupKey, 
	[ValidateSet("Yes","No")]
    [string[]]$iLOConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$LoginPrivilege="Yes",
    [ValidateSet("Yes","No")]
    [string[]]$RemoteConsolePrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$UserConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$VirtualPowerAndResetPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$VirtualMediaPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$HostBIOSConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$HostNICConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$HostStorageConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$SystemRecoveryConfigPrivilege="No",
    [ValidateSet("Site", "Link", "Organization")]
    [Parameter(Mandatory=$true)]
    [string[]]$MulticastScope,
    [ValidateRange(1,255)]
    [Parameter(Mandatory=$true)]
    [string[]]$MulticastTTL,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Disabled", "30", "60", "120", "300", "600", "900", "1800")]
    [string[]]$AnnouncementInterval

    )
try
{
    $path = Split-Path -Parent $PSCommandPath
    $path = join-Path $path "\iLOInput.csv"
    $inputcsv = Import-Csv $path
	if($inputcsv.IP.count -eq $inputcsv.Username.count -eq $inputcsv.Password.count -eq 0)
	{
		Write-Host "Provide values for IP, Username and Password columns in the iLOInput.csv file and try again."
        exit
	}

    $notNullIP = $inputcsv.IP | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullUsername = $inputcsv.Username | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullPassword = $inputcsv.Password | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
	if(-Not($notNullIP.Count -eq $notNullUsername.Count -eq $notNullPassword.Count))
	{
        Write-Host "Provide equal number of values for IP, Username and Password columns in the iLOInput.csv file and try again."
        exit
	}
}
catch
{
    Write-Host "iLOInput.csv file import failed. Please check the file path of the iLOInput.csv file and try again."
    Write-Host "iLOInput.csv file path: $path"
    exit
}

Clear-Host

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference ="SilentlyContinue"

# script execution started
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "This script allows user to get the federation group and federation multicast settings, configure them and add new group to the federation group.`n" -ForegroundColor Green

#Load HPEiLOCmdlets module
$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEiLOCmdlets"))
{
    Write-Host "Loading module :  HPEiLOCmdlets"
    Import-Module HPEiLOCmdlets
    if(($(Get-Module -Name "HPEiLOCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEiLOCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstallediLOModule  =  Get-Module -Name "HPEiLOCmdlets"
    Write-Host "HPEiLOCmdlets Module Version : $($InstallediLOModule.Version) is installed on your machine."
    Write-host ""
}

$Error.Clear()

#Enable logging feature
Write-Host "Enabling logging feature" -ForegroundColor Yellow
$log = Enable-HPEiLOLog
$log | fl

if($Error.Count -ne 0)
{ 
	Write-Host "`nPlease launch the PowerShell in administrator mode and run the script again." -ForegroundColor Yellow 
	Write-Host "`n****** Script execution terminated ******" -ForegroundColor Red 
	exit 
}	

try
{
	$ErrorActionPreference = "SilentlyContinue"
	$WarningPreference ="SilentlyContinue"

    [bool]$isParameterCountEQOne = $false;

    foreach ($key in $MyInvocation.BoundParameters.keys)
    {
        $count = $($MyInvocation.BoundParameters[$key]).Count
        if($count -ne 1 -and $count -ne $inputcsv.Count)
        {
            Write-Host "The input paramter value count and the input csv IP count does not match. Provide equal number of IP's and parameter values." -ForegroundColor Red    
            exit;
        }
        elseif($count -eq 1)
        {
            $isParameterCountEQOne = $true;
        }

    }
    Write-Host "`nConnecting using Connect-HPEiLO`n" -ForegroundColor Yellow
    $connection = Connect-HPeiLO -IP $inputcsv.IP -Username $inputcsv.Username -Password $inputcsv.Password -DisableCertificateAuthentication
	
	$Error.Clear()

    if($Connection -eq $null)
    {
        Write-Host "`nConnection could not be established to any target iLO.`n" -ForegroundColor Red
        $inputcsv.IP | fl
        exit;
    }

    if($Connection.count -ne $inputcsv.IP.count)
    {
        #List of IP's that could not be connected
        Write-Host "`nConnection failed for below set of targets" -ForegroundColor Red
        foreach($item in $inputcsv.IP)
        {
            if($Connection.IP -notcontains $item)
            {
                $item | fl
            }
        }

        #Prompt for user input
        $mismatchinput = Read-Host -Prompt 'Connection object count and parameter value count does not match. Do you want to continue? Enter Y to continue with script execution. Enter N to cancel.'
        if($mismatchinput -ne 'Y')
        {
            Write-Host "`n****** Script execution stopped ******" -ForegroundColor Yellow
            exit;
        }
    }

    
    foreach($connect in $connection)
    {

        Write-Host "`nAdding the Federation Group for $($connect.IP)." -ForegroundColor Green

        if($isParameterCountEQOne)
        {
            $appendText= " -GroupName " +$GroupName
            foreach ($key in $MyInvocation.BoundParameters.keys)
            {
               if($key -match "Privilege" -or $key -eq "GroupKey")
               {
                    $appendText +=" -"+$($key)+" "+$($MyInvocation.BoundParameters[$key])
               }
            }
        }
        else
        {
            $index = $csv.IP.IndexOf($connect.IP)
            $appendText= " -GroupName " +$GroupName[$index]
            foreach ($key in $MyInvocation.BoundParameters.keys)
            {
               if($key -match "Privilege" -or $key -eq "GroupKey")
               {
                    $value = $($MyInvocation.BoundParameters[$key])
                    $appendText +=" -"+$($key)+" "+$value[$index]
               }
            }
        }
        
        #executing the cmdlet Add-HPEiLODirectoryGroup 
        $cmdletName = "Add-HPEiLOFederationGroup"
        $expression = $cmdletName + " -connection $" + "connect" +$appendText
        $output = Invoke-Expression $expression

        #checking for cmdlet failure
        if($output.StatusInfo -ne $null)
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to add federation group for $($output.IP): "$message -ForegroundColor Red
        }

        Write-Host "`nGetting the added federation group info." -ForegroundColor Green
        if($isParameterCountEQOne)
        {
            $output = Get-HPEiLOFederationGroup -Connection $connect -GroupName $GroupName
        }
        else
        {
            $output = Get-HPEiLOFederationGroup -Connection $connect -GroupName $GroupName[$index]
        }
       
        #displaying Directory Group information
        if($output.Status -ne "OK")
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to get federation group info for $($output.IP): "$message -ForegroundColor Red
        }
        else
        {  Write-Host "`nFederation group info for $($output.IP)." -ForegroundColor Green; $output | Out-String }
        

        Write-Host "`nModifying Federation Multicast settings." -ForegroundColor green
        if($isParameterCountEQOne)
        {
            $output = Set-HPEiLOFederationMulticast -Connection $connect -DiscoveryAuthentication Yes -MulticastScope $MultiCastScope -MulticastTTL $MulticastTTL -AnnouncementInterval $AnnouncementInterval
        }
        else
        {
            $output = Set-HPEiLOFederationMulticast -Connection $connect -DiscoveryAuthentication Yes -MulticastScope $MultiCastScope[$index] -MulticastTTL $MulticastTTL[$index] -AnnouncementInterval $AnnouncementInterval[$index]
        }

        if($output.StatusInfo -ne $null)
        {  
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to set federation multicast info for $($output.IP): "$message -ForegroundColor Red 
                
        }
        
         Write-Host "`nGetting the Federation Multicast settings" -ForegroundColor green
         $output = Get-HPEiLOFederationMulticast -Connection $connect

        if($output.Status -eq "OK")
        {
                
            Write-Host "`nFederation multicast information for $($output.IP)" -ForegroundColor Green
            $output | out-string
        }
        else
        {
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to get federation multicast information for $($output.IP): "$message -ForegroundColor Red 
        }
    }
   
 }
 catch
 {
 }
finally
{
    if($connection -ne $null)
    {
        #Disconnect 
		Write-Host "Disconnect using Disconnect-HPEiLO `n" -ForegroundColor Yellow
		$disconnect = Disconnect-HPEiLO -Connection $Connection
		$disconnect | fl
		Write-Host "All connections disconnected successfully.`n"
    }  
	
	#Disable logging feature
	Write-Host "Disabling logging feature`n" -ForegroundColor Yellow
	$log = Disable-HPEiLOLog
	$log | fl
	
	if($Error.Count -ne 0 )
    {
        Write-Host "`nScript executed with few errors. Check the log files for more information.`n" -ForegroundColor Red
    }
	
    Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
}