########################################################
#Uninstalling TLS Certificate
###################################################----#

<#
.Synopsis
    This script allows user to uninstall the existing installed TLS certificate on HPE Proliant Gen10 servers.

.DESCRIPTION
    This script allows user to uninstall the existing installed TLS certificate.
    TLSCertificateIndex :- Use this option to uninstall the existing installed TLS certificate by specifying the TLS certificate index on HPE ProLiant Gen10 servers.

.EXAMPLE
    UninstallTLSCertificate.ps1

    This mode of execution of script will prompt for 
    
    -Address    :- Accept IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    -Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    -TLSCertificateIndex   :- Specifiy the TLS certificate index to uninstall. To uninstall more than one certificate, specify the indexes by comma(,) as delimiter.

.EXAMPLE
    UninstallTLSCertificate.ps1 -Address "10.20.30.40" -Credential $userCredential -TLSCertificateIndex "2,3"

    This mode of script have input parameter for Address Credential and TLSCertificateIndex.
    
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to specify user credential. #In case of multiple servers use same credential for all the servers
    
    -TLSCertificateIndex :- Use this Parameter to specify the TLS certificate index to uninstall. To uninstall more than one certificate, specify the indexes by comma(,) as delimiter.

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 11/04/2020
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    TLSCertificateIndex

.OUTPUTS
    None (by default)

.LINK
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS    
    
#>

#Command line parameters
Param(
    # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [string[]]$Address,   
    #In case of multiple servers it use same credential for all the servers
    [PSCredential]$Credential, 
    # TLSCertificateIndex If you uninstall more than one certificate, specify the index seperated by comma (,)
    [String[]]$TLSCertificateIndex  
     )

 #Check for server avaibiality

function CheckServerAvailability ($ListOfAddress)
{
    [int]$pingFailureCount = 0
    [array]$PingedServerList = @()
    foreach($serverAddress in $ListOfAddress)
    {
           if(Test-Connection $serverAddress)
           {
            #Write-Host "Server $serverAddress pinged successfully."
            $PingedServerList += $serverAddress
           }
           else
           {
            Write-Host ""
            Write-Host "Server $serverAddress is not reachable. Please check network connectivity"
            $pingFailureCount ++
           }
    }

    if($pingFailureCount -eq $ListOfAddress.Count)
    {
        Write-Host ""
        Write-Host "Server(s) are not reachable please check network conectivity"
        exit
    }
    return $PingedServerList
}

#clear host
Clear-Host

# script execution started
Write-Host "****** Script execution started ******" -ForegroundColor Yellow
Write-Host ""
#Decribe what script does to the user

Write-Host "This script allows user to uninstall the existing installed TLS certificate into uninstallation queue."
Write-Host ""

#dont show error in script

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"
$ErrorActionPreference = "Stop"

#check powershell support
#Write-Host "Checking PowerShell version support"
#Write-Host ""
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "3")
{
    Write-Host "Your powershell version : $($PSVersionTable.PSVersion) is valid to execute this script"
    Write-Host ""
}
else
{
    Write-Host "This script required PowerSehll 3 or above"
    Write-Host "Current installed PowerShell version is $($PSVersionTable.PSVersion)"
    Write-Host "Please Update PowerShell version"
    Write-Host ""
    Write-Host "Exit..."
    Write-Host ""
    exit
}

#Load HPEBIOSCmdlets module
#Write-Host "Checking HPEBIOSCmdlets module"
#Write-Host ""

$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEBIOSCmdlets"))
{
    Write-Host "Loading module :  HPEBIOSCmdlets"
    Import-Module HPEBIOSCmdlets
    if(($(Get-Module -Name "HPEBIOSCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEBIOSCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstalledBiosModule  =  Get-Module -Name "HPEBIOSCmdlets"
    Write-Host "HPEBIOSCmdlets Module Version : $($InstalledBiosModule.Version) is installed on your machine."
    Write-host ""
}

# check for IP(s) or Hostname(s) Input. if not available prompt for Input

if($Address.Count -eq 0)
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}
    
[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)"
    Write-Host ""
    Write-Host "Exit..."
    exit
}

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password(Use same credential for multiple servers)"
    Write-Host ""
}

#  Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

# create connection object
[array]$ListOfConnection = @()

foreach($IPAddress in $ListOfAddress)
{
    
    Write-Host ""
    Write-Host "Connecting to server  : $IPAddress"
    $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        $connection
        if($connection.TargetInfo.ProductName.Contains("Gen10"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "Install TLS certificate is not supported on Server $($connection.IP)"
            Disconnect-HPEBIOS -Connection $connection
        }
    }
    else
    {
        Write-Host "Connection cannot be established to the server : $IPAddress" -ForegroundColor Red
    }
}

if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit..."
    Write-Host ""
    exit
}

# Get current TLS Certificate Uninstallation Queue

Write-Host ""
Write-Host "Current TLS Certificate Installation Queue" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
    $result = Get-HPEBIOSTLSCertificateUninstallationQueue -Connection $serverConnection
    Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}

if($TLSCertificateIndex.Count -eq 0)
{
    $tempTLSCertificateIndex = Read-Host "Enter the index to uninstall the existing installed certificates [Specifiy the index separated by comma(,) to uninstall more than one certificate]"
    $TLSCertificateIndex = $tempTLSCertificateIndex.ToString()
    if($TLSCertificateIndex.Count -eq 0)
    {
        Write-Host "TLSCertificateIndex is not provided`n Exit......."
        exit
    }
}

Write-Host "Uninstallating TLS Certificate into uninstallation queue....." -ForegroundColor Green

$failureCount = 0
if($ListOfConnection.Count -ne 0)
{
	$setResult =  Uninstall-HPEBIOSTLSCertificate -Connection $ListOfConnection -TLSCertificateIndex $TLSCertificateIndex
    foreach($result in $setResult)
    {
	    if($result.Status -eq "Error")
	    {
		    Write-Host ""
		    Write-Host "TLS Certificate Cannot be installed"
		    Write-Host "Server : $($result.IP)"
		    Write-Host "Error : $($result.StatusInfo)"
		    Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
		    $failureCount++
	    }
	    elseif($result.Status -eq "Warning")
	    {
		    Write-Host ""
		    Write-Host "Server : $($result.IP)"
		    Write-Host "Status : $($result.Status)"
		    Write-Host "StatusInfo : $($result.StatusInfo)"
		    Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
	    }
    }
}

if($failureCount -ne $ListOfConnection.Count)
{
	Write-Host ""
	Write-host "Added certificate to be uninstalled successfully into uninstallation queue" -ForegroundColor Green
	Write-Host ""
	$counter = 1
	foreach($serverConnection in $ListOfConnection)
	{
		$result = Get-HPEBIOSTLSCertificateUninstallationQueue -Connection $serverConnection
		Write-Host "------------------------ Server $counter ------------------------" -ForegroundColor Yellow
		Write-Host ""
		$result
		$counter++
	}
}

Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit
# SIG # Begin signature block
# MIIjEQYJKoZIhvcNAQcCoIIjAjCCIv4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCVg1ozzV4DS8cX
# k+hg6+Hl6g5+F5BNijv4oQFHS4DrQaCCHhkwggViMIIESqADAgECAhEA1HaTOoqh
# lf5Gt0z/XIj9PzANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJHQjEbMBkGA1UE
# CBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2ln
# bmluZyBDQTAeFw0yMDAxMjkwMDAwMDBaFw0yMTAxMjgyMzU5NTlaMIHSMQswCQYD
# VQQGEwJVUzEOMAwGA1UEEQwFOTQzMDQxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlQ
# YWxvIEFsdG8xHDAaBgNVBAkMEzMwMDAgSGFub3ZlciBTdHJlZXQxKzApBgNVBAoM
# Ikhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBhbnkxGjAYBgNVBAsMEUhQ
# IEN5YmVyIFNlY3VyaXR5MSswKQYDVQQDDCJIZXdsZXR0IFBhY2thcmQgRW50ZXJw
# cmlzZSBDb21wYW55MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvx6k
# Tl1QwY5TPYjtfizxfnoPN5p5ww8eS2bphLytlwcYK3+gaZ53iSzma2e2M9b5vj6p
# hTwUaY6Nb73Z7mho270Ze/fhCmPEPi2lEJSkj+iGSlrFGDnxOEM6YIqtT8615kE7
# CUVgQDxq7nOAgJFxA7BgIJPr9wssh5ix3cnJL6WrYIlmGe9+zgeoyhq98vU9D4Oa
# dUfuXXpRhXQBq3odyXE7BAADShVrFtOmc8zgBlk3iuvpBaX2M4vVEuckJK+IQ8lP
# 3iVo7GbpFjKXneh3JcnxHy+cHbN1zkbj1BkfysuLXylswWB8BWQbHZpUD7Ck/XbE
# wvWlwnMBg21oTG8FPQIDAQABo4IBhjCCAYIwHwYDVR0jBBgwFoAUDuE6qFM6MdWK
# vsG7rWcaA4WtNA4wHQYDVR0OBBYEFNEUNOlei+sYBxYNcJwz3uwND2/2MA4GA1Ud
# DwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEG
# CWCGSAGG+EIBAQQEAwIEEDBABgNVHSAEOTA3MDUGDCsGAQQBsjEBAgEDAjAlMCMG
# CCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzBDBgNVHR8EPDA6MDig
# NqA0hjJodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29SU0FDb2RlU2lnbmlu
# Z0NBLmNybDBzBggrBgEFBQcBAQRnMGUwPgYIKwYBBQUHMAKGMmh0dHA6Ly9jcnQu
# c2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5nQ0EuY3J0MCMGCCsGAQUF
# BzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEA
# HV/3fBUIKpntI8lNEkiH4b1Yg/gFHbdwhtJBV4LTAvhtknuzyPXYvbC+f7STvvRh
# 4AtpTQtV4YYDrT/u5dxZUOcoQBVxZzeF32CwIq/N37H96UrMDCEvj/BZjpALrojX
# lDsUwigaC9cggeEs3qr4jUffTL1u/wQyri0BSKuRSFkvkVFnzyG09g3JoJz3K1MD
# WM7NDQZwoTJfrkkGMDabtrD+4dniZ9lgeryBNYJoQ9Xmxe9MbyiGXNPGlwhMSMEF
# /8m4aVVaWn7an5+NuFg/etiEVMe1kwFzV18j5YKYdAQAQ/MVuJeRXSmjrARPXslq
# Y3m0OLx6TeshBO1B7J0Y7jCCBXcwggRfoAMCAQICEBPqKHBb9OztDDZjCYBhQzYw
# DQYJKoZIhvcNAQEMBQAwbzELMAkGA1UEBhMCU0UxFDASBgNVBAoTC0FkZFRydXN0
# IEFCMSYwJAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5hbCBUVFAgTmV0d29yazEiMCAG
# A1UEAxMZQWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9vdDAeFw0wMDA1MzAxMDQ4Mzha
# Fw0yMDA1MzAxMDQ4MzhaMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEpl
# cnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJV
# U1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJTQSBDZXJ0aWZpY2F0aW9u
# IEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAIASZRc2
# DsPbCLPQrFcNdu3NJ9NMrVCDYeKqIE0JLWQJ3M6Jn8w9qez2z8Hc8dOx1ns3KBEr
# R9o5xrw6GbRfpr19naNjQrZ28qk7K5H44m/Q7BYgkAk+4uh0yRi0kdRiZNt/owbx
# iBhqkCI8vP4T8IcUe/bkH47U5FHGEWdGCFHLhhRUP7wz/n5snP8WnRi9UY41pqdm
# yHJn2yFmsdSbeAPAUDrozPDcvJ5M/q8FljUfV1q3/875PbcstvZU3cjnEjpNrkyK
# t1yatLcgPcp/IjSufjtoZgFE5wFORlObM2D3lL5TN5BzQ/Myw1Pv26r+dE5px2uM
# YJPexMcM3+EyrsyTO1F4lWeL7j1W/gzQaQ8bD/MlJmszbfduR/pzQ+V+DqVmsSl8
# MoRjVYnEDcGTVDAZE6zTfTen6106bDVc20HXEtqpSQvf2ICKCZNijrVmzyWIzYS4
# sT+kOQ/ZAp7rEkyVfPNrBaleFoPMuGfi6BOdzFuC00yz7Vv/3uVzrCM7LQC/NVV0
# CUnYSVgaf5I25lGSDvMmfRxNF7zJ7EMm0L9BX0CpRET0medXh55QH1dUqD79dGMv
# sVBlCeZYQi5DGky08CVHWfoEHpPUJkZKUIGy3r54t/xnFeHJV4QeD2PW6WK61l9V
# LupcxigIBCU5uA4rqfJMlxwHPw1S9e3vL4IPAgMBAAGjgfQwgfEwHwYDVR0jBBgw
# FoAUrb2YejS0Jvf6xCZU7wO94CTLVBowHQYDVR0OBBYEFFN5v1qqK0rPVIDh2JvA
# nfKyA2bLMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MBEGA1UdIAQK
# MAgwBgYEVR0gADBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3JsLnVzZXJ0cnVz
# dC5jb20vQWRkVHJ1c3RFeHRlcm5hbENBUm9vdC5jcmwwNQYIKwYBBQUHAQEEKTAn
# MCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3
# DQEBDAUAA4IBAQCTZfY3g5UPXsOCHB/Wd+c8isCqCfDpCybx4MJqdaHHecm5UmDI
# KRIO8K0D1gnEdt/lpoGVp0bagleplZLFto8DImwzd8F7MhduB85aFEE6BSQb9hQG
# O6glJA67zCp13blwQT980GM2IQcfRv9gpJHhZ7zeH34ZFMljZ5HqZwdrtI+LwG5D
# fcOhgGyyHrxThX3ckKGkvC3vRnJXNQW/u0a7bm03mbb/I5KRxm5A+I8pVupf1V8U
# U6zwT2Hq9yLMp1YL4rg0HybZexkFaD+6PNQ4BqLT5o8O47RxbUBCxYS0QJUr9GWg
# SHn2HYFjlp1PdeD4fOSOqdHyrYqzjMchzcLvMIIF9TCCA92gAwIBAgIQHaJIMG+b
# JhjQguCWfTPTajANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVU
# aGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgxMTAyMDAwMDAwWhcNMzAxMjMxMjM1
# OTU5WjB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAi
# BgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAIYijTKFehifSfCWL2MIHi3cfJ8Uz+MmtiVmKUCG
# VEZ0MWLFEO2yhyemmcuVMMBW9aR1xqkOUGKlUZEQauBLYq798PgYrKf/7i4zIPoM
# GYmobHutAMNhodxpZW0fbieW15dRhqb0J+V8aouVHltg1X7XFpKcAC9o95ftanK+
# ODtj3o+/bkxBXRIgCFnoOc2P0tbPBrRXBbZOoT5Xax+YvMRi1hsLjcdmG0qfnYHE
# ckC14l/vC0X/o84Xpi1VsLewvFRqnbyNVlPG8Lp5UEks9wO5/i9lNfIi6iwHr0bZ
# +UYc3Ix8cSjz/qfGFN1VkW6KEQ3fBiSVfQ+noXw62oY1YdMCAwEAAaOCAWQwggFg
# MB8GA1UdIwQYMBaAFFN5v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1UdDgQWBBQO4Tqo
# Uzox1Yq+wbutZxoDha00DjAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHSUEFjAUBggrBgEFBQcDAwYIKwYBBQUHAwgwEQYDVR0gBAowCDAG
# BgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwudXNlcnRydXN0LmNv
# bS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDB2BggrBgEF
# BQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9V
# U0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcwAYYZaHR0cDovL29j
# c3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEATWNQ7Uc0SmGk295q
# Koyb8QAAHh1iezrXMsL2s+Bjs/thAIiaG20QBwRPvrjqiXgi6w9G7PNGXkBGiRL0
# C3danCpBOvzW9Ovn9xWVM8Ohgyi33i/klPeFM4MtSkBIv5rCT0qxjyT0s4E307dk
# sKYjalloUkJf/wTr4XRleQj1qZPea3FAmZa6ePG5yOLDCBaxq2NayBWAbXReSnV+
# pbjDbLXP30p5h1zHQE1jNfYw08+1Cg4LBH+gS667o6XQhACTPlNdNKUANWlsvp8g
# JRANGftQkGG+OY96jk32nw4e/gdREmaDJhlIlc5KycF/8zoFm/lv34h/wCOe0h5D
# ekUxwZxNqfBZslkZ6GqNKQQCd3xLS81wvjqyVVp4Pry7bwMQJXcVNIr5NsxDkuS6
# T/FikyglVyn7URnHoSVAaoRXxrKdsbwcCtp8Z359LukoTBh+xHsxQXGaSynsCz1X
# UNLK3f2eBVHlRHjdAd6xdZgNVCT98E7j4viDvXK6yz067vBeF5Jobchh+abxKgoL
# pbn0nu6YMgWFnuv5gynTxix9vTp3Los3QqBqgu07SqqUEKThDfgXxbZaeTMYkuO1
# dfih6Y4KJR7kHvGfWocj/5+kUZ77OYARzdu1xKeogG/lU9Tg46LC0lsa+jImLWpX
# cBw8pFguo/NbSwfcMlnzh6cabVgwggZqMIIFUqADAgECAhADAZoCOv9YsWvW1erm
# F/BmMA0GCSqGSIb3DQEBBQUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERp
# Z2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTAeFw0xNDEwMjIwMDAwMDBaFw0yNDEwMjIw
# MDAwMDBaMEcxCzAJBgNVBAYTAlVTMREwDwYDVQQKEwhEaWdpQ2VydDElMCMGA1UE
# AxMcRGlnaUNlcnQgVGltZXN0YW1wIFJlc3BvbmRlcjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAKNkXfx8s+CCNeDg9sYq5kl1O8xu4FOpnx9kWeZ8a39r
# jJ1V+JLjntVaY1sCSVDZg85vZu7dy4XpX6X51Id0iEQ7Gcnl9ZGfxhQ5rCTqqEss
# kYnMXij0ZLZQt/USs3OWCmejvmGfrvP9Enh1DqZbFP1FI46GRFV9GIYFjFWHeUhG
# 98oOjafeTl/iqLYtWQJhiGFyGGi5uHzu5uc0LzF3gTAfuzYBje8n4/ea8EwxZI3j
# 6/oZh6h+z+yMDDZbesF6uHjHyQYuRhDIjegEYNu8c3T6Ttj+qkDxss5wRoPp2kCh
# WTrZFQlXmVYwk/PJYczQCMxr7GJCkawCwO+k8IkRj3cCAwEAAaOCAzUwggMxMA4G
# A1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMIIBvwYDVR0gBIIBtjCCAbIwggGhBglghkgBhv1sBwEwggGSMCgGCCsGAQUF
# BwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMIIBZAYIKwYBBQUHAgIw
# ggFWHoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkAcwAgAEMAZQByAHQA
# aQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUAcwAgAGEAYwBjAGUA
# cAB0AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMA
# UAAvAEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEA
# cgB0AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMAaAAgAGwAaQBtAGkA
# dAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIAZQAgAGkAbgBjAG8A
# cgBwAG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkAIAByAGUAZgBlAHIA
# ZQBuAGMAZQAuMAsGCWCGSAGG/WwDFTAfBgNVHSMEGDAWgBQVABIrE5iymQftHt+i
# vlcNK2cCzTAdBgNVHQ4EFgQUYVpNJLZJMp1KKnkag0v0HonByn0wfQYDVR0fBHYw
# dDA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJl
# ZElEQ0EtMS5jcmwwOKA2oDSGMmh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRENBLTEuY3JsMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURDQS0xLmNydDAN
# BgkqhkiG9w0BAQUFAAOCAQEAnSV+GzNNsiaBXJuGziMgD4CH5Yj//7HUaiwx7ToX
# GXEXzakbvFoWOQCd42yE5FpA+94GAYw3+puxnSR+/iCkV61bt5qwYCbqaVchXTQv
# H3Gwg5QZBWs1kBCge5fH9j/n4hFBpr1i2fAnPTgdKG86Ugnw7HBi02JLsOBzppLA
# 044x2C/jbRcTBu7kA7YUq/OPQ6dxnSHdFMoVXZJB2vkPgdGZdA0mxA5/G7X1oPHG
# dwYoFenYk+VVFvC7Cqsc21xIJ2bIo4sKHOWV2q7ELlmgYd3a822iYemKC23sEhi9
# 91VUQAOSK2vCUcIKSK+w1G7g9BQKOhvjjz3Kr2qNe9zYRDCCBs0wggW1oAMCAQIC
# EAb9+QOWA63qAArrPye7uhswDQYJKoZIhvcNAQEFBQAwZTELMAkGA1UEBhMCVVMx
# FTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNv
# bTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTA2MTEx
# MDAwMDAwMFoXDTIxMTExMDAwMDAwMFowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UE
# AxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEA6IItmfnKwkKVpYBzQHDSnlZUXKnE0kEGj8kz/E1FkVyBn+0s
# nPgWWd+etSQVwpi5tHdJ3InECtqvy15r7a2wcTHrzzpADEZNk+yLejYIA6sMNP4Y
# SYL+x8cxSIB8HqIPkg5QycaH6zY/2DDD/6b3+6LNb3Mj/qxWBZDwMiEWicZwiPkF
# l32jx0PdAug7Pe2xQaPtP77blUjE7h6z8rwMK5nQxl0SQoHhg26Ccz8mSxSQrllm
# CsSNvtLOBq6thG9IhJtPQLnxTPKvmPv2zkBdXPao8S+v7Iki8msYZbHBc63X8djP
# Hgp0XEK4aH631XcKJ1Z8D2KkPzIUYJX9BwSiCQIDAQABo4IDejCCA3YwDgYDVR0P
# AQH/BAQDAgGGMDsGA1UdJQQ0MDIGCCsGAQUFBwMBBggrBgEFBQcDAgYIKwYBBQUH
# AwMGCCsGAQUFBwMEBggrBgEFBQcDCDCCAdIGA1UdIASCAckwggHFMIIBtAYKYIZI
# AYb9bAABBDCCAaQwOgYIKwYBBQUHAgEWLmh0dHA6Ly93d3cuZGlnaWNlcnQuY29t
# L3NzbC1jcHMtcmVwb3NpdG9yeS5odG0wggFkBggrBgEFBQcCAjCCAVYeggFSAEEA
# bgB5ACAAdQBzAGUAIABvAGYAIAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEA
# dABlACAAYwBvAG4AcwB0AGkAdAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMA
# ZQAgAG8AZgAgAHQAaABlACAARABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMA
# IABhAG4AZAAgAHQAaABlACAAUgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEA
# ZwByAGUAZQBtAGUAbgB0ACAAdwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEA
# YgBpAGwAaQB0AHkAIABhAG4AZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEA
# dABlAGQAIABoAGUAcgBlAGkAbgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4w
# CwYJYIZIAYb9bAMVMBIGA1UdEwEB/wQIMAYBAf8CAQAweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6
# Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmww
# HQYDVR0OBBYEFBUAEisTmLKZB+0e36K+Vw0rZwLNMB8GA1UdIwQYMBaAFEXroq/0
# ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBBQUAA4IBAQBGUD7Jtygkpzgdtlsp
# r1LPUukxR6tWXHvVDQtBs+/sdR90OPKyXGGinJXDUOSCuSPRujqGcq04eKx1XRcX
# NHJHhZRW0eu7NoR3zCSl8wQZVann4+erYs37iy2QwsDStZS9Xk+xBdIOPRqpFFum
# hjFiqKgz5Js5p8T1zh14dpQlc+Qqq8+cdkvtX8JLFuRLcEwAiR78xXm8TBJX/l/h
# HrwCXaj++wc4Tw3GXZG5D2dFzdaD7eeSDY2xaYxP+1ngIw/Sqq4AfO6cQg7Pkdcn
# txbuD8O9fAqg7iwIVYUiuOsYGk38KiGtSTGDR5V3cdyxG0tLHBCcdxTBnU8vWpUI
# KRAmMYIETjCCBEoCAQEwgZEwfDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0
# ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGln
# byBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdvIFJTQSBDb2RlIFNpZ25pbmcgQ0EC
# EQDUdpM6iqGV/ka3TP9ciP0/MA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIB
# DDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOLO/pTsA4wYHg4ubZAW3ml6
# aaoH99ubrcSwA9QIHDSWMA0GCSqGSIb3DQEBAQUABIIBABKjLRt7bO6QA/0c2UD4
# KkW52pH+H0gu2UD2JpkkVR1Jh+bfCPD13lPeYRGtRTcQPp/tUjCBjR/h7DxgdwUx
# ZWeA9Uc9gaCHaT7qMfGPxgduOz/PFsRFfgmutNvgf2kgzxOVIZXH7PzIRU2ZstNc
# a4kISGmCn53nXM9wvKZmLMJc+2t0j5uUCC2DS23NJmmbhHPlNw0WvqAI1/PyM/3C
# n+6t/lkQWkYvO+UlFWGpwHbYJJSsaq3mJ6ylCjIUTNi5ggcoE4qToRPQ+XlFx2mU
# o77RH25ELMZqgbDTYE0yWwTJcLjw+apvwdRRuhGJiN8pii32vELuDNbdHM51v6jG
# r+OhggIPMIICCwYJKoZIhvcNAQkGMYIB/DCCAfgCAQEwdjBiMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTECEAMBmgI6/1ix
# a9bV6uYX8GYwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEw
# HAYJKoZIhvcNAQkFMQ8XDTIwMDUxODEyMDY1NlowIwYJKoZIhvcNAQkEMRYEFBQP
# opwjtIoWO5a0pyFEhrX2o1/6MA0GCSqGSIb3DQEBAQUABIIBAH1fqtW3zP7Jc+3G
# 3GpsNnL+mqqOX2VcjFnVpzvGgq1RcdYjHJLyeN8VE2Ey1cwWojWIQ+lpQx9PdfH7
# 8Hov8xXEf1HiDo6uvku3EzfBTOOOR4PxnrKHTD8q24NXhqm1QgNnKeAJ0uPk3StI
# s94waBNgrGwS3pkwefGJuewUB9fn/Ss1CHnkyGvCb/0QlzuZ/BnnP6Oktdpp5DJE
# GJ2C/AuX789d6CV66b1zAX4/JsIOxy0hk75iHxnYKuiLtdAVqYO84pDykkcmZBtv
# D5LuCCNG+gLDrK5cmwPjqKQc0o/2r/K23Wo1PWC9wo7sWz47xfOhsN1tKNxMAkm1
# kUr6kkg=
# SIG # End signature block
