####################################################################
#Boot mode configuration in iLO
####################################################################

<#
.Synopsis
    This Script allows user to use Boot mode configuration on HPE Proliant servers.

.DESCRIPTION
    This Script allows user to use Boot mode configuration on HPE Proliant servers.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Get-HPEiLOBootMode, Set-HPEiLOBootMode, Disconnect-HPEiLO, Disable-HPEiLOLog

.PARAMETER BootMode
	Specifies the boot mode for the BIOS. Valid values are UEFI, LegacyBIOS.

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\BootConfiguration.ps1 -BootMode UEFI
	
	This script takes BootMode as the parameter.

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
param(
    [ValidateSet("LegacyBios","UEFI")]
    [ValidateNotNullorEmpty()]
    [Parameter(Mandatory=$true)]
    [string[]]$BootMode #BootModeValueToSet
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

    if($bootMode.Length -ne 1 -and ($null -ne $inputcsv.Count -and $bootMode.Length -ne $inputcsv.Count))
    {
        Write-Host "The input paramter value count and the input csv IP count does not match. Provide equal number of IP's and parameter values." -ForegroundColor Red    
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
	
    foreach($connect in $Connection)
    {
        #Get Boot mode information
        Write-Host "$($connect.IP) : Getting Boot mode information using Get-HPEiLOBootMode cmdlet `n" -ForegroundColor Yellow
        $getBoot = Get-HPEiLOBootMode -Connection $connect
        $getBoot | fl

        if($getBoot.Status -contains "Error")
        {
            $getBoot.StatusInfo | fl 
            Write-Host "$($connect.IP) : Getting Boot mode information Failed `n" -ForegroundColor Red
            continue;
        }
        Write-Host "$($connect.IP) : Get Boot mode information completed successfully `n" -ForegroundColor Green    

        Write-Host "$($connect.IP) : Setting Boot mode using Set-HPEiLOBootMode cmdlet `n" -ForegroundColor Yellow
        
        if($bootMode.Count -eq 1)
        {
            $setBoot = Set-HPEiLOBootMode -Connection $connect -PendingBootMode $bootMode
        }
        else
        {
            $bootmodeindex = $inputcsv.IP.IndexOf($connect.IP)
            $setBoot = Set-HPEiLOBootMode -Connection $connect -PendingBootMode $bootMode[$bootmodeindex]
        }
        $setBoot | fl

        if($null -ne $setBoot)
        {
            $setBoot.StatusInfo | fl 
            if($setBoot.Status -contains "Error")
            {
                Write-Host "$($connect.IP) : Setting Boot mode Failed `n" -ForegroundColor Red
                continue;
            }
        }
        
        Write-Host "$($connect.IP) : Set Boot mode completed successfully `n" -ForegroundColor Green    

        #Get Boot mode information
        Write-Host "$($connect.IP) : Getting Boot mode information using Get-HPEiLOBootMode cmdlet `n" -ForegroundColor Yellow
        $getModifiedBoot = Get-HPEiLOBootMode -Connection $connect
        $getModifiedBoot | fl

        if($getModifiedBoot.Status -contains "Error")
        {
            $getModifiedBoot.StatusInfo | fl 
            Write-Host "$($connect.IP) : Getting Boot mode information Failed `n" -ForegroundColor Red
            continue;
        }
        Write-Host "$($connect.IP) : Get Boot mode information completed successfully `n" -ForegroundColor Green    
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