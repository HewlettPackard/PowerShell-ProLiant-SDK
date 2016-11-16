<#********************************************Description********************************************

This script is an example of how to generate CertificateSigningRequest by using
Get-HPILOCertificateSigningRequest and then importing the signed certificate by the 
Import-HPILOCertificate cmdlet.

***************************************************************************************************#>

##Target ILO IP
#The ILO which needs to generate the CertificateSigningRequest by invoking 'Get-HPILOCertificateSigningRequest'
$targetILO = "1.1.1.1"
#Target ILO login username and password
$targetILOUsername = ""
$targetILOPassword = ""

#Customized paramters for Get-HPILOCertificateSigningRequest
#If user needs to generate customized CertificateSigningRequest 
#Please modify below paramters as needed, and add them during '1st time generate CertificateSigningRequest'
#Important!!! CommonName (CN) value should be the iLO Hostname in iLO Web -> Information -> Overview page.
$state = ""
$country = ""
$locality = ""
$organization = ""
$organizationalUnit = ""
$commonName = ""

#Waittime after 1st time 'Get-HPILOCertificateSigningRequest' is invoked
#Value is being set as 120 sec as ILO might take 2-10 min to generate the CertificateSigningRequest.
#If needed, please increase the $waitTime based on local ILO condition.
$waitTime = 120

# 1st time, the cmdlet is called to generate CertificateSigningRequest
# Used example will only generate ILO CertificateSigningRequest with default value
# If you need ILO to generate a customized CertificateSigningRequest, customized paramters of Get-HPILOCertificateSigningRequest are needed.
# Please modify parameters in 
# $state = ""
# $country = ""
# $locality = ""
# $organization = ""
# $organizationalUnit = ""
# $commonName = ""
# 
# Then use generate cmd example as shown below
# e.g.
# Get-HPILOCertificateSigningRequest -Server $targetILO -Username $targetILOUsername -Password $targetILOPassword -state $state -country $country -locality $locality -organization $organization
# Get-HPILOCertificateSigningRequest -Server $targetILO -Username $targetILOUsername -Password $targetILOPassword -state $state -country $country
# ...
$cer = Get-HPILOCertificateSigningRequest -Server $targetILO -Username $targetILOUsername -Password $targetILOPassword -DisableCertificateAuthentication

#Sleep for the time ILO must wait to execute the command agin to retrieve the certificateSigningRequest
Start-Sleep -Seconds $waitTime

# The cmdlet is executed for the 2nd time to load generated CertificateSigningRequest by running “Get-HPiLOCertificateSigningRequest” with the same parameter values as the 1st time.
# e.g.
# Get-HPILOCertificateSigningRequest -Server $targetILO -Username $targetILOUsername -Password $targetILOPassword -state $state -country $country -locality $locality -organization $organization
# Get-HPILOCertificateSigningRequest -Server $targetILO -Username $targetILOUsername -Password $targetILOPassword -state $state -country $country
# ...
$cer = Get-HPILOCertificateSigningRequest -Server $targetILO -Username $targetILOUsername -Password $targetILOPassword -DisableCertificateAuthentication

if($cer.STATUS_TYPE -ieq "ERROR" -and $cer.STATUS_MESSAGE -like "The ILO subsystem is currently generating a Certificate Signing Request(CSR), run script after 10 minutes or more to receive the CSR."){
    #If this status type is returned, it means that 1st time generation was not completed or it was not successful
    #Please increase the $waitTime and re-run the script.
    #If the $waitTime is increased to more than 10 mins and the same error is displayed, please contact HP support to check the ILO status
    Write-host "1st time generating was not finished or failed."
    return
}
elseif($cer.STATUS_TYPE -ieq "OK"){
    #CertificateSigningRequest generated succefully.
	Write-host "Successful generated CertificateSigningRequest, please check var `$certificateSigningRequest"
    $certificateSigningRequest = $cer.CERTIFICATE_SIGNING_REQUEST
}

# If there are no errors and the CertificateSigningRequest is gernerated, it is not signed
# You need to use a 3rd party sign tool to sign this request in $certificateSigningRequest.
#
#e.g.
#  1. Export generated $certificateSigningRequest to a txt file 
#  Set-Content -Path .\cert.txt -Value $certificateSigningRequest.Split("`n")
#
#  2. Use a 3rd party tool to sign $certificateSigningRequest
#
#  3. Import signed $certificateSigningRequest from a txt file
#  $signedCert = get-content .\signedCert.txt -Raw
#
#  4. Import signed certifiacte into targetILO
#  Import-HPILOCertificate -Server $targetILO -Username $targetILOUsername -Password $targetILOPassword -Certificate $signedCert