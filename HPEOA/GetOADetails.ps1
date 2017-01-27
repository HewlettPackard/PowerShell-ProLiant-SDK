Param(
[string]$OA,
[string]$Username,
[string]$Password
)

if($OA -eq "")
{
    $OA = Read-Host "Enter OA Address"
}

if($Username -eq "")
{
    $Username = Read-Host "Enter Username"
}

if($Password -eq "")
{
    $Password = Read-Host "Enter Password"
}

$connection = Connect-HPOA -OA $OA -Username $Username -Password $Password

if($connection -eq $null)
{
    Write-Host "Connection cannot be established."
    exit
}

$result = $connection | Get-HPOAFRU


Write-Host "***** OA details *****" -ForegroundColor Yellow
Write-Host ""
Write-Host "OAIP `t`t:`t $($result.IP)"
$result.OnboardAdministrator

Write-Host "***** Blade details *****" -ForegroundColor Yellow
Write-Host ""
$result.Blade

Write-Host "***** Interconnect details *****" -ForegroundColor Yellow
Write-Host ""
$result.Interconnect
[array]$VCBayList = @()
foreach($interconnect in $result.Interconnect)
{
    if($interconnect.Model -match "VC")
    {
        $customObj = New-Object psobject
        $customObj | Add-member NoteProperty  VCModuleName $interconnect.Model
        $customObj | Add-member NoteProperty  BayNumber $interconnect.Bay
        $VCBayList += $customObj
    }
}


$interconnectDetails = $connection | Get-HPOAEBIPA

foreach($obj in $VCBayList)
{
    foreach($item in $interconnectDetails.EBIPADeviceInterconnectSettings)
    {
        if($Obj.BayNumber -eq $item.Bay)
        {
            $obj | Add-member NoteProperty VCIP $item.EBIPA
        }
    }

}

Write-host "***** VC IP Address ******" -ForegroundColor Yellow
Write-Host ""
$VCBayList

Write-Host "***** Enclosure details *****" -ForegroundColor Yellow
Write-Host ""
$result.Enclosure

Disconnect-HPOA -Connection $connection

