<#********************************************Description********************************************

This script is an example of how to add Cmdlet parameter values into a CSV file, and import these
values from this CSV file into the Cmdlet.

You can change the cmdlet name to other ones and customize your own CSV file with the same format as
Input1.csv or Input2.csv as below.

***************************************************************************************************#>


#Example 1: CSV file has different Server, Username, Password, and other parameter values
<#CSV input file(Input1.csv):
Server,Username,Password,HostPower
192.168.1.1,user1,password1,Yes
192.168.1.2,user2,password2,No
192.168.1.3,user3,password3,Yes
#>
$path = ".\input1.csv"
$csv = Import-Csv $path
$rt = Set-HPiLOHostPower -Server $csv.Server -Username $csv.Username -Password $csv.Password -HostPower $csv.HostPower -DisableCertificateAuthentication
$rt | Format-List
$rt = Get-HPiLOHostPower -Server $csv.Server -Username $csv.Username -Password $csv.Password -DisableCertificateAuthentication
$rt | Format-List

#Piping the imported object from CSV file into the cmdlet
$path = ".\input1.csv"
$csv = Import-Csv $path
$rt = $csv | Set-HPiLOHostPower -DisableCertificateAuthentication
$rt | Format-List
$rt = $csv | Get-HPiLOHostPower -DisableCertificateAuthentication
$rt | Format-List

#Example 2: CSV file has only iLO IP or hostname and there is a common username and password for logging in
<#CSV input file(Input2.csv):
Server
192.168.1.1
192.168.1.2
192.168.1.3
#>
$path = ".\input2.csv"
$csv = Import-Csv $path
$rt = Set-HPiLOHostPower -Server $csv.Server -Username "username" -Password "password" -HostPower "Yes" -DisableCertificateAuthentication
$rt | Format-List
$rt = Get-HPiLOHostPower -Server $csv.Server -Username "username" -Password "password" -DisableCertificateAuthentication
$rt | Format-List