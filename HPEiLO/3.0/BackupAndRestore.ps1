####################################################################
#Backup and Restore in iLO
####################################################################

<#
.Synopsis
    This Script allows user to take backup and restore setting on HPE Proliant servers. This feature is supported only on iLO 5.

.DESCRIPTION
    This Script allows user to take backup and restore setting on HPE Proliant servers. This feature is supported only on iLO 5.
	iLOIP, Username and Password input is read from iLOInput.csv file placed in the same folder location.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Backup-HPEiLOSetting, Restore-HPEiLOSetting, Disconnect-HPEiLO, Disable-HPEiLOLog
	
.PARAMETER Operation
	This parameter specifies the operation to be performed on the target iLO. Valid values are Backup and Restore.
	Backup: To backup the iLO setting into .bak file
	Restore: To restore the iLO setting from .bak file.
	
.PARAMETER BackupFileLocation
	This parameter allows to specify the back up file location from where the .bak file either has to be loaded or stored depending upon the operation parameter value.
	
.PARAMETER BackupFilePassword
	This parameter allows to specify back up file password. If iLO setting was backed up using password. The same password has to be provided while doing the restore operation of the back up file.
	
.PARAMETER UploadTimeout
	This parameter specifies the http timeout period for the file to be backed up or restored.
		
.EXAMPLE
	PS C:\HPEiLOCmdlets\Samples\> .\BackupAndRestore.ps1 -Operation Backup -BackupFileLocation "C:\Apps\Backup.bak" -BackupFilePassword lock123
	
	Backup the file at the given BackupFileLocation.

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\BackupAndRestore.ps1 -Operation Restore -BackupFileLocation "C:\Apps\Backup.bak" -BackupFilePassword lock123
	
	Restore the file from the given BackupFileLocation.

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
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEiLO
#>

param(
    [ValidateSet("Backup","Restore")]
    [ValidateNotNullorEmpty()]
    [Parameter(Mandatory=$true)]
    [string]$Operation, 

    [ValidateNotNullorEmpty()]
    [Parameter(Mandatory=$true)]
    [string[]]$BackupFileLocation, #BackupFileLocationValueToSet

    [ValidateNotNullorEmpty()]
    [Parameter(Mandatory=$false)]
    [string[]]$BackupFilePassword, #BackupFilePasswordValueToSet

    [ValidateNotNullorEmpty()]
    [Parameter(Mandatory=$false)]
    [UInt32[]]$UploadTimeout #UploadTimeoutValueToSet
    
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

    if(($null -ne $inputcsv.Count -and ($BackupFileLocation.Count -ne $inputcsv.Count)) -or ($null -ne $BackupFilePassword -and $BackupFilePassword.Count -ne $BackupFileLocation.Count) -or ($null -ne $UploadTimeout -and $UploadTimeout.Count -ne $BackupFileLocation.Count))
    {
        Write-Host "The input paramter value count and the input csv IP count does not match. Provide equal number of IP's and parameter values." -ForegroundColor Red    
        exit;
    }

    if($Operation -eq "Backup" -and $UploadTimeout -ne $null)
    {
       Write-Host "Backup setting does not support UploadTimeout parameter." -ForegroundColor Red    
       exit; 
    }

    $reachableIPList = Find-HPEiLO $inputcsv.IP -WarningAction SilentlyContinue
    Write-Host "The below list of IP's are reachable."
    $reachableIPList.IP

    #Connect to the reachable IP's using the credential
    $reachableData = @()
    foreach($ip in $reachableIPList.IP)
    {
        $index = $inputcsv.IP.IndexOf($ip)
        $inputObject = New-Object System.Object

        $inputObject | Add-Member -type NoteProperty -name IP -Value $ip
        $inputObject | Add-Member -type NoteProperty -name Username -Value $inputcsv[$index].Username
        $inputObject | Add-Member -type NoteProperty -name Password -Value $inputcsv[$index].Password

        $reachableData += $inputObject
    }

    Write-Host "`nConnecting using Connect-HPEiLO`n" -ForegroundColor Yellow
    $Connection = Connect-HPEiLO -IP $reachableData.IP -Username $reachableData.Username -Password $reachableData.Password -DisableCertificateAuthentication -WarningAction SilentlyContinue
	
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

    if($Operation -eq "Backup")
    {
        foreach($connect in $Connection)
        {
            Write-Host "$($connect.IP) : Taking backup Backup-HPEiLOSetting cmdlet `n" -ForegroundColor Yellow
            $errorcount = $Error.Count
            if($BackupFileLocation.Count -eq 1)
            {
                if($null -eq $BackupFilePassword)
                {
                    $backup = Backup-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation
                }
                else
                {
                    $backup = Backup-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation -BackupFilePassword $BackupFilePassword
                }
            }
            else
            {
                $backupindex = $inputcsv.IP.IndexOf($connect.IP)
                if($null -eq $BackupFilePassword)
                {
                    $backup = Backup-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation[$backupindex]
                }
                else
                {
                    $backup = Backup-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation[$backupindex] -BackupFilePassword $BackupFilePassword[$backupindex]
                }
            }
            $backup | fl

            if($null -ne $backup)
            {
                $backup.StatusInfo | fl 
                if($backup.Status -contains "Error")
                {
                    Write-Host "$($connect.IP) : Taking back up Failed. Check the log files for more information. `n" -ForegroundColor Red
                    continue;
                }
            }
            if($errorcount -eq $Error.Count)
            {
                Write-Host "$($connect.IP) : Taking back up completed successfully `n" -ForegroundColor Green    
            }
        }
    }
    else
    {
        foreach($connect in $Connection)
        {
            Write-Host "$($connect.IP) : Restore iLO setting Restore-HPEiLOSetting cmdlet `n" -ForegroundColor Yellow
            $errorcount = $Error.Count

            if($BackupFileLocation.Count -eq 1)
            {
                if($null -eq $BackupFilePassword -and $null -eq $UploadTimeout)
                {
                    $restore = Restore-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation
                }
                elseif($null -ne $BackupFilePassword -and $null -eq $UploadTimeout)
                {
                    $restore = Restore-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation -BackupFilePassword $BackupFilePassword
                }
                elseif($null -eq $BackupFilePassword -and $null -ne $UploadTimeout)
                {
                    $restore = Restore-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation -UploadTimeout $UploadTimeout
                }
                else
                { 
                    $restore = Restore-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation -BackupFilePassword $BackupFilePassword -UploadTimeout $UploadTimeout
                }
            }
            else
            {
                $backupindex = $inputcsv.IP.IndexOf($connect.IP)
                if($null -eq $BackupFilePassword -and $null -eq $UploadTimeout)
                {
                    $restore = Restore-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation[$backupindex]
                }
                elseif($null -ne $BackupFilePassword -and $null -eq $UploadTimeout)
                {
                    $restore = Restore-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation[$backupindex] -BackupFilePassword $BackupFilePassword[$backupindex]
                }
                elseif($null -eq $BackupFilePassword -and $null -ne $UploadTimeout)
                {
                    $restore = Restore-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation[$backupindex] -UploadTimeout $UploadTimeout[$backupindex]
                }
                else
                { 
                    $restore = Restore-HPEiLOSetting -Connection $connect -BackupFileLocation $BackupFileLocation[$backupindex] -BackupFilePassword $BackupFilePassword[$backupindex] -UploadTimeout $UploadTimeout[$backupindex]
                }
            }
            $restore | fl

            if($null -ne $backup)
            {
                $restore.StatusInfo | fl 
                if($restore.Status -contains "Error")
                {
                    Write-Host "$($connect.IP) : Restore iLO setting Failed. Check the log files for more information. `n" -ForegroundColor Red
                    continue;
                }
            }
            if($errorcount -eq $Error.Count)
            {
                Write-Host "$($connect.IP) : Restore iLO setting completed successfully `n" -ForegroundColor Green    
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