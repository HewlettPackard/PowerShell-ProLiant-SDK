####################################################################
#Gen 10 new features
####################################################################

<#
.Synopsis
    This Script allows user to use JitterControl, Self test, Physical security, IntelligentProvisioning,ServerSoftwareInventory,PCIDeviceInventory and USB features for HPE ProLiant servers.
	These features are only supported on iLO 5.

.DESCRIPTION
    This Script allows user to use JitterControl, Self test, Physical security, IntelligentProvisioning,ServerSoftwareInventory,PCIDeviceInventory and USB features for HPE ProLiant servers.
	These features are only supported on iLO 5.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Get-HPEiLOSelfTestResult, Set-HPEiLOProcessorJitterControl, Get-HPEiLOProcessorJitterControl, Get-HPEiLOPhysicalSecurity, Get-HPEiLOIntelligentProvisioningInfo, Get-HPEiLOUSBDevice, Get-HPEiLOPCISlot, Get-HPEiLOServerSoftwareInventory, Get-HPEiLOPCIDeviceInventory, Disconnect-HPEiLO, Disable-HPEiLOLog
	
.PARAMETER Mode
    Specifies the mode for Processor JitterControl. The possible values are Auto, Disabled, Manual.

.PARAMETER FrequencyLimitMHz
    Specifies the FrequencyLimitMHz for JitterControl when Mode is set to Manual. 

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\Gen10NewFeatures.ps1 -Mode Auto
	
    This script takes input for Mode.

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\Gen10NewFeatures.ps1 -Mode Manual -FrequencyLimitMHz 100
	
    This script takes input for Mode and FrequencyLimitMHz.

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
    [ValidateSet("Auto","Disabled","Manual")]
    [ValidateNotNullorEmpty()]
    [Parameter(Mandatory=$true)]
    [string[]]$Mode, 

    [ValidateNotNullorEmpty()]
    [Parameter(Mandatory=$false)]
    [int[]]$FrequencyLimitMHz 

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

    if(($null -ne $inputcsv.Count -and ($Mode.Length -ne 1 -and $Mode.Count -ne $inputcsv.Count)) -or ($null -ne $FrequencyLimitMHz -and $FrequencyLimitMHz.Count -ne $Mode.Count))
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
        $iLOVersion = $connect.TargetInfo.iLOGeneration -replace '\w+\D+',''
        
        switch($iLOVersion)
        {
            3 {
                Write-Host "$($connect.IP) : The script is not supported in iLO 3 `n" -ForegroundColor Yellow
            }
            4 {
                Write-Host "$($connect.IP) : The script is not supported in iLO 4 `n" -ForegroundColor Yellow
            }
            5 {
                #Get Self-Test Result 
                Write-Host "$($connect.IP) : Getting Self-Test result using Get-HPEiLOSelfTestResult cmdlet `n" -ForegroundColor Yellow
                $selfTest = Get-HPEiLOSelfTestResult -Connection $connect
                $selfTest | fl

                if($selfTest.Status -contains "Error")
                {
                   $selfTest.StatusInfo | fl 
                   Write-Host "Getting Self-Test Failed `n" -ForegroundColor Red
                }
                else
                {
                    $selfTest.iLOSelfTestResult | fl
                    Write-Host "$($connect.IP) : Get Self-Test result completed successfully `n" -ForegroundColor Green
                }


                #Set JitterControl
                Write-Host "$($connect.IP) : Setting Jittercontrol information using Get-HPEiLOProcessorJitterControl cmdlet `n" -ForegroundColor Yellow
                if($mode.Count -eq 1)
                {
                    if($FrequencyLimitMHz -ne $null)
                    {
                        $setjitcontrol = Set-HPEiLOProcessorJitterControl -Connection $connect -Mode $mode -FrequencyLimitMHz $FrequencyLimitMHz
                    }
                    else
                    {
                        $setjitcontrol = Set-HPEiLOProcessorJitterControl -Connection $connect -Mode $mode 
                    }
                }
                else
                {
                    $modeindex = $inputcsv.IP.IndexOf($connect.IP)
                    if($FrequencyLimitMHz -ne $null)
                    {
                        $setjitcontrol = Set-HPEiLOProcessorJitterControl -Connection $connect -Mode $mode[$modeindex] -FrequencyLimitMHz $FrequencyLimitMHz[$modeindex]
                    }
                    else
                    {
                        $setjitcontrol = Set-HPEiLOProcessorJitterControl -Connection $connect -Mode $mode[$modeindex]
                    }
                    
                }
                $setjitcontrol | fl

                if($setjitcontrol.Status -contains "Error")
                {
                   $setjitcontrol.StatusInfo | fl 
                   Write-Host "$($connect.IP) : Setting Jittercontrol information Failed `n" -ForegroundColor Red
                }
                else
                {
                    Write-Host "$($connect.IP) : Set Jittercontrol information completed successfully `n" -ForegroundColor Green
                }

                
                #Get JitterControl 
                Write-Host "$($connect.IP) : Getting Jittercontrol information using Get-HPEiLOProcessorJitterControl cmdlet `n" -ForegroundColor Yellow
                $getjitcontrol = Get-HPEiLOProcessorJitterControl -Connection $connect
                $getjitcontrol | fl

                if($getjitcontrol.Status -contains "Error")
                {
                   $getjitcontrol.StatusInfo | fl 
                   Write-Host "$($connect.IP) : Getting Jittercontrol information Failed `n" -ForegroundColor Red
                }
                else
                {
                    Write-Host "$($connect.IP) : Get Jittercontrol information completed successfully `n" -ForegroundColor Green
                }

                #Get Physical security 
                Write-Host "$($connect.IP) : Getting Physical security information using Get-HPEiLOPhysicalSecurity cmdlet `n" -ForegroundColor Yellow
                $physicalSecurity = Get-HPEiLOPhysicalSecurity -Connection $connect
                $physicalSecurity | fl

                if($physicalSecurity.Status -contains "Error")
                {
                   $physicalSecurity.StatusInfo | fl 
                   Write-Host "$($connect.IP) : Getting Physical security information Failed `n" -ForegroundColor Red
                }
                else
                {
                    Write-Host "$($connect.IP) : Get Physical security information completed successfully `n" -ForegroundColor Green
                }

                #Get Intelligent Provisioning 
                Write-Host "$($connect.IP) : Getting Intelligent Provisioning information using Get-HPEiLOIntelligentProvisioningInfo cmdlet `n" -ForegroundColor Yellow
                $ipinfo = Get-HPEiLOIntelligentProvisioningInfo -Connection $connect
                $ipinfo | fl

                if($ipinfo.Status -contains "Error")
                {
                   $ipinfo.StatusInfo | fl 
                   Write-Host "$($connect.IP) : Getting Intelligent Provisioning information Failed `n" -ForegroundColor Red
                }
                else
                {
                    Write-Host "$($connect.IP) : Get Intelligent Provisioning information completed successfully `n" -ForegroundColor Green
                }
                
                #Get USBDevice detail 
                Write-Host "$($connect.IP) : Getting USBDevice detail using Get-HPEiLOUSBDevice cmdlet `n" -ForegroundColor Yellow
                $usbDevice = Get-HPEiLOUSBDevice -Connection $connect
                $usbDevice | fl

                if($usbDevice.Status -contains "Error")
                {
                   $usbDevice.StatusInfo | fl 
                   Write-Host "Getting USBDevice detail Failed `n" -ForegroundColor Red
                }
                else
                {
                    $usbDevice.USBDeviceDetail | fl
                    Write-Host "$($connect.IP) : Get USBDevice detail completed successfully `n" -ForegroundColor Green
                }    
                
                #Get PCI slot information
                Write-Host "$($connect.IP) : Getting PCI slot information using Get-HPEiLOPCISlot cmdlet `n" -ForegroundColor Yellow
                $pciSlot = Get-HPEiLOPCISlot -Connection $connect
                $pciSlot | fl

                if($pciSlot.Status -contains "Error")
                {
                   $pciSlot.StatusInfo | fl 
                   Write-Host "Getting PCI slot information Failed `n" -ForegroundColor Red
                }
                else
                {
                    $pciSlot.PCISlotDetail | fl
                    Write-Host "$($connect.IP) : Get PCI slot information completed successfully `n" -ForegroundColor Green
                }  
                
                #Get Server software inventory information
                Write-Host "$($connect.IP) : Getting Server software inventory information using Get-HPEiLOServerSoftwareInventory cmdlet `n" -ForegroundColor Yellow
                $ssiInfo = Get-HPEiLOServerSoftwareInventory -Connection $connect
                $ssiInfo | fl

                if($ssiInfo.Status -contains "Error")
                {
                   $ssiInfo.StatusInfo | fl 
                   Write-Host "Getting Server software inventory information Failed `n" -ForegroundColor Red
                }
                else
                {
                    $ssiInfo.ServerSoftwareInfo | fl
                    Write-Host "$($connect.IP) : Get Server software inventory information completed successfully `n" -ForegroundColor Green
                }    
                
                #Get PCI device inventory information
                Write-Host "$($connect.IP) : Getting PCI device inventory information using Get-HPEiLOPCIDeviceInventory cmdlet `n" -ForegroundColor Yellow
                $pciDevice = Get-HPEiLOPCIDeviceInventory -Connection $connect
                $pciDevice | fl

                if($pciDevice.Status -contains "Error")
                {
                   $pciDevice.StatusInfo | fl 
                   Write-Host "Getting PCI device inventory information Failed `n" -ForegroundColor Red
                }
                else
                {
                    $pciDevice.PCIDevice | fl
                    Write-Host "$($connect.IP) : Get PCI device inventory information completed successfully `n" -ForegroundColor Green
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