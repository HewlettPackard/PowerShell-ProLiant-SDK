########################################################
#Get Windows Image Index
########################################################

<#
.Synopsis
    This script allows user to get the windows image index details in input ISO file.

.DESCRIPTION
    This script allows user to get the windows image index details in input ISO file.
    ImageFile :- Use this option to specify the windows ISO file as input.

.EXAMPLE
    GetWindowsImageIndex.ps1
    This mode of execution of script will prompt for 
    
    ImageFile    :- Accept windows ISO full path.

.EXAMPLE
    ConfigureBootMode.ps1 -ImageFile "C:\TestFolder\Windows2016_Datacenter.iso"

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 1.0.0.1
    Date    : 27/11/2017
    
.INPUTS
    Inputs to this script file
    ImageFile

.OUTPUTS
    System.Management.Automation.PSObject[]

.LINK
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEOSProvisioning    
    
#>

#Command line parameters
Param(
    [Parameter(Mandatory=$true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][ValidatePattern('^(?:[\w]\:)(\\[A-Za-z_\-\s0-9\.]+)+\.((i|I)(s|S)(o|O))$')] [ValidateNotNullOrEmpty()] [string] $ImageFile
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

Write-Host "Mounting the image file $ImageFile."
Write-Host ""

$mountResult = Mount-DiskImage -ImagePath $ImageFile -Verbose -PassThru -ErrorAction Stop

if($null -ne $mountResult)
{
    $drive = ($mountResult | Get-Volume -ErrorAction Stop).DriveLetter + ':'

    Write-Host "Image file '$ImageFile' is successfully mounted at $drive"
    Write-Host ""

    $installWimPath = [System.IO.Path]::Combine($drive + '\', "sources\install.wim")

    Write-Host "Reading the windows image index in $installWimPath."
    Write-Host ""
    $WindowsImage = Get-WindowsImage -ImagePath $installWimPath -ErrorAction Stop
    
    $WindowsImage

    Write-Host "Dismounting the image file $ImageFile."
    Write-Host ""
    Dismount-DiskImage -ImagePath $ImageFile -ErrorAction Stop
}

Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit