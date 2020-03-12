####################################################################
# Apollo Chassis PowerManagement Settings
####################################################################

<#
.Synopsis
    This Script allows user to get Chassis Power Management setting on HPE Proliant Apollo servers. This feature is supported only on iLO 5.

.DESCRIPTION
    This Script allows users to get Chassis Power Management settings on HPE Proliant servers. This feature is supported only on iLO 5.
	iLOIP, Username and Password input is read from iLOInput.csv file placed in the same folder location.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Get-HPEiLOChassisPowerCalibrationData, Get-HPEiLOChassisPowerZoneConfiguration, Get-HPEiLOChassisPowerCapSetting, Get-HPEiLOChassisPowerRegulatorSetting, Get-HPEiLOChassisPowerNodeInfo, Disconnect-HPEiLO, Disable-HPEiLOLog
	
.PARAMETER OperationType
	This parameter specifies the operation to be performed on the target iLO. Valid values are CalibrationData, PowerZone, PowerCap, PowerRegulator & PowerNode.
	PowerCalibrationData: Gets chassis power calibration data
    PowerZone: Gets chassis powerzone information
    PowerCap: Gets chassis power capping information
    PowerRegulator: Gets chassis power regulator settings
    PowerNode: Gets chassis power node information.

.EXAMPLE
	.\ApolloChassisPowerManagementSettings.ps1 -OperationType CalibrationData
	
	Starting and getting calibration data for the apollo server.

.EXAMPLE
    .\ApolloChassisPowerManagementSettings.ps1 -OperationType PowerZone
	
	Getting powerzone data for the apollo server.

.EXAMPLE
    .\ApolloChassisPowerManagementSettings.ps1 -OperationType PowerRegulator
	
	Getting powerzone data for the apollo server.

.EXAMPLE
    .\ApolloChassisPowerManagementSettings.ps1 -OperationType PowerCap

    Getting power capping information of the apollo server.

.INPUTS
	iLOInput.csv file in the script folder location having iLO IPv5 address, iLO Username and iLO Password.

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
    [ValidateSet("CalibrationData","PowerZone","PowerCap","PowerRegulator","PowerNode")]
    [ValidateNotNullorEmpty()]
    [Parameter(Mandatory=$true)]
    [string]$OperationType    
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
    if($null -eq $reachableData)
    {
        Write-Host "`nCould not reach any of the given target(s)." -ForegroundColor Red
        exit
    }
    Write-Host "`nConnecting using Connect-HPEiLO`n" -ForegroundColor Yellow
    $Connection = Connect-HPEiLO -IP $reachableData.IP -Username $reachableData.Username -Password $reachableData.Password -DisableCertificateAuthentication -WarningAction SilentlyContinue
	
	$Error.Clear()
	
    if($Connection -eq $null)
    {
        Write-Host "`nConnection could not be established to any target iLO." -ForegroundColor Red
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

    #("CalibrationData","PowerZone","PowerCap","PowerRegulator","PowerNode")
    switch ($OperationType) 
    {
        'CalibrationData'
        {
            foreach($connect in $Connection)
            {
                Write-Host "$($connect.IP) : Starting Power calibration settings" -ForegroundColor Yellow
                $errorcount = $Error.Count
            
                $out = Start-HPEiLOChassisPowerCalibrationConfiguration -Connection $connect -ActionType Start -Seconds 70 -EEPROMSaveEnabled Yes -AllZone Yes
                if($out -ne $null )
                {
                    $out.StatusInfo | fl
                    if($calibData.Status -contains "Error")
                    {
                        Write-Host "$($connect.IP) : Chassis Power Calibration failed to start. Check the log files for more information." -ForegroundColor Red
                        continue;
                    }
                }
                $calibData = Get-HPEiLOChassisPowerCalibrationData -Connection $connect
                $calibData | fl
                $calibData.CalibrationData | ft
                $calibData.CalibrationData.ThrottlePeakPower | ft

                if($null -ne $calibData)
                {
                    $calibData.StatusInfo | fl 
                    if($calibData.Status -contains "Error")
                    {
                        Write-Host "$($connect.IP) : Chassis Power Calibration failed. Check the log files for more information." -ForegroundColor Red
                        continue;
                    }
                }

                if($errorcount -eq $Error.Count)
                {
                    Write-Host "$($connect.IP) : Chassis Power Calibration done !!!" -ForegroundColor Green    
                }
            }
            break
        }

        'PowerZone'
        {
            foreach($connect in $Connection)
            {
                Write-Host "$($connect.IP) : Getting Power Zone information `n" -ForegroundColor Yellow
                $errorcount = $Error.Count
            
                $powerZone = Get-HPEiLOChassisPowerZoneConfiguration -Connection $connect 
                $powerZone | fl
                $z = $powerZone.Zone | ft
                $z.Node | ft

                if($null -ne $powerZone)
                {
                    $powerZone.StatusInfo | fl 
                    if($powerZone.Status -contains "Error")
                    {
                        Write-Host "$($connect.IP) : Get Power Zone information failed. Check the log files for more information. `n" -ForegroundColor Red
                        continue;
                    }
                }

                if($errorcount -eq $Error.Count)
                {
                    Write-Host "$($connect.IP) : Get Power Zone information done !!! `n" -ForegroundColor Green    
                }
            }
            break
        }

        'PowerCap'
        {
            foreach($connect in $Connection)
            {
                Write-Host "$($connect.IP) : Getting Power capping settings `n" -ForegroundColor Yellow
                $errorcount = $Error.Count
            
                $powerCap = Get-HPEiLOChassisPowerCapSetting -Connection $connect
                $powerCap | fl
                $powerCap.ActualPowerLimits | ft
                $powerCap.PowerLimitRanges | ft
                $powerCap.PowerLimits | ft

                if($null -ne $powerCap)
                {
                    $powerCap.StatusInfo | fl 
                    if($powerCap.Status -contains "Error")
                    {
                        Write-Host "$($connect.IP) : Getting Power capping settings failed. Check the log files for more information. `n" -ForegroundColor Red
                        continue;
                    }
                }

                if($errorcount -eq $Error.Count)
                {
                    Write-Host "$($connect.IP) : Getting Power capping settings done !!! `n" -ForegroundColor Green    
                }
            }
            break
        }

        'PowerRegulator'
        {
            foreach($connect in $Connection)
            {
                Write-Host "$($connect.IP) : Getting Power Regulator settings `n" -ForegroundColor Yellow
                $errorcount = $Error.Count
            
                $powerReg = Get-HPEiLOChassisPowerRegulatorSetting -Connection $connect 
                $powerReg | fl

                if($null -ne $powerReg)
                {
                    $powerReg.StatusInfo | fl 
                    if($powerReg.Status -contains "Error")
                    {
                        Write-Host "$($connect.IP) : Getting Power Regulator settings failed. Check the log files for more information. `n" -ForegroundColor Red
                        continue;
                    }
                }

                if($errorcount -eq $Error.Count)
                {
                    Write-Host "$($connect.IP) : Get Power Regulator settings done !!! `n" -ForegroundColor Green    
                }
            }
        }    

        'PowerNode'
        {
            foreach($connect in $Connection)
            {
                Write-Host "$($connect.IP) : Getting Power Node Information `n" -ForegroundColor Yellow
                $errorcount = $Error.Count            
  
                $nodeInfo = Get-HPEiLOChassisPowerNodeInfo -Connection $connect
                $nodeInfo | fl
                $nodeInfo.NodeInfoList | ft

                if($null -ne $nodeInfo)
                {
                    $nodeInfo.StatusInfo | fl 
                    if($nodeInfo.Status -contains "Error")
                    {
                        Write-Host "$($connect.IP) : Getting Power Node Information failed. Check the log files for more information. `n" -ForegroundColor Red
                        continue;
                    }
                }

                if($errorcount -eq $Error.Count)
                {
                    Write-Host "$($connect.IP) : Getting Power Node Information done !!! `n" -ForegroundColor Green    
                }
            }
            break
        }

        default
        {
            
            Write-Host "$($connect.IP) : This is an invalid option. Choose a proper Operation Type listed in the validate set list. `n" -ForegroundColor Red
            break
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
