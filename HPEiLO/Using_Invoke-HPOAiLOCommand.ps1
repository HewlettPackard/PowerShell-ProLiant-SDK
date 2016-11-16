<#********************************************Description********************************************

This script is an example of how to use Invoke-HPOAiLOCommand to get or set the iLO configurations
for iLO servers inside the target OA.

***************************************************************************************************#>

#Create an OA connection (Cmdlet Invoke-HPOAiLOCommand is supported in HPOACmdlet 1.1 or later)
$c = Connect-HPOA -OA 192.168.242.62 -username "username" -password "password"

#Get the RIBCL to send
$ribcl = Get-HPiLODefaultLanguage -Server 192.168.242.62 -Username "username" -Password "password" –OutputType ExternalCommand -DisableCertificateAuthentication

#Use the connection to OA and the RIBCL command and send it to Bay 2
$c | Invoke-HPOAiLOCommand –iLOCommand $ribcl –Bay 2