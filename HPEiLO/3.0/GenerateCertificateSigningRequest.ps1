####################################################################
#Generate Certificate Signing Request
####################################################################

<#
.Synopsis
    This Script generates the CSR and gets the same.

.DESCRIPTION
    This Script generates the CSR and gets the same.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Start-HPEiLOCertificateSigningRequest, Get-HPEiLOCertificateSigningRequest, Disconnect-HPEiLO, Disable-HPEiLOLog

.PARAMETER State
    Specifies state in which the company or organization that owns the iLO subsystem is located.

.PARAMETER Country
    Specifies the country code for the country in which the company or organization that owns the iLO subsystem is located.

.PARAMETER City
    Specifies the city or locality in which the company or organization that owns the iLO subsystem is located.

.PARAMETER Organization
    Specifies the name of the company or organization that owns the iLO subsystem.

.PARAMETER OrganizationalUnit
    The unit within the company or organization that owns the iLO subsystem.

.PARAMETER CommonName
    The FQDN of the iLO subsystem.

.EXAMPLE
    
    PS C:\HPEiLOCmdlets\Samples\> .\GenerateCertificateSigningRequest.ps1 -State QWERTY -Country AB -City Dummy -Organization XYZ -OrganizationalUnit 1234ABC -CommonName common

	This script takes the required input and generates certificate signing request for the given iLO's.
	
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
    [string[]]$State, 
    [Parameter(Mandatory=$true)]
    [string[]]$Country, 
    [Parameter(Mandatory=$true)]
    [string[]]$City, 
    [Parameter(Mandatory=$true)]
    [string[]]$Organization, 
    [Parameter(Mandatory=$true)]
    [string[]]$OrganizationalUnit, 
    [Parameter(Mandatory=$true)]
    [string[]]$CommonName
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

Write-Host "This script generates the CSR and displays the same.`n"

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
    $connection = Connect-HPEiLO -IP $inputcsv.IP -Username $inputcsv.Username -Password $inputcsv.Password -DisableCertificateAuthentication
	
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

       Write-Host "`nGenerating CSR for $($connect.IP)." -ForegroundColor Green

       if($isParameterCountEQOne)
       {
           $result = Start-HPEiLOCertificateSigningRequest -Connection $connect -State $State -Country $Country -City $City -Organization $Organization -OrganizationalUnit $OrganizationalUnit -CommonName $CommonName 
       }
       else
       {
          $index = $inputcsv.IP.IndexOf($connect.IP)
          $result = Start-HPEiLOCertificateSigningRequest -Connection $connect -State $State[$index] -Country $Country[$index] -City $City[$index] -Organization $Organization[$index] -OrganizationalUnit $OrganizationalUnit[$index] -CommonName $CommonName[$index]
       }

        if($result.Status -eq "ERROR")
        {
            if($result.StatusInfo -ne $null)
            {   $message = $result.StatusInfo.Message; Write-Host "`nFailed to generate CSR for $($result.IP): "$message -ForegroundColor Red }
           
        }
       
        if($connect.ConnectionType -eq "RIBCL")
        { 
            Start-Sleep -Seconds 60
        }
        else
        {
            Start-Sleep -Seconds 35
        }
      
        $result = Get-HPEiLOCertificateSigningRequest -Connection $connect
       
       
        if($result.Status -eq "ERROR")
        {   
            $message = $result.StatusInfo.Message; 
            Write-Host "`nFailed to get certificate for $($result.IP): "$message -ForegroundColor Red
                
        }
        elseif($result.Status -eq "INFORMATION")
        {
            Start-Sleep -Seconds 60
            $output = Get-HPEiLOCertificateSigningRequest -Connection $connect
            Write-Host "`nCertificate information for $($result.IP)" -ForegroundColor Green
            $output.CertificateSigningRequest | Out-String
        }
        else
        {
            Write-Host "`nCertificate information for $($result.IP)" -ForegroundColor Green
            $result.CertificateSigningRequest | Out-String
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