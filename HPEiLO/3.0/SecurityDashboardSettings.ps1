####################################################################
#iLO Security Dashboard Information
####################################################################

<#
.Synopsis
    This Script sets the security dashboard settings to the given value and retrieves the same.

.DESCRIPTION
    This Script sets the security dashboard settings to the given value and retrieves the same.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Set-HPEiLOLicense, Get-HPEiLOLicense, Disconnect-HPEiLO, Disable-HPEiLOLog

.PARAMETER Key
    Specifies the security dashboard settings to be updated in iLO.

.EXAMPLE
    
    PS C:\HPEiLOCmdlets\Samples\> .\SecurityDashboardSettings.ps1 
	
    This script takes the required input and updates the iLO license key.
 
.INPUTS
	iLOInput.csv file in the script folder location having iLO IPv4 address, iLO Username and iLO Password.

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 01/15/2020 

.LINK
    http://www.hpe.com/servers/powershell
#>

#Command line parameters
Param(

    [switch]$IgnoreSecureBoot,
    [switch]$IgnoreSecurityOverrideSwitch,
    [switch]$IgnorePasswordComplexity,
    [switch]$IgnoreIPMIDCMIOverLAN,
    [switch]$IgnoreMinimumPasswordLength,
    [switch]$IgnoreRequireLoginforiLORBSU,
    [switch]$IgnoreAuthenticationFailureLogging,
    [switch]$IgnoreLastFirmwareScanResult,
    [switch]$IgnoreRequireHostAuthentication
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

# script execution started
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "This script sets the security dashboard settings to the given value and gets the same.`n"

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

    foreach ($Key in $MyInvocation.BoundParameters.keys)
    {
        $count = $($MyInvocation.BoundParameters[$Key]).Count        

    }
    Write-Host "`nConnecting using Connect-HPEiLO`n" -ForegroundColor Yellow

    $connection = Connect-HPEiLO -IP $inputcsv.IP -Username $inputcsv.Username -Password $inputcsv.Password -DisableCertificateAuthentication
	
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
        $appendText = ""
        Write-Host "`nGetting Security Dashboard information for $($connect.IP)" -ForegroundColor Green
     
        #executing the cmdlet Enable-HPEiLOSecurityDashboardSetting 
        $cmdletName = "Enable-HPEiLOSecurityDashboardSetting -IgnoreSecurityOverrideSwitch -IgnoreSecureBoot -IgnoreMinimumPasswordLength -IgnoreRequireLoginforiLORBSU -IgnoreLastFirmwareScanResult -IgnorePasswordComplexity" 
        $expression = $cmdletName + " -connection $" + "connect"
        $output = Invoke-Expression $expression

        if($output.StatusInfo -ne $null)
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to Enable security dashboard settings for $($output.IP): "$message -ForegroundColor Red
            if($message -contains "Feature not supported.")
            { continue; }
        }
        else
        {
            Write-Host "`nEnable security dashboard settings for $($connect.IP) successful !" -ForegroundColor Green
        }

        Write-Host "`nGetting the security dashboard info for $($connect.IP)" -ForegroundColor Green
        $output = Get-HPEiLOSecurityDashboardInfo -Connection $connect
       
        #Displaying security dashboard info

        if($output.Status -ne "OK")
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to get security dashboard info for $($output.IP): "$message -ForegroundColor Red
        }
        else
        {  
            $output.SecurityParameters | Select-Object Id, Name, SecurityStatus, State, Ignore | ft  
        }  

        #executing the cmdlet Disable-HPEiLOSecurityDashboardSetting 
        $cmdletName = "Disable-HPEiLOSecurityDashboardSetting -IgnoreSecurityOverrideSwitch -IgnoreSecureBoot -IgnoreMinimumPasswordLength -IgnoreRequireLoginforiLORBSU -IgnoreLastFirmwareScanResult -IgnorePasswordComplexity"
        $expression = $cmdletName + " -connection $" + "connect"
        $output = Invoke-Expression $expression

        if($output.StatusInfo -ne $null)
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to Disable security dashboard settings for $($output.IP): "$message -ForegroundColor Red
            if($message -contains "Feature not supported.")
            { continue; }
        }
        else
        {
            Write-Host "`nDisable security dashboard settings for $($connect.IP) successful !" -ForegroundColor Green
        }

        Write-Host "`nGetting the security dashboard info for $($connect.IP)" -ForegroundColor Green
        $output = Get-HPEiLOSecurityDashboardInfo -Connection $connect
       
        #Displaying security dashboard info

        if($output.Status -ne "OK")
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to get security dashboard info for $($output.IP): "$message -ForegroundColor Red
        }
        else
        {  
            $output.SecurityParameters | Select-Object Id, Name, SecurityStatus, State, Ignore | ft  
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