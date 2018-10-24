####################################################################
#Getting Server information using Get-HPEiLOServerInfo cmdlet
####################################################################

<#
.Synopsis
    This Script allows user to get server information for HPE ProLiant servers.

.DESCRIPTION
    This Script allows user to get server information.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Find-HPEiLO, Connect-HPEiLO, Get-HPEiLOServerInfo, Disconnect-HPEiLO, Disable-HPEiLOLog

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\GettingServerInformation.ps1
	
	This script does not take any parameter and gets the server information for the given target iLO's.
    
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
	else
	{
		$Connection | fl 
	}
	
	#List of IP's that could not be connected
	if($Connection.count -ne $reachableIPList.IP.count)
    {
        Write-Host "`nConnection failed for below set of targets" -ForegroundColor Red
        foreach($item in $reachableIPList.IP)
        {
            if($Connection.IP -notcontains $item)
            {
                $item | fl
            }
        }
    }
	
    Write-Host "`nRetrieving server information using Get-HPEiLOServerInfo" -ForegroundColor Yellow
    $getServerInfo = Get-HPEiLOServerInfo -Connection $connection 

    foreach($connect in $Connection)
    {
        $index = $getServerInfo.IP.IndexOf($connect.IP)
        $iLOVersion = $connect.iLOGeneration -replace '\w+\D+',''
        
        switch($iLOVersion)
        {
            4 {
                Write-Host "`nServer information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index]

                Write-Host "`nFan information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].FanInfo | fl

                Write-Host "`nFirmware information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].FirmwareInfo | fl

                Write-Host "`nTemperature information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].TemperatureInfo | fl

                Write-Host "`nPowerSupply information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].PowerSupplyInfo | fl

                Write-Host "`nPowerSupplySummary information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].PowerSupplyInfo.PowerSupplySummary | fl

                Write-Host "`nPowerSupplies information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].PowerSupplyInfo.PowerSupplies | fl

                if($null -ne $getServerInfo[$index].PowerSupplyInfo.PowerDiscoveryServicesiPDUSummary)
                {
                    Write-Host "`nPowerDiscoveryServicesiPDUSummary information of $($connect.IP)" -ForegroundColor Yellow
                    $getServerInfo[$index].PowerSupplyInfo.PowerDiscoveryServicesiPDUSummary | fl    
                }

                Write-Host "`nMemory information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].MemoryInfo | fl

                if($null -eq $out.MemoryInfo.MemoryComponent)
                {
                    Write-Host "`nAdvancedMemoryProtection information of $($connect.IP)" -ForegroundColor Yellow
                    $getServerInfo[$index].MemoryInfo.AdvancedMemoryProtection | fl

                    Write-Host "`nMemoryDetailsSummary information of $($connect.IP)" -ForegroundColor Yellow
                    $getServerInfo[$index].MemoryInfo.MemoryDetailsSummary | fl

                    Write-Host "`nMemoryDetails information of $($connect.IP)" -ForegroundColor Yellow
                    $getServerInfo[$index].MemoryInfo.MemoryDetails | fl
                   
                    Write-Host "`nMemoryData information of $($connect.IP)" -ForegroundColor Yellow
                    $getServerInfo[$index].MemoryInfo.MemoryDetails.MemoryData | fl
                }
                else
                {
                    Write-Host "`nMemoryComponent information of $($connect.IP)" -ForegroundColor Yellow
                    $getServerInfo[$index].MemoryInfo.MemoryComponent | fl
                }

                Write-Host "`nNIC information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].NICInfo | fl

                Write-Host "`nNetworkAdapter information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].NICInfo.NetworkAdapter | fl

                Write-Host "`nEthernetInterface information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].NICInfo.EthernetInterface | fl

                Write-Host "`nProcessor information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].ProcessorInfo | fl

                Write-Host "`nCache information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].ProcessorInfo.Cache | fl

                
                Write-Host "`nHealth Summary information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].HealthSummaryInfo | fl
            }

            5{

                Write-Host "`nServer information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index]

                Write-Host "`nFan information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].FanInfo | fl

                Write-Host "`nFirmware information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].FirmwareInfo | fl

                Write-Host "`nTemperature information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].TemperatureInfo | fl

                Write-Host "`nPowerSupply information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].PowerSupplyInfo | fl

                Write-Host "`nPowerSupplySummary information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].PowerSupplyInfo.PowerSupplySummary | fl

                Write-Host "`nPowerSupplies information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].PowerSupplyInfo.PowerSupplies | fl

                Write-Host "`nMemory information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].MemoryInfo | fl

                Write-Host "`nAdvancedMemoryProtection information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].MemoryInfo.AdvancedMemoryProtection | fl

                Write-Host "`nMemoryDetailsSummary information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].MemoryInfo.MemoryDetailsSummary | fl

                Write-Host "`nMemoryDetails information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].MemoryInfo.MemoryDetails | fl
                   
                Write-Host "`nMemoryData information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].MemoryInfo.MemoryDetails.MemoryData | fl

                Write-Host "`nNIC information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].NICInfo | fl

                Write-Host "`nNetworkAdapter information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].NICInfo.NetworkAdapter | fl

                Write-Host "`nEthernetInterface information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].NICInfo.EthernetInterface | fl

                Write-Host "`nProcessor information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].ProcessorInfo | fl

                Write-Host "`nCache information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].ProcessorInfo.Cache | fl
                
                Write-Host "`nHealth Summary information of $($connect.IP)" -ForegroundColor Yellow
                $getServerInfo[$index].HealthSummaryInfo | fl
            }
                                   
            default{continue}
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