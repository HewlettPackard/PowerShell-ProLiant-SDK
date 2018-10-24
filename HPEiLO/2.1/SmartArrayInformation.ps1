####################################################################
#Get smart array storage controller details from iLO
####################################################################

<#
.Synopsis
    This Script gets the Smart Array Information.

.DESCRIPTION
    This Script gets the Smart Array Information such as the Logical drive information, Physical drive information, storage enclosure information etc.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Get-HPEiLOSmartArrayStorageController, Disconnect-HPEiLO, Disable-HPEiLOLog

.EXAMPLE
    
    PS C:\HPEiLOCmdlets\Samples\> .\SmartArrayInformation.ps1
	
    This script does not take any parameter and gets the smart array information for the given target iLO's.
 
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

Write-Host "This script gets the SmartArrayInformation of the given server.`n"

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
	else
	{
		$Connection | fl 
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

        Write-Host "`nGetting the Smart Array Controller information." -ForegroundColor Green

        $result = Get-HPEiLOSmartArrayStorageController -Connection $connection 
       
        foreach($output in $result)
        {
        
            if($output.Status -eq "OK" -and $output.SmartArrayDiscoveryStatus -ne $null)
            {
                if($output.SmartArrayDiscoveryStatus -ne "Complete")
                {
                    Write-Host "`nDiscovery Status is $($output.SmartArrayDiscoveryStatus). No controller information available for $($output.IP)." -ForegroundColor Yellow
                }
                else
                {
                    $i=0
                    foreach($item in $output.Controllers)
                    {
                        $i = $i+1
                        Write-Host "`nController $i information for the server $($output.IP) is:" -ForegroundColor Green

                        $controllerInfo = New-Object PSObject                                       
                                        
                        $item.PSObject.Properties | ForEach-Object {
                            if($_.Value -ne $null){ $controllerInfo | add-member Noteproperty $_.Name  $_.Value}
                        }
                    
                        $controllerInfo 
                    
                        if($item.LogicalDrives -ne $null)
                        {
                            Write-Host "`nLogical Drive information -> Controller $i for $($output.IP) is:" -ForegroundColor Green

                            foreach($logicalDrive in $item.LogicalDrives)
                            {
                                $logicalDriveInfo = New-Object PSObject                                       
                                        
                                $logicalDrive.PSObject.Properties | ForEach-Object {
                                if($_.Value -ne $null){ $logicalDriveInfo | add-member Noteproperty $_.Name  $_.Value}
                                }
                            }
                    
                            $logicalDriveInfo 
                        }

                        if($item.PhysicalDrives -ne $null)
                        {
                            Write-Host "`nPhysical Drive information -> Controller $i for $($output.IP) is:" -ForegroundColor Green

                            foreach($physicalDrive in $item.PhysicalDrives)
                            {
                                $physicalDriveInfo = New-Object PSObject                                       
                                        
                                $physicalDrive.PSObject.Properties | ForEach-Object {
                                if($_.Value -ne $null){ $physicalDriveInfo | add-member Noteproperty $_.Name  $_.Value}
                                }
                            }
                    
                            $physicalDriveInfo 
                        }

                        if($item.StorageEnclosures -ne $null)
                        {

                            Write-Host "`nStorage Enclosure information -> Controller $i for $($output.IP) is:" -ForegroundColor Green

                            foreach($enclosure in $item.StorageEnclosures)
                            {
                                $enclosureInfo = New-Object PSObject                                       
                                        
                                $enclosure.PSObject.Properties | ForEach-Object {
                                if($_.Value -ne $null){ $enclosureInfo | add-member Noteproperty $_.Name  $_.Value}
                                }
                            }
                    
                            $enclosureInfo 
                        }

                    }
                }
            }
            elseif($output.StatusInfo -ne $null)
            {
                $message = $output.StatusInfo.Message; Write-Host "`nFailed to add components to the repository: "$message -ForegroundColor Red 
            }
            
        }

    }
    else
    {
        Write-Host "`nThe given list of IP's are not reachable" -ForegroundColor Red
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