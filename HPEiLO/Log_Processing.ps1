<#********************************************Description********************************************

This script is an example of how to get and categorize the types of events in the iLO logs or
Integrated Management Log (IML).

***************************************************************************************************#>


<#CSV input file(Input3.csv):
Server,Username,Password
192.168.1.9,user1,pwd1
192.168.1.14,user2,pwd2
#>
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference="SilentlyContinue"
#Example 1: Get and categorize the types of events in the iLO logs
$path = ".\input3.csv"
$csv = Import-Csv $path
$rt = $csv | Get-HPiLOEventLog -DisableCertificateAuthentication
#Process the iLO event log returned from each iLO
foreach ($ilo in $rt) {
    Write-Host $ilo.IP + " has " + $ilo.EVENT.Count + " iLO log entries."
    $sevs = $(foreach ($event in $ilo.EVENT) {$event.SEVERITY})
    $uniqsev = $($sevs | Sort-Object | Get-Unique)
    $sevcnts = $ilo.EVENT | group-object -property SEVERITY –noelement
    Write-Host "There are " + $uniqsev.Count + " type(s) of events in the iLO log."
    $sevcnts | Format-Table
}

#Example 2: Get and categorize the types of events in the Integrated Management Log (IML)
$path = ".\input3.csv"
$csv = Import-Csv $path
$rt = $csv | Get-HPiLOIML -DisableCertificateAuthentications
#Process the system IML returned from each iLO
foreach ($ilo in $rt) {
    Write-Host $ilo.IP + " has " + $ilo.EVENT.Count + " IML entries."
    $sevs = $(foreach ($event in $ilo.EVENT) {$event.SEVERITY})
    $uniqsev = $($sevs | Sort-Object | Get-Unique)
    $sevcnts = $ilo.EVENT | group-object -property SEVERITY –noelement
    Write-Host "There are " + $uniqsev.Count + " type(s) of events in the IML."
    $sevcnts | Format-Table
}

$ErrorActionPreference = "Continue"
$WarningPreference ="Continue"