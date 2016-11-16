<#********************************************Description********************************************

This script is an example of how to set iLO functions for multiple iLO Servers at the same time by 
importing cmdlet parameter values from a CSV file, and finally gather and report the different
setting results returned from iLO.

You can use other HPiLOCmdlets by changing the cmdlet name and you can customize your own CSV file 
with the same format as Input1.csv as below.

***************************************************************************************************#>

<#CSV input file(Input1.csv):
Server,Username,Password,HostPower
192.168.1.1,user1,password1,Yes
192.168.1.2,user2,password2,No
192.168.1.3,user3,password3,Yes
#>
$path = ".\input1.csv"
$csv = Import-Csv $path
try{
    $rt = $csv | Set-HPiLOHostPower -DisableCertificateAuthentication
    if($rt -ne $null)
    {
        foreach ($iloreturn in $rt) 
        {
            $type = 0
            if($iloreturn.StatusType -eq "Warning")
            {
                $type = 1
                $IP = $iloreturn.IP
                $Message = $iloreturn.StatusMessage
            }
            elseif($iloreturn.StatusType -eq "Error")
            {
                $type = 2
                $IP = $iloreturn.IP
                $Message = $iloreturn.StatusMessage
            }
            switch($type)
            {
                #OK status is not returned in a Set cmdlet
                #but you can get a warning or error
                1 { Write-Host "I have been warned by $IP : $Message" -ForegroundColor Yellow}
                2 { Write-Host "Something bad returned by $IP : $Message" -ForegroundColor Red}
                default {Write-Host "Success returned by $IP : $Message" -ForegroundColor Green}
            }
        }
    }
    $rt = $csv | Get-HPiLOHostPower -DisableCertificateAuthentication
    $rt | Format-List
}
catch{
#code for however you want to handle a PowerShell error in the try block
    exit
}