####################################################################
#Firmare inventory information
####################################################################

<#
.Synopsis
    This Script gets the Inventory Information.

.DESCRIPTION
    This Script gets Firmware, Software, Device and PCIDevice Inventory information for iLO5.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Get-HPEiLOFirmwareInventory, Get-HPEiLOServerSoftwareInventory, Get-HPEiLODeviceInventory, Get-HPEiLOPCIDeviceInventory, Disconnect-HPEiLO, Disable-HPEiLOLog

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\InventoryInformation.ps1
	
	This script does not take any parameter.
	
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

Write-Host "This script gets the inventory information such as Firmware inventory, Device Inventory and PCI device Inventory.`n"

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

    $connection = Connect-HPEiLO -IP $inputcsv.IP -Username $inputcsv.Username -Password $inputcsv.Password -DisableCertificateAuthentication
	
	$Error.Clear()
	
	if($Connection -eq $null)
    {
        Write-Host "`nConnection could not be established to any target iLO.`n" -ForegroundColor Red
        $inputcsv.IP | fl
        exit;
    }

	#List of IP's that could not be connected
	if($Connection.count -ne $inputcsv.IP.count)
    {
        Write-Host "`nConnection failed for below set of targets" -ForegroundColor Red
        foreach($item in $inputcsv.IP)
        {
            if($Connection.IP -notcontains $item)
            {
                $item | fl
            }
        }
    }
	
    if($connection -ne $null)
    {

        Write-Host "`nConnection established to the server." -ForegroundColor Green

        Write-Host "`nGetting Firmware Inventory information." -ForegroundColor Green

        $result = Get-HPEiLOFirmwareInventory -Connection $connection 
       
        foreach($output in $result)
        {

            if($output.Status -eq "OK")
            {
                Write-Host "`Firmware Inventory information for $($output.IP)." -ForegroundColor Green

                $fwInventory = @()
                foreach($item in $output.FirmwareInformation)
                {
                    $fwInfo = New-Object PSObject 
                    if($item.Status.Health -ne $null){ $status = $item.Status.Health } else { $status = $item.Status.State }                                      
                                        
                    $fwInfo | Add-Member Noteproperty "Index" $item.Index
                    $fwInfo | Add-Member Noteproperty "FirmwareName" $item.FirmwareName
                    $fwInfo | Add-Member Noteproperty "FirmwareVersion" $item.FirmwareVersion
                    $fwInfo | Add-Member Noteproperty "Location" $item.Location
                    $fwInfo | Add-Member Noteproperty "Status" $status

                    $fwInventory += $fwInfo
                 }
                 $fwInventory
           
            }
            
            else
            {
                if($output.StatusInfo -ne $null)
                {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to get Firmware Inventory information: "$message -ForegroundColor Red }
            }

        }
        
        Start-Sleep -Seconds 6

        Write-Host "`nGetting Server Software Inventory information." -ForegroundColor Green

        $result = Get-HPEiLOServerSoftwareInventory -Connection $connection 

        foreach($output in $result)
        {
            
            if($output.Status -eq "OK")
            {
                
                Write-Host "`nServer Software Inventory information for $($output.IP)." -ForegroundColor Green

                $output.Devices
           
            }
   
            else
            {
                if($output.StatusInfo -ne $null)
                {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to get Server Software Inventory information for $($output.IP): "$message -ForegroundColor Red }
            }

        }
        

        Start-Sleep -Seconds 6

        Write-Host "`nGetting Device Inventory information." -ForegroundColor Green

        $output = Get-HPEiLODeviceInventory -Connection $connection 

        
       foreach($output in $result)
        {
            
            if($output.Status -eq "OK")
            {
                
                Write-Host "`nDevice Inventory information for $($output.IP)." -ForegroundColor Green

                $output.Devices
           
            }
   
            else
            {
                if($output.StatusInfo -ne $null)
                {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to get Device Inventory information for $($output.IP): "$message -ForegroundColor Red }
            }

        }

        Start-Sleep -Seconds 6

        Write-Host "`nGetting PCI Device Inventory information." -ForegroundColor Green

        $output = Get-HPEiLOPCIDeviceInventory -Connection $connection 

        
        foreach($output in $result)
        {
            
            if($output.Status -eq "OK")
            {
                
                Write-Host "`nPCIDevice Inventory information for $($output.IP)." -ForegroundColor Green

                $output.PCIDevice
           
            }
   
            else
            {
                if($output.StatusInfo -ne $null)
                {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to get PCIDevice Inventory information for $($output.IP): "$message -ForegroundColor Red }
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