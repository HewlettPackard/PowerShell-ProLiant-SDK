####################################################################
#Managing Install Set of iLO using Install set cmdlets
####################################################################

<#
.Synopsis
    This Script allows user to manage install set for HPE ProLiant servers. This sample script is for iLO 5.

.DESCRIPTION
    This Script allows user to manage install set for HPE ProLiant servers. This sample script is for iLO 5.
	In order to create the install set, the component has to present in the iLO Repository.
	
	Use ComponentRepositoryManagement.ps1 sample script to add the component in the iLO Repository.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Find-HPEiLO, Connect-HPEiLO, Get-HPEiLORepositoryComponent, Add-HPEiLOInstallSet, Get-HPEiLOInstallSet, Invoke-HPEiLOInstallSet, Remove-HPEiLOInstallSet, Clear-HPEiLOInstallSet, Disconnect-HPEiLO, Disable-HPEiLOLog

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\InstallSetManagement.ps1
	
	This script does not take any parameter.
    
.INPUTS
	iLOInput.csv, InstallSetInput.csv file in the script folder location.

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
	This sample script is designed for creation/invoke/deletion of single installset for single or multiple targets iLO's.
	
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 01/15/2020

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
	if(-Not($inputcsv.count -eq $notNullIP.Count -eq $notNullUsername.Count -eq $notNullPassword.Count))
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

try
{
	$path = Split-Path -Parent $PSCommandPath
    $path = join-Path $path "\InstallSetInput.csv"
    $installsetinputcsv = Import-Csv $path
}
catch
{
    Write-Host "InstallSetInput.csv file import failed. Please check the file path of the InstallSetInput.csv file and try again."
	Write-Host "InstallSetInput.csv file path: $installsetinputcsv"
    exit
}

Clear-Host

Write-Host "Validating the install set input `n"

foreach($item in $installsetinputcsv)
{
    if("" -eq $item.Command -or  "" -eq $item.UpdatableBy -or "" -eq $item.ComponentName)
    {
        Write-Host "Install set input validaion failed. Check the install set input csv file"
        break;
    }
}

Write-Host "Completed validating the install set input `n"

$update = New-Object System.Collections.ArrayList($installsetinputcsv.Count)

foreach($item in $installsetinputcsv)
{
    [string[]]$updateCommand = $item.UpdatableBy.Split(';')
    $update += ,$updateCommand
}

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
        $iLOVersion = $connect.TargetInfo.iLOGeneration -replace '\w+\D+',''
        
        switch($iLOVersion)
        {
            3 {
                Write-Host "$($connect.IP) : Install set feature is not supported in iLO 3 `n" -ForegroundColor Yellow
            }
            4 {
                Write-Host "$($connect.IP) : Install set feature is not supported in iLO 4 `n" -ForegroundColor Yellow
            }
            5 {
                $getRepositoryComponent = $connect | Get-HPEiLORepositoryComponent 
                if($getRepositoryComponent.RepositoryComponentInformation.Count -eq 0)
                {
                    Write-Host "$($connect.IP) : The iLO Repository Component is empty. Try the script after adding a component in iLO repository `n" -ForegroundColor Yellow    
                    continue;
                }

                #Adding Install set 
                Write-Host "$($connect.IP) : Adding install set using Add-HPEiLOInstallSet `n" -ForegroundColor Yellow
                $addInstallSet = Add-HPEiLOInstallSet -Connection $connect -Name $installsetinputcsv[0].Name -Command $installsetinputcsv.Command -Filename $installsetinputcsv.Filename -ComponentName $installsetinputcsv.ComponentName -UpdatableBy $update
                $addInstallSet | fl

                if($null -ne $addInstallSet)
                {
                   $addInstallSet.StatusInfo | fl 
                   Write-Host "$($connect.IP) : Add install set failed `n" -ForegroundColor Red
                   break;
                }
                Write-Host "$($connect.IP) : Adding install set completed successfully `n" -ForegroundColor Green


                #Get Install set 
                Write-Host "$($connect.IP) : Getting install set information using Get-HPEiLOInstallSet `n" -ForegroundColor Yellow
                $getInstallSet = Get-HPEiLOInstallSet -Connection $connect 
                $getInstallSet | fl

                if($getInstallSet.Status -contains "Error")
                {
                   $getInstallSet.StatusInfo | fl 
                   break;
                }
                else
                {
                    $getInstallSet.InstallSetInfo | fl
                    foreach($item in $getInstallSet.InstallSetInfo)
                    {
                        if($item.Name -eq $installsetinputcsv[0].Name)
                        {
                            $item.Sequence | fl
                            break;
                        }
                    }
                }
                Write-Host "$($connect.IP) : Get install set completed successfully `n" -ForegroundColor Green

                #Invoke Install set 
                Write-Host "$($connect.IP) : Invoking install set using Invoke-HPEiLOInstallSet `n" -ForegroundColor Yellow
                $res = Get-Date
                $startDate = $res.AddDays(10).ToString("yyyy-MM-dd")
                $endDate = $res.AddDays(11).ToString("yyyy-MM-dd")
                $invokeInstallSet = Invoke-HPEiLOInstallSet -Connection $connect -Name $installsetinputcsv[0].Name -StartAfter $startDate -Expire $endDate
                $invokeInstallSet | fl

                if($null -ne $invokeInstallSet)
                {
                   $invokeInstallSet.StatusInfo | fl 
                   Write-Host "$($connect.IP) : Invoke install set failed `n" -ForegroundColor Red
                   break;
                }
                Write-Host "$($connect.IP) : Invoke install set completed successfully `n" -ForegroundColor Green

                #Remove Install set 
                Write-Host "$($connect.IP) : Removing install set using Remove-HPEiLOInstallSet `n" -ForegroundColor Yellow
                $removeInstallSet = Remove-HPEiLOInstallSet -Connection $connect -Name $installsetinputcsv[0].Name
                $removeInstallSet | fl

                if($null -ne $removeInstallSet)
                {
                   $removeInstallSet.StatusInfo | fl 
                   break;
                }
                Write-Host "$($connect.IP) : Remove install set completed successfully `n" -ForegroundColor Green

                #Clear Install set 
                Write-Host "$($connect.IP) : Clearing install set using Clear-HPEiLOInstallSet `n" -ForegroundColor Yellow
                $ClearInstallSet = Clear-HPEiLOInstallSet -Connection $connect 
                $ClearInstallSet | fl

                if($null -ne $ClearInstallSet)
                {
                   $ClearInstallSet.StatusInfo | fl 
                   break;
                }
                Write-Host "$($connect.IP) : Clear install set completed successfully `n" -ForegroundColor Green
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