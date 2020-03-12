####################################################################
#Component Repository management
####################################################################

<#
.Synopsis
    This Script allows user to add components to the repository and move them to installation queue in iLO5.

.DESCRIPTION
    This Script allows user to add components to the repository and move them to installation queue in iLO5.
	iLOIP, Username and Password input is read from iLOInput.csv file placed in the same folder location.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Add-HPEiLORepositoryComponent, Get-HPEiLORepositoryComponent, Invoke-HPEiLORepositoryComponent, Disconnect-HPEiLO, Disable-HPEiLOLog

.PARAMETER Location
	Specifies the location of the component file.

.PARAMETER CompSigLocation
	Specifies the location of the Component Signature file.

.PARAMETER TPMEnabled
	SwitchParameter to enables the firmware to continue updating when the option ROM measuring is enabled.

.EXAMPLE
    
    PS C:\HPEiLOCmdlets\Samples\> .\ComponentRepositoryMangement.ps1 -Location "C:\iLO\ComponentFile\cp033330.exe" -CompSigLocation "C:\iLO\ComponentFile\cp033330.compsig" -TPMEnabled
	
    This script takes input parameter for Location, CompSigLocation and TPMEnabled.
 
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

#Command line parameters
Param(

    [Parameter(Mandatory=$true)]
    [string[]]$Location,   
    [String[]]$CompSigLocation,
    [Switch]$TPMEnabled

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

# script execution started
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "This script allows user to add component to the repository, get the repository component information and add them to installation task queue.`n"

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

    [bool]$isParameterCountEQOne = $false;

    foreach ($key in $MyInvocation.BoundParameters.keys)
    {
        $count = $($MyInvocation.BoundParameters[$key]).Count
        if($count -ne 1 -and $count -ne $inputcsv.Count)
        {
            Write-Host "The input paramter value count and the input csv IP count does not match. Provide equal number of IP's and parameter values." -ForegroundColor Red    
            exit;
        }
        elseif($count -eq 1)
        {
            $isParameterCountEQOne = $true;
        }

    }
    Write-Host "`nConnecting using Connect-HPEiLO`n" -ForegroundColor Green
    $connection = Connect-HPeiLO -IP $inputcsv.IP -Username $inputcsv.Username -Password $inputcsv.Password -DisableCertificateAuthentication
	
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

    foreach($connect in $connection)
    {

        Write-Host "`nAdding the components to the repository for $($connect.IP)." -ForegroundColor Green

        if($isParameterCountEQOne)
        {
            $appendText= " -Location "+'"'+$Location+'"'
            if($CompSigLocation -ne $null)
            {
                $appendText += " -CompSigLocation "+'"'+$CompSigLocation+'"'
            }
        }
        else
        {
            $index = $inputcsv.IP.IndexOf($connect.IP)
            $appendText= " -Location " +'"'+$Location[$index]+'"'
            if($CompSigLocation -ne $null)
            {
                $appendText += " -CompSigLocation "+'"'+$CompSigLocation[$index]+'"'
            }
        }

        if($TPMEnabled)
        {
            $appendText += " -TPMEnabled:$"+"true"
        }

        #Executing cmdlet
        $cmdletName = "Add-HPEiLORepositoryComponent"
        $expression = $cmdletName + " -connection $" + "connect" +$appendText +" -Confirm:$"+"false"
        $output = Invoke-Expression $expression

        if($output.StatusInfo -ne $null)
        {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to add components to the repository for $($output.IP): "$message -ForegroundColor Red
            if($message -contains "Feature not supported.")
            { continue; }
        }

        $output = Get-HPEiLORepositoryComponent -Connection $connect

        Write-Host "`nAdded repository component information for $($connect.IP) is: " -ForegroundColor Green

        if($output.StatusInfo -eq $null)
        {
            $count = $output.ComponentCount
            $output.RepositoryComponentInformation[$count-1]
        }
        else
        { $message = $output.StatusInfo.Message; Write-Host "`nFailed to get repository components for $($output.IP): "$message -ForegroundColor Red ;
            
        }
        
        if($PSCmdlet.ShouldContinue("Do you want to install the component added to the repository.","Warning"))
        {
            
            $startTime = (Get-Date).AddHours(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
            $expireTime = (Get-Date).AddHours(2).ToString("yyyy-MM-ddTHH:mm:ssZ")
      
            $Name = "TestTask" + $(get-date -uformat "%Y%m%d%H%M%S")
            $FileName = $output.RepositoryComponentInformation[$count-1].Filename

            $output = Invoke-HPEiLORepositoryComponent -Connection $connect -TaskName $Name -Filename $FileName -Command ApplyUpdate -StartAfter $startTime -Expire $expireTime -UpdatableBy Bmc
               
            if($output.StatusInfo -ne $null)
            {   $message = $output.StatusInfo.Message; Write-Host "nFailed to invoke the repository component for $($output.IP): "$message -ForegroundColor Red }
            else
            {   
                Write-Host "`nComponent added to installation queue for $($connect.IP)." -ForegroundColor Green
            }
        }
        else
        {
            Write-Host "`nComponent invocation aborted." -ForegroundColor Red
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