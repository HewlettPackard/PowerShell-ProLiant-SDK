########################################################
#Connecting to iLO using Connection cmdlets
########################################################

<#
.Synopsis
    This Script allows user to connect to the iLO for HPE ProLiant servers.

.DESCRIPTION
    This Script allows user to connect to the iLO.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Find-HPEiLO, Connect-HPEiLO, Test-HPEiLOConnection, Disconnect-HPEiLO, Disable-HPEiLOLog
	
.PARAMETER ThreadLimit
	Specifies the maximum number of threads that can be spawned by the cmdlets.

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\EstablishingConnection.ps1
  
	This script does not take any parameter. 
	
.INPUTS
	iLOInput.csv file in the script folder location having iLO IPv4/IPv6/Hostname address, iLO Username and iLO Password.

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
    [ValidateNotNullorEmpty()]
    [Parameter(Mandatory=$false)]
    [UInt32[]]$ThreadLimit = 128
    
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

function ConvertTo-IPAddressCompressedForm($target,$outIP) {
    $out = [System.Net.IPAddress]::TryParse($target,[ref]$outIP)
    $out
    $outIP
}

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
	$threadCount = Get-HPEiLOMaxThreadLimit
	
	Write-Host "`nThread count that can be spawned are $threadCount." -ForegroundColor Yellow
	
	#You can change the count values from 64 to 128,256 till 4096
	Write-Host "`nChanging the thread count value to $ThreadLimit." -ForegroundColor Yellow
	
	Set-HPEiLOMaxThreadLimit -MaxThreadLimit 128
	
	Write-Host ("`nThread limit set to $ThreadLimit." -f (Get-HPEiLOMaxThreadLimit)) -ForegroundColor Yellow
	
    Write-Host ("`nConnecting to the given target using Connect-HPEiLO." -f (Get-HPEiLOMaxThreadLimit)) -ForegroundColor Yellow
    $Connection = Connect-HPEiLO -IP $reachableData.IP -Username $reachableData.Username -Password $reachableData.Password -DisableCertificateAuthentication -WarningAction SilentlyContinue

	$Error.Clear()
	
	if($Connection -eq $null)
    {
        Write-Host "`nConnection could not be established to any target iLO." -ForegroundColor Red
        $inputcsv.IP | fl
        exit;
    }
	else
	{
		$Connection | fl 
	}

	#List of IP's that could not be connected
	if($Connection.count -ne $inputcsv.IP.count)
    {
        $connectionIndex = 0;
        Write-Host "`nConnection failed for below set of targets." -ForegroundColor Red
        foreach($item in $inputcsv.IP)
        {
            $outref = $null
            $csvout = ConvertTo-IPAddressCompressedForm $item $outref
            #Validate for compressed IPv6
            if($true -eq $csvout[0])
            {
                $outref = $null
                $connectionout = ConvertTo-IPAddressCompressedForm $Connection.IP[$connectionIndex] $outref
                if( $connectionout[1].IPAddressToString -ne $csvout[1].IPAddressToString)
                {
                    $item | fl
                }
                else
                {
                   $connectionIndex = $connectionIndex+1
                }
            }
            #Validate for Hostname
            else
            {
                if($Connection.Hostname[$connectionIndex] -notcontains $item)
                {
                    $item | fl
                }
                else
                {
                   $connectionIndex = $connectionIndex+1
                }
            }
        }
    }

    #TestConnection
    Write-Host "Test connection using Test-HPEiLOConnection." -ForegroundColor Yellow
    $testConnection = Test-HPEiLOConnection -Connection $Connection
    $testConnection | fl
}
catch
{
}
finally
{
    if($connection -ne $null)
    {
        #Disconnect 
		Write-Host "Disconnect using Disconnect-HPEiLO." -ForegroundColor Yellow
		$disconnect = Disconnect-HPEiLO -Connection $Connection
		$disconnect | fl
		Write-Host "`nAll connections disconnected successfully."
    }  
	
	#Disable logging feature
	Write-Host "`nDisabling logging feature.`n" -ForegroundColor Yellow
	$log = Disable-HPEiLOLog
	$log | fl
	
	if($Error.Count -ne 0 )
    {
        Write-Host "`nScript executed with few errors. Check the log files for more information." -ForegroundColor Red
    }
	
    Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
}