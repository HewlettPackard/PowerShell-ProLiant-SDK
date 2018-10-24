####################################################################
#Update iLO firmware
####################################################################

<#
.Synopsis
    This Script gets the existing firmware details and updates the firmware.

.DESCRIPTION
    This Script gets the existing firmware details and updates the firmware to the given version.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Get-HPEiLOFirmwareInventory, Update-HPEiLOFirmware, Disconnect-HPEiLO, Disable-HPEiLOLog

.PARAMETER Location
    Specifies the location of the firmware file.

.PARAMETER UploadTimeout
    Specifies the time required to upload the firmware file in seconds. Valid values are between range 120 to 1800.

.PARAMETER TPMEnabled
	SwitchParameter to indicate the iLO to continue with firmware update, in case the target iLO has TPM enabled.

.EXAMPLE
    
   PS C:\HPEiLOCmdlets\Samples\> .\UpdateFirmware.ps1 -Location "C:\iLO\Firmwares\iLO5.bin" -UploadTimeout 180 -TPMEnabled
	
   This script takes input parameter for Location, UploadTimeout and TPMEnabled.
 
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
    [string[]]$Location, 
	[ValidateRange(120,1800)]
    [int[]]$UploadTimeout,  
    [Switch]$TPMEnabled

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

Write-Host "This script allows user to get the existing firmware version of iLO or any other firmware and update to the given version.`n"

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

    Write-Host "`nConnecting using Connect-HPEiLO`n" -ForegroundColor Green
    $connection = Connect-HPEiLO -IP $inputcsv.IP -Username $inputcsv.Username -Password $inputcsv.Password -ErrorAction SilentlyContinue -DisableCertificateAuthentication
	
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

       Write-Host "`nGetting existing firmware details for $($connect.IP)." -ForegroundColor Green

       $output = Get-HPEiLOFirmwareInventory -Connection $connect
       
        if($output.Status -eq "OK")
        {
            $fwInventory = @()
            foreach($data in $output.FirmwareInformation)
            {
                $fwInfo = New-Object PSObject 
                if($data.Status.Health -ne $null){ $status = $data.Status.Health } else { $status = $data.Status.State }                                      
                                        
                $fwInfo | Add-Member Noteproperty "Index" $data.Index
                $fwInfo | Add-Member Noteproperty "FirmwareName" $data.FirmwareName
                $fwInfo | Add-Member Noteproperty "FirmwareVersion" $data.FirmwareVersion
                $fwInventory += $fwInfo
                }
                $fwInventory | Out-String
           
        }
        else
        {
            if($output.StatusInfo -ne $null)
            {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to get Firmware Inventory information for $($output.IP): "$message -ForegroundColor Red }
        }
       
        Start-Sleep -Seconds 2

        $confirmValue = $false

        Write-Host "`nUpdating the firmware for $($connect.IP)." -ForegroundColor Green

        if($isParameterCountEQOne)
        {
            $appendText= " -Location " +'"'+$Location+'"'
         
            if($UploadTimeout -ne $null)
            {
                $appendText += " -UploadTimeout $UploadTimeout"
            }
        }
        else
        {
            $index = $inputcsv.IP.IndexOf($connect.IP)
            $appendText= " -Location " +'"'+$Location[$index]+'"'
         
            if($UploadTimeout -ne $null)
            {
                $appendText += " -UploadTimeout " +$UploadTimeout[$index]
            }
        }
        

        if($TPMEnabled)
        {
            $appendText += " -TPMEnabled:$"+"true"
        }

        #Executing cmdlet
        $cmdletName = "Update-HPEiLOFirmware"
        $expression = $cmdletName + " -connection $" + "connect" +$appendText +" -Confirm:$"+"false"
        $output = Invoke-Expression $expression

        if($output.StatusInfo -ne $null)
        {   
            $message = $output.StatusInfo.Message; 
            if($output.Status -eq "ERROR")
            {
                Write-Host "`nFirmware update failed for $($output.IP): "$message -ForegroundColor red
            }
            else
            {
                Write-Host "`nFirmware update Information for $($output.IP): "$message -ForegroundColor Yellow
            }
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