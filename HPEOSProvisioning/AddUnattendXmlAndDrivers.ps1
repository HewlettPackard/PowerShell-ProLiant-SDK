########################################################
#Add autounattend.xml and drivers into Windows ISO file
########################################################

<#
.Synopsis
    This script allows user to add autounattend.xml and drivers into input windows ISO.

.DESCRIPTION
    This script allows user to add autounattend.xml and drivers into input windows ISO. This will create a new ISO based on OutputFile input.
    ImageFile :- Use this option to specify the windows ISO file as input.
	
	ImageIndex :- Use this option to specify the install.wim image index.
	
	DiskPartitionMode :- Use this option to specify the disk partition mode either it can be UEFI or LegacyMode.
		
	InstallToDiskID :- Use this option to specify the disk ID to install the windows.
	
	Password :- Use this option to specify the password for windows user.
		
	Driver :- Use this option to specify the driver(s) folder path.

.EXAMPLE
    AddUnattendXmlAndDrivers.ps1
    This mode of execution of script will prompt for 
    
    ImageFile    :- Accept windows ISO full path.
    
    ImageIndex :- Accept Install.wim image index.
	
	DiskPartitionMode :- Accept the disk partition mode either it can be UEFI or LegacyMode.
		
	InstallToDiskID :- Accept the disk ID to install the windows.
	
	Password :- Accept the password for windows user.
		
	Driver :- Accept the driver(s) folder path.
	
.EXAMPLE
    AddUnattendXmlAndDrivers.ps1 -ImageFile "C:\TestFolder\Windows2016_Datacenter.iso" -ImageIndex 4 -DiskPartitionMode UEFI -InstallToDiskID 0 -Password admin123 -Driver C:\TestFolder\Drivers

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 1.0.0.1
    Date    : 27/11/2017
    
.INPUTS
    Inputs to this script file
    ImageFile
	ImageIndex
	DiskPartitionMode
	InstallToDiskID
	Password
	Driver
	OutputFile

.OUTPUTS
    System.Management.Automation.PSObject[]

.LINK
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEOSProvisioning    
    
#>

#Command line parameters
Param(
    [Parameter(Mandatory=$true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [ValidatePattern('^(?:[\w]\:)(\\[A-Za-z_\-\s0-9\.]+)+\.((i|I)(s|S)(o|O))$')] [ValidateNotNullOrEmpty()] [string] $ImageFile,
    [Parameter(Mandatory=$true, Position = 1, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] [ValidateRange(1, 8)] [int] $ImageIndex,
    [Parameter(Mandatory=$true, Position = 2, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] [ValidateSet('LegacyBIOS', 'UEFI')] [ValidateNotNullOrEmpty()] [string] $DiskPartitionMode,
    [Parameter(Mandatory=$true, Position = 3, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] [ValidateRange(0, 100)] [int] $InstallToDiskID,
    [Parameter(Mandatory=$true, Position = 4, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] [ValidateLength(0, 63)] [ValidateNotNullOrEmpty()] [string] $Password,
    [Parameter(Mandatory=$true, Position = 5, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] [ValidateNotNullOrEmpty()] [string] $Driver,
    [Parameter(Mandatory=$false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] [ValidatePattern('^(?:[\w]\:)(\\[A-Za-z_\-\s0-9\.]+)+\.((i|I)(s|S)(o|O))$')] [ValidateNotNullOrEmpty()] [string] $OutputFile
)



#clear host
Clear-Host

# script execution started
Write-Host "****** Script execution started ******" -ForegroundColor Yellow
Write-Host ""
#Decribe what script does to the user

Write-Host "This script allows user to get the windows image index details in input ISO file."
Write-Host ""


#check powershell supported version
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "4")
{
    Write-Host "Your powershell version : $($PSVersionTable.PSVersion) is valid to execute this script."
    Write-Host ""
}
else
{
    Write-Host "This script required PowerSehll 3 or above."
    Write-Host "Current installed PowerShell version is $($PSVersionTable.PSVersion)."
    Write-Host "Please Update PowerShell version."
    Write-Host ""
    Write-Host "Exit..."
    Write-Host ""
    exit
}

#Load HPEOSProvisionCmdlets module

$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEOSProvisionCmdlets"))
{
    Write-Host "Loading module :  HPEOSProvisionCmdlets"
    Import-Module HPEOSProvisionCmdlets
    if(($(Get-Module -Name "HPEOSProvisionCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEOSProvisionCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
elseif($ModuleNames -like "HPEOSProvisionCmdlets")
{
   $InstalledOSPModule  =  Get-Module -Name "HPEOSProvisionCmdlets"
   Write-Host "HPEOSProvisionCmdlets Module Version : $($InstalledOSPModule.Version) is installed on your machine."
   Write-host "" 
}
else
{
    $InstalledOSPModule  =  Get-Module -Name "HPEOSProvisionCmdlets" -ListAvailable
    Write-Host "HPEOSProvisionCmdlets Module Version : $($InstalledOSPModule.Version) is installed on your machine."
    Write-host ""
}

Write-Host "Enabling HPEOSProvisioningCmdlets log"
Write-Host ""

Enable-HPEOSPLog -ErrorAction Stop

Write-Host "Adding autounattend.xml file into ISO file '$ImageFile'."
Write-Host ""

if ($PSBoundParameters.ContainsKey('OutputFile'))
{
    Use-HPEOSPWindowsUnattend -ImageFile $ImageFile -ImageIndex $ImageIndex -DiskPartitionMode $DiskPartitionMode -InstallToDiskID $InstallToDiskID -Password $Password -OutputFile $OutputFile -ErrorAction Stop
}
else
{
    Use-HPEOSPWindowsUnattend -ImageFile $ImageFile -ImageIndex $ImageIndex -DiskPartitionMode $DiskPartitionMode -InstallToDiskID $InstallToDiskID -Password $Password -ErrorAction Stop
}

Write-Host "Adding driver(s) into ISO file '$ImageFile' at ImageIndex '$ImageIndex'."
Write-Host ""

if ($PSBoundParameters.ContainsKey('OutputFile'))
{
    Add-HPEOSPWindowsDriver -ImageFile $OutputFile -Driver $Driver -ImageIndex $ImageIndex -OutputFile $OutputFile -ErrorAction Stop
}
else
{
    Add-HPEOSPWindowsDriver -ImageFile $ImageFile -Driver $Driver -ImageIndex $ImageIndex -ErrorAction Stop
}

Write-Host "Disabling HPEOSProvisioningCmdlets log"
Write-Host ""

Disable-HPEOSPLog -ErrorAction Stop

Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit