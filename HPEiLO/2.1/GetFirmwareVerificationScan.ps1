####################################################################
#Firmware verification scan
####################################################################

<#
.Synopsis
    This Script allows user to do the firmware verification scan. This feature is supported only on iLO 5.

.DESCRIPTION
    This Script allows user to perform the firmware verification scan, view scan result and also trigger the system recovery event for HPE ProLiant servers.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Find-HPEiLO, Connect-HPEiLO, Get-HPEiLOFirmwareVerificationLastScanResult, Invoke-HPEiLOFirmwareVerificationScan, Send-HPEiLOSystemRecoveryEvent, Disconnect-HPEiLO, Disable-HPEiLOLog

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\GetFirmwareVerificationScan.ps1
	
	This script does not take any parameter.

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
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEiLO
#>

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

    foreach($connect in $Connection)
    {
        $iLOVersion = $connect.iLOGeneration -replace '\w+\D+',''
        
        switch($iLOVersion)
        {
            3 {
                Write-Host "$($connect.IP) : The script is not supported in iLO 3 `n" -ForegroundColor Yellow
            }
            4 {
                Write-Host "$($connect.IP) : The script is not supported in iLO 4 `n" -ForegroundColor Yellow
            }
            5 {
                #Get firmwarescanresult 
                Write-Host "$($connect.IP) : Getting FirmwareVerificationLastScanResult information using Get-HPEiLOFirmwareVerificationLastScanResult cmdlet `n" -ForegroundColor Yellow
                $getfirmwarescanresult = Get-HPEiLOFirmwareVerificationLastScanResult -Connection $connect
                $getfirmwarescanresult | fl

                if($getfirmwarescanresult.Status -contains "Error")
                {
                    $getfirmwarescanresult.StatusInfo | fl 
                    Write-Host "$($connect.IP) : Getting FirmwareVerificationLastScanResult information Failed `n" -ForegroundColor Red
                }
                else
                {
                    Write-Host "$($connect.IP) : Get FirmwareVerificationLastScanResult information completed successfully `n" -ForegroundColor Green
                }

                #InvokeScan
                Write-Host "$($connect.IP) : Invoke firmware verification scan using Invoke-HPEiLOFirmwareVerificationScan cmdlet `n" -ForegroundColor Yellow
                $invokescan = Invoke-HPEiLOFirmwareVerificationScan -Connection $connect
                $invokescan | fl

                if($invokescan.Status -contains "Error")
                {
                   $invokescan.StatusInfo | fl 
                   Write-Host "$($connect.IP) : Invoke firmware verification scan Failed `n" -ForegroundColor Red
                }
                else
                {
                    Write-Host "$($connect.IP) : Invoke firmware verification scan completed successfully `n" -ForegroundColor Green
                    if($invokescan.ScanResult -ne "OK")
                    {
                        $mismatchinput = Read-Host -Prompt 'Scan result is not "OK". Do you want to send recovery event? Enter Y to continue with script execution. Enter N to cancel.'
                        if($mismatchinput -ne 'Y')
                        {
                            Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
                            exit;
                        } 
                        #InvokeScanrecoveryevent
                        Write-Host "$($connect.IP) : Send recovery event scan using Send-HPEiLOSystemRecoveryEvent cmdlet `n" -ForegroundColor Yellow
                        $invokerecovery = Send-HPEiLOSystemRecoveryEvent -Connection $connect
                        $invokerecovery | fl

                        if($invokescan.Status -contains "Error")
                        {
                            $invokescan.StatusInfo | fl 
                            Write-Host "$($connect.IP) : Invoke firmware verification scan Failed `n" -ForegroundColor Red
                        }
                        else
                        {
                            Write-Host "$($connect.IP) : Invoke firmware verification scan information completed successfully `n" -ForegroundColor Green
                        }
                    }
                }

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