########################################################
#Configuring Intel turbo boost
###################################################----#

<#
.Synopsis
    Script to Enabled / Disabled Intel turbo boost of HPE Proliant Gen8, Gen9, and Gen10 Intel servers

.DESCRIPTION
    This script allows user to Enable / Disable Intel Turbo Boost Technology. This technology controls whether the processor transitions to a 
    higher frequency than the processor's rated speed if the processor has available power and is within temperature specifications.

.EXAMPLE
    ConfigureIntelTurboBoost.ps1

    This mode of execution of script will prompt for 
    
    -Address    :- Accept IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    -Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    -IntelturboBoost   :- Accepted values are "Enabled" or "Disabled".For multiple servers values should be separated by comma(,)

.EXAMPLE
    ConfigureIntelTurboBoost.ps1 -Address "10.20.30.40" -Credential $userCredential -IntelturboBoost Enabled

    This mode of script have input parameter for Address Credential and IntelturboBoost.
    
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to specify user credential. #In case of multiple servers use same credential for all the servers
    
    -IntelturboBoost :- Use this Parameter to specify boot mode. Accepted values are "Enabled" or "Disabled".

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.1.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    IntelTurboBoost

.OUTPUTS
    None (by default)

.LINK
    
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential,  #In case of multiple servers it use same credential for all the servers
    [String] $IntelturboBoost  # UEFI optimized boot mode
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
         Write-Host "Server $serverAddress pinged successfully."
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

Write-Host "This script allows user to Enable / Disable Intel Turbo Boost Technology."
Write-Host "The technology controls whether the processor transitions to a higher frequency than the processor's rated speed if the processor has available power and is within temperature specifications."
Write-Host ""

#dont shoe error in scrip

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"
$ErrorActionPreference = "SilentlyContinue"

#check powershell support
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

if($Address -eq "")
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
    $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential

    #Retry connection if it is failed because  of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "The underlying connection was closed")
    {
       $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        $connection
        if($connection.ProcessorInfo -match "Intel")
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "Intel turbo boost is not supported on Server $($connection.IP)"
			Disconnect-HPEBIOS -Connection $connection
        }
    }
    else
    {
         Write-Host "Connection cannot be eastablished to the server : $IPAddress" -ForegroundColor Red
    }
}

if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit"
    Write-Host ""
    exit
}

# Get current Intel turbo boost technology configuration

Write-Host ""
Write-Host "Current Intel turbo boost configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
    $result = $serverConnection | Get-HPEBIOSIntelTurboBoost
    Write-Host "----------------------- Server $counter -----------------------" -ForegroundColor Yellow
    Write-Host ""
    $result
    $counter++
}

# Get the valid value list fro each parameter
$parameterMetaData = $(Get-Command -Name Set-HPEBIOSIntelTurboBoost).Parameters
$turboBoostValidValues = $($parameterMetaData["IntelTurboBoost"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

if($IntelturboBoost -eq "")
{
    $IntelturboBoost = Read-Host "Enter IntelTurboBoost [Accepted values : ($($turboBoostValidValues -join ","))]."
    Write-Host ""
}

$inputIntelturboBoostList =  ($IntelturboBoost.Trim().Split(','))

if($inputIntelturboBoostList.Count -eq 0)
{
    Write-Host "You have not enterd Intel turbo boost value"
    Write-Host "Exit....."
    exit
}

[array]$IntelturboBoostToSet = @()
for($i = 0;$i -lt $ListOfConnection.Count ; $i++)
{
    if(($turboBoostValidValues | where {$_ -eq $inputIntelturboBoostList[$i]}) -ne $null)
    {
        $IntelturboBoostToSet += $inputIntelturboBoostList[$i];
    }
    
    else
    {
        Write-Host "Invalid value for Intel turbo boost" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

#Set the intel turbo boost configuration value provided by user
Write-Host "Changing Intel turbo boost configuration....." -ForegroundColor Green  
$failureCount = 0

if($ListOfConnection.Count -eq 1)
{
    $result = $ListOfConnection[0] | Set-HPEBIOSIntelTurboBoost -IntelTurboBoost $IntelturboBoostToSet[0]
    if($result.Status -eq "Error")
    {
        Write-Host ""
        Write-Host "Intel turbo boost cannot be changed"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.StatusInfo)"
		Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
        $failureCount++
    }
}
else
{
    if($BootModeToset.Count -eq 1)
    {
        $resultList = $ListOfConnection | Set-HPEBIOSIntelTurboBoost -IntelTurboBoost $IntelturboBoostToSet[0]
    }
    else
    {
        $resultList = $ListOfConnection |Set-HPEBIOSIntelTurboBoost -IntelTurboBoost $IntelturboBoostToSet
    }
        
    foreach($result in $resultList)
    {
        
        if($result.Status -eq "Error")
        {
            Write-Host ""
            Write-Host "Intel Turbo boost cannot be changed" -ForegroundColor Red
            Write-Host "Server : $($result.IP)"
            Write-Host "Error : $($result.StatusInfo)"
			Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
			Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
			Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
            $failureCount++
        }
    }
}

#Get Intel turbo boost technology configuration after set
if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "Intel Turbo boost configuration changed successfully" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $result = $serverConnection | Get-HPEBIOSIntelTurboBoost
        Write-Host "----------------------- Server $counter -----------------------" -ForegroundColor Yellow
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
# MIIkYQYJKoZIhvcNAQcCoIIkUjCCJE4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB+11TsWXIi+FcP
# sSsBpu3NpWHi4qMkq/QnEETZmhyKoKCCHtUwggQUMIIC/KADAgECAgsEAAAAAAEv
# TuFS1zANBgkqhkiG9w0BAQUFADBXMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xv
# YmFsU2lnbiBudi1zYTEQMA4GA1UECxMHUm9vdCBDQTEbMBkGA1UEAxMSR2xvYmFs
# U2lnbiBSb290IENBMB4XDTExMDQxMzEwMDAwMFoXDTI4MDEyODEyMDAwMFowUjEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMT
# H0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzIwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCU72X4tVefoFMNNAbrCR+3Rxhqy/Bb5P8npTTR94ka
# v56xzRJBbmbUgaCFi2RaRi+ZoI13seK8XN0i12pn0LvoynTei08NsFLlkFvrRw7x
# 55+cC5BlPheWMEVybTmhFzbKuaCMG08IGfaBMa1hFqRi5rRAnsP8+5X2+7UulYGY
# 4O/F69gCWXh396rjUmtQkSnF/PfNk2XSYGEi8gb7Mt0WUfoO/Yow8BcJp7vzBK6r
# kOds33qp9O/EYidfb5ltOHSqEYva38cUTOmFsuzCfUomj+dWuqbgz5JTgHT0A+xo
# smC8hCAAgxuh7rR0BcEpjmLQR7H68FPMGPkuO/lwfrQlAgMBAAGjgeUwgeIwDgYD
# VR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFEbYPv/c
# 477/g+b0hZuw3WrWFKnBMEcGA1UdIARAMD4wPAYEVR0gADA0MDIGCCsGAQUFBwIB
# FiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAzBgNVHR8E
# LDAqMCigJqAkhiJodHRwOi8vY3JsLmdsb2JhbHNpZ24ubmV0L3Jvb3QuY3JsMB8G
# A1UdIwQYMBaAFGB7ZhpFDZfKiVAvfQTNNKj//P1LMA0GCSqGSIb3DQEBBQUAA4IB
# AQBOXlaQHka02Ukx87sXOSgbwhbd/UHcCQUEm2+yoprWmS5AmQBVteo/pSB204Y0
# 1BfMVTrHgu7vqLq82AafFVDfzRZ7UjoC1xka/a/weFzgS8UY3zokHtqsuKlYBAIH
# MNuwEl7+Mb7wBEj08HD4Ol5Wg889+w289MXtl5251NulJ4TjOJuLpzWGRCCkO22k
# aguhg/0o69rvKPbMiF37CjsAq+Ah6+IvNWwPjjRFl+ui95kzNX7Lmoq7RU3nP5/C
# 2Yr6ZbJux35l/+iS4SwxovewJzZIjyZvO+5Ndh95w+V/ljW8LQ7MAbCOf/9RgICn
# ktSzREZkjIdPFmMHMUtjsN/zMIIEnzCCA4egAwIBAgISESHWmadklz7x+EJ+6RnM
# U0EUMA0GCSqGSIb3DQEBBQUAMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFtcGluZyBD
# QSAtIEcyMB4XDTE2MDUyNDAwMDAwMFoXDTI3MDYyNDAwMDAwMFowYDELMAkGA1UE
# BhMCU0cxHzAdBgNVBAoTFkdNTyBHbG9iYWxTaWduIFB0ZSBMdGQxMDAuBgNVBAMT
# J0dsb2JhbFNpZ24gVFNBIGZvciBNUyBBdXRoZW50aWNvZGUgLSBHMjCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBALAXrqLTtgQwVh5YD7HtVaTWVMvY9nM6
# 7F1eqyX9NqX6hMNhQMVGtVlSO0KiLl8TYhCpW+Zz1pIlsX0j4wazhzoOQ/DXAIlT
# ohExUihuXUByPPIJd6dJkpfUbJCgdqf9uNyznfIHYCxPWJgAa9MVVOD63f+ALF8Y
# ppj/1KvsoUVZsi5vYl3g2Rmsi1ecqCYr2RelENJHCBpwLDOLf2iAKrWhXWvdjQIC
# KQOqfDe7uylOPVOTs6b6j9JYkxVMuS2rgKOjJfuv9whksHpED1wQ119hN6pOa9PS
# UyWdgnP6LPlysKkZOSpQ+qnQPDrK6Fvv9V9R9PkK2Zc13mqF5iMEQq8CAwEAAaOC
# AV8wggFbMA4GA1UdDwEB/wQEAwIHgDBMBgNVHSAERTBDMEEGCSsGAQQBoDIBHjA0
# MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0
# b3J5LzAJBgNVHRMEAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMEIGA1UdHwQ7
# MDkwN6A1oDOGMWh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vZ3MvZ3N0aW1lc3Rh
# bXBpbmdnMi5jcmwwVAYIKwYBBQUHAQEESDBGMEQGCCsGAQUFBzAChjhodHRwOi8v
# c2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc3RpbWVzdGFtcGluZ2cyLmNy
# dDAdBgNVHQ4EFgQU1KKESjhaGH+6TzBQvZ3VeofWCfcwHwYDVR0jBBgwFoAURtg+
# /9zjvv+D5vSFm7DdatYUqcEwDQYJKoZIhvcNAQEFBQADggEBAI+pGpFtBKY3IA6D
# lt4j02tuH27dZD1oISK1+Ec2aY7hpUXHJKIitykJzFRarsa8zWOOsz1QSOW0zK7N
# ko2eKIsTShGqvaPv07I2/LShcr9tl2N5jES8cC9+87zdglOrGvbr+hyXvLY3nKQc
# MLyrvC1HNt+SIAPoccZY9nUFmjTwC1lagkQ0qoDkL4T2R12WybbKyp23prrkUNPU
# N7i6IA7Q05IqW8RZu6Ft2zzORJ3BOCqt4429zQl3GhC+ZwoCNmSIubMbJu7nnmDE
# Rqi8YTNsz065nLlq8J83/rU9T5rTTf/eII5Ol6b9nwm8TcoYdsmwTYVQ8oDSHQb1
# WAQHsRgwggVMMIIDNKADAgECAhMzAAAANdjVWVsGcUErAAAAAAA1MA0GCSqGSIb3
# DQEBBQUAMH8xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAn
# BgNVBAMTIE1pY3Jvc29mdCBDb2RlIFZlcmlmaWNhdGlvbiBSb290MB4XDTEzMDgx
# NTIwMjYzMFoXDTIzMDgxNTIwMzYzMFowbzELMAkGA1UEBhMCU0UxFDASBgNVBAoT
# C0FkZFRydXN0IEFCMSYwJAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5hbCBUVFAgTmV0
# d29yazEiMCAGA1UEAxMZQWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9vdDCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBALf3GjPm8gAELTngTlvtH7xsD821+iO2
# zt6bETOXpClMfZOfvUq8k+0DGuOPz+VtUFrWlymUWoCwSXrbLpX9uMq/NzgtHj6R
# Qa1wVsfwTz/oMp50ysiQVOnGXw94nZpAPA6sYapeFI+eh6FqUNzXmk6vBbOmcZSc
# cbNQYArHE504B4YCqOmoaSYYkKtMsE8jqzpPhNjfzp/haW+710LXa0Tkx63ubUFf
# clpxCDezeWWkWaCUN/cALw3CknLa0Dhy2xSoRcRdKn23tNbE7qzNE0S3ySvdQwAl
# +mG5aWpYIxG3pzOPVnVZ9c0p10a3CitlttNCbxWyuHv77+ldU9U0WicCAwEAAaOB
# 0DCBzTATBgNVHSUEDDAKBggrBgEFBQcDAzASBgNVHRMBAf8ECDAGAQH/AgECMB0G
# A1UdDgQWBBStvZh6NLQm9/rEJlTvA73gJMtUGjALBgNVHQ8EBAMCAYYwHwYDVR0j
# BBgwFoAUYvsKIVt/Q24R2glUUGv10pZx8Z4wVQYDVR0fBE4wTDBKoEigRoZEaHR0
# cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0
# Q29kZVZlcmlmUm9vdC5jcmwwDQYJKoZIhvcNAQEFBQADggIBADYrovLhMx/kk/fy
# aYXGZA7Jm2Mv5HA3mP2U7HvP+KFCRvntak6NNGk2BVV6HrutjJlClgbpJagmhL7B
# vxapfKpbBLf90cD0Ar4o7fV3x5v+OvbowXvTgqv6FE7PK8/l1bVIQLGjj4OLrSsl
# U6umNM7yQ/dPLOndHk5atrroOxCZJAC8UP149uUjqImUk/e3QTA3Sle35kTZyd+Z
# BapE/HSvgmTMB8sBtgnDLuPoMqe0n0F4x6GENlRi8uwVCsjq0IT48eBr9FYSX5Xg
# /N23dpP+KUol6QQA8bQRDsmEntsXffUepY42KRk6bWxGS9ercCQojQWj2dUk8vig
# 0TyCOdSogg5pOoEJ/Abwx1kzhDaTBkGRIywipacBK1C0KK7bRrBZG4azm4foSU45
# C20U30wDMB4fX3Su9VtZA1PsmBbg0GI1dRtIuH0T5XpIuHdSpAeYJTsGm3pOam9E
# hk8UTyd5Jz1Qc0FMnEE+3SkMc7HH+x92DBdlBOvSUBCSQUns5AZ9NhVEb4m/aX35
# TUDBOpi2oH4x0rWuyvtT1T9Qhs1ekzttXXyaPz/3qSVYhN0RSQCix8ieN913jm1x
# i+BbgTRdVLrM9ZNHiG3n71viKOSAG0DkDyrRfyMVZVqsmZRDP0ZVJtbE+oiV4pGa
# oy0Lhd6sjOD5Z3CfcXkCMfdhoinEMIIFajCCBFKgAwIBAgIRAKe3/pHyvMv1yr56
# CgaXQBgwDQYJKoZIhvcNAQELBQAwfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdy
# ZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09N
# T0RPIENBIExpbWl0ZWQxIzAhBgNVBAMTGkNPTU9ETyBSU0EgQ29kZSBTaWduaW5n
# IENBMB4XDTE3MDUyNjAwMDAwMFoXDTE4MDUyNjIzNTk1OVowgdIxCzAJBgNVBAYT
# AlVTMQ4wDAYDVQQRDAU5NDMwNDELMAkGA1UECAwCQ0ExEjAQBgNVBAcMCVBhbG8g
# QWx0bzEcMBoGA1UECQwTMzAwMCBIYW5vdmVyIFN0cmVldDErMCkGA1UECgwiSGV3
# bGV0dCBQYWNrYXJkIEVudGVycHJpc2UgQ29tcGFueTEaMBgGA1UECwwRSFAgQ3li
# ZXIgU2VjdXJpdHkxKzApBgNVBAMMIkhld2xldHQgUGFja2FyZCBFbnRlcnByaXNl
# IENvbXBhbnkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCelXai046B
# hPhj4jxPC8YxDCkDlv+KxVBT6PWVni2HMlHTmZWAvh4KWv6iV1S3K4TantAms7+h
# TyHNLI2LZPIHyVv2pde58/nvaJaoBO5hbbv2IhW/xzGycySDTX575SAEFuRAkL/h
# 5Epti26Gu2Mc7Fii22Ne4Ds+nCWMQzS6k4MiOBlp2mHknWZJc3ZqcVjKywJcyJkc
# EJe+rItDB7SfJq0mhlHsJi5m/UJxXs50MdYoGJOQrIiLmr5owho0KPJspomnls9X
# JXRqsORixMhLuWle2z9L9M+yMMMFrbfmD+j1Cu4MyXW6I0ZsXN2qgwMA+s+KdrZu
# 6s1Vu3YGq+FnAgMBAAGjggGNMIIBiTAfBgNVHSMEGDAWgBQpkWD/ik366/mmarjP
# +eZLvUnOEjAdBgNVHQ4EFgQUzLLiuS0XHd44yiqOEytZw/+QWogwDgYDVR0PAQH/
# BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYJYIZI
# AYb4QgEBBAQDAgQQMEYGA1UdIAQ/MD0wOwYMKwYBBAGyMQECAQMCMCswKQYIKwYB
# BQUHAgEWHWh0dHBzOi8vc2VjdXJlLmNvbW9kby5uZXQvQ1BTMEMGA1UdHwQ8MDow
# OKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0NPTU9ET1JTQUNvZGVTaWdu
# aW5nQ0EuY3JsMHQGCCsGAQUFBwEBBGgwZjA+BggrBgEFBQcwAoYyaHR0cDovL2Ny
# dC5jb21vZG9jYS5jb20vQ09NT0RPUlNBQ29kZVNpZ25pbmdDQS5jcnQwJAYIKwYB
# BQUHMAGGGGh0dHA6Ly9vY3NwLmNvbW9kb2NhLmNvbTANBgkqhkiG9w0BAQsFAAOC
# AQEAZHyiH6fGpfKs/guW+drx6EuxKExQLU0C6NB3ckIHcIcvQ5TogP9TixEjOrVn
# h34uJYCpc1mn8HrWNZIRwIGMAdiCpJQtTgQUsp5v6ZeKzIUT6z6A6eDsBq7FubaQ
# kWdu5UOqT6z1qHITzToO6qN6mxwxZmcoHYAvf3dW2VJNt/1DS2gp4ngb1D6BsKQ9
# Fv36aHLnhUjsMtA/V23LeYb3PFZNzfXYOfhMtbfbmhsU2o95G3KQ7qvV5222K7TX
# xRoobV+RJngl9ZqeeonwYGFgBl7nje2VJYmMEBiaoLIXq0VVPBFYfZBC4DPcZs8V
# DN7nhpxRzTIm1l1CnmX0MY7VTTCCBXQwggRcoAMCAQICECdm7lbrSfOOq9dwovyE
# 3iIwDQYJKoZIhvcNAQEMBQAwbzELMAkGA1UEBhMCU0UxFDASBgNVBAoTC0FkZFRy
# dXN0IEFCMSYwJAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5hbCBUVFAgTmV0d29yazEi
# MCAGA1UEAxMZQWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9vdDAeFw0wMDA1MzAxMDQ4
# MzhaFw0yMDA1MzAxMDQ4MzhaMIGFMQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3Jl
# YXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01P
# RE8gQ0EgTGltaXRlZDErMCkGA1UEAxMiQ09NT0RPIFJTQSBDZXJ0aWZpY2F0aW9u
# IEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJHoVJLS
# ClaxrA0k3cXPRGd0mSs3o30jcABxvFPfxPoqEo9LfxBWvZ9wcrdhf8lLDxenPeOw
# BGHu/xGXx/SGPgr6Plz5k+Y0etkUa+ecs4Wggnp2r3GQ1+z9DfqcbPrfsIL0FH75
# vsSmL09/mX+1/GdDcr0MANaJ62ss0+2PmBwUq37l42782KjkkiTaQ2tiuFX96sG8
# bLaL8w6NmuSbbGmZ+HhIMEXVreENPEVg/DKWUSe8Z8PKLrZr6kbHxyCgsR9l3kgI
# uqROqfKDRjeE6+jMgUhDZ05yKptcvUwbKIpcInu0q5jZ7uBRg8MJRk5tPpn6lRfa
# fDNXQTyNUe0LtlyvLGMa31fIP7zpXcSbr0WZ4qNaJLS6qVY9z2+q/0lYvvCo//S4
# rek3+7q49As6+ehDQh6J2ITLE/HZu+GJYLiMKFasFB2cCudx688O3T2plqFIvTz3
# r7UNIkzAEYHsVjv206LiW7eyBCJSlYCTaeiOTGXxkQMtcHQC6otnFSlpUgK7199Q
# alVGv6CjKGF/cNDDoqosIapHziicBkV2v4IYJ7TVrrTLUOZr9EyGcTDppt8WhuDY
# /0Dd+9BCiH+jMzouXB5BEYFjzhhxayvspoq3MVw6akfgw3lZ1iAar/JqmKpyvFdK
# 0kuduxD8sExB5e0dPV4onZzMv7NR2qdH5YRTAgMBAAGjgfQwgfEwHwYDVR0jBBgw
# FoAUrb2YejS0Jvf6xCZU7wO94CTLVBowHQYDVR0OBBYEFLuvfgI9+qbxPISOre44
# mOzZMjLUMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MBEGA1UdIAQK
# MAgwBgYEVR0gADBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3JsLnVzZXJ0cnVz
# dC5jb20vQWRkVHJ1c3RFeHRlcm5hbENBUm9vdC5jcmwwNQYIKwYBBQUHAQEEKTAn
# MCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3
# DQEBDAUAA4IBAQBkv4PxX5qF0M24oSlXDeha99HpPvJ2BG7xUnC7Hjz/TQ10asyB
# giXTw6AqXUz1uouhbcRUCXXH4ycOXYR5N0ATd/W0rBzQO6sXEtbvNBh+K+l506tX
# RQyvKPrQ2+VQlYi734VXaX2S2FLKc4G/HPPmuG5mEQWzHpQtf5GVklnxTM6jkXFM
# fEcMOwsZ9qGxbIY+XKrELoLL+QeWukhNkPKUyKlzousGeyOd3qLzTVWfemFFmBho
# x15AayP1eXrvjLVri7dvRvR78T1LBNiTgFla4EEkHbKPFWBYR9vvbkb9FfXZX5qz
# 29i45ECzzZc5roW7HY683Ieb0abv8TtvEDhvMIIF4DCCA8igAwIBAgIQLnyHzA6T
# SlL+lP0ct800rzANBgkqhkiG9w0BAQwFADCBhTELMAkGA1UEBhMCR0IxGzAZBgNV
# BAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UE
# ChMRQ09NT0RPIENBIExpbWl0ZWQxKzApBgNVBAMTIkNPTU9ETyBSU0EgQ2VydGlm
# aWNhdGlvbiBBdXRob3JpdHkwHhcNMTMwNTA5MDAwMDAwWhcNMjgwNTA4MjM1OTU5
# WjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAw
# DgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDEjMCEG
# A1UEAxMaQ09NT0RPIFJTQSBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCmmJBjd5E0f4rR3elnMRHrzB79MR2zuWJXP5O8W+Of
# HiQyESdrvFGRp8+eniWzX4GoGA8dHiAwDvthe4YJs+P9omidHCydv3Lj5HWg5TUj
# jsmK7hoMZMfYQqF7tVIDSzqwjiNLS2PgIpQ3e9V5kAoUGFEs5v7BEvAcP2FhCoyi
# 3PbDMKrNKBh1SMF5WgjNu4xVjPfUdpA6M0ZQc5hc9IVKaw+A3V7Wvf2pL8Al9fl4
# 141fEMJEVTyQPDFGy3CuB6kK46/BAW+QGiPiXzjbxghdR7ODQfAuADcUuRKqeZJS
# zYcPe9hiKaR+ML0btYxytEjy4+gh+V5MYnmLAgaff9ULAgMBAAGjggFRMIIBTTAf
# BgNVHSMEGDAWgBS7r34CPfqm8TyEjq3uOJjs2TIy1DAdBgNVHQ4EFgQUKZFg/4pN
# +uv5pmq4z/nmS71JzhIwDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8C
# AQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYDVR0gBAowCDAGBgRVHSAAMEwGA1Ud
# HwRFMEMwQaA/oD2GO2h0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0NPTU9ET1JTQUNl
# cnRpZmljYXRpb25BdXRob3JpdHkuY3JsMHEGCCsGAQUFBwEBBGUwYzA7BggrBgEF
# BQcwAoYvaHR0cDovL2NydC5jb21vZG9jYS5jb20vQ09NT0RPUlNBQWRkVHJ1c3RD
# QS5jcnQwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNvbW9kb2NhLmNvbTANBgkq
# hkiG9w0BAQwFAAOCAgEAAj8COcPu+Mo7id4MbU2x8U6ST6/COCwEzMVjEasJY6+r
# otcCP8xvGcM91hoIlP8l2KmIpysQGuCbsQciGlEcOtTh6Qm/5iR0rx57FjFuI+9U
# US1SAuJ1CAVM8bdR4VEAxof2bO4QRHZXavHfWGshqknUfDdOvf+2dVRAGDZXZxHN
# TwLk/vPa/HUX2+y392UJI0kfQ1eD6n4gd2HITfK7ZU2o94VFB696aSdlkClAi997
# OlE5jKgfcHmtbUIgos8MbAOMTM1zB5TnWo46BLqioXwfy2M6FafUFRunUkcyqfS/
# ZEfRqh9TTjIwc8Jvt3iCnVz/RrtrIh2IC/gbqjSm/Iz13X9ljIwxVzHQNuxHoc/L
# i6jvHBhYxQZ3ykubUa9MCEp6j+KjUuKOjswm5LLY5TjCqO3GgZw1a6lYYUoKl7RL
# QrZVnb6Z53BtWfhtKgx/GWBfDJqIbDCsUgmQFhv/K53b0CDKieoofjKOGd97SDMe
# 12X4rsn4gxSTdn1k0I7OvjV9/3IxTZ+evR5sL6iPDAZQ+4wns3bJ9ObXwzTijIch
# hmH+v1V04SF3AwpobLvkyanmz1kl63zsRQ55ZmjoIs2475iFTZYRPAmK0H+8KCgT
# +2rKVI2SXM3CZZgGns5IW9S1N5NGQXwH3c/6Q++6Z2H/fUnguzB9XIDj5hY5S6cx
# ggTiMIIE3gIBATCBkjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBN
# YW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0Eg
# TGltaXRlZDEjMCEGA1UEAxMaQ09NT0RPIFJTQSBDb2RlIFNpZ25pbmcgQ0ECEQCn
# t/6R8rzL9cq+egoGl0AYMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDEC
# MAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGjFDOxrnFaA9z/v7WoNGgqw2MCH
# q2Zt0MEu4IB49UPqMA0GCSqGSIb3DQEBAQUABIIBAC0amc5BtEeTUTsrde3bSsKL
# nuiT69tHSIfUr6/W0s8+tiZZjie+6RFUYsKrrG0LSpDp6cGtDJl2tbTMj0G5gQ6c
# cGAip3sHKwE+j1G/Inqj92lVR59sfAgka42uoIevJoOy3XPahqV3D0S2pjwFmm9e
# dsh07AbdbYI8KqY5iA7O6xWJt0GVZc/4temdei9RJ7D7TdLhn8/KYK4dmokEFuM7
# 12qXVkHdCYQnhNMGG83+7O5+NJlc8nbQp52mW5SaHWBT7nemOvhWI5PZpeftaAjQ
# oHGRqcWGABOEay4El7asLGxQqIRrYqmZZE7OwbU8LY+Tvdj+4AIyyIiDCUtYRS6h
# ggKiMIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZ
# MBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBU
# aW1lc3RhbXBpbmcgQ0EgLSBHMgISESHWmadklz7x+EJ+6RnMU0EUMAkGBSsOAwIa
# BQCggf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcN
# MTgwMzA5MTAxMDIzWjAjBgkqhkiG9w0BCQQxFgQU3BT6pjoSB/WAKgjM3OvRhPrU
# 2DUwgZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBRjuC+rYfWDkJaVBQsAJJxQ
# KTPseTBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBu
# di1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgIS
# ESHWmadklz7x+EJ+6RnMU0EUMA0GCSqGSIb3DQEBAQUABIIBAFJAOrGp73rgwaWr
# snErcfR8v6AOlRsQ46SKPv90Z8DeFcWL5F8p6rK/kj/yRPaEeSaXskEcP/j6R+wH
# M0/XspmtLLBqkK2HOx/cB1e0n8aBq6369oE0l1/2GAD62hq7YZzpQdO8lzfytT+c
# 4X2sl6r93YACPpiTbZD6Un4gFpeDLfSqtK6X91n5mzDYe2Zh9lpOVPUlEOSXGTqy
# ejTsU9XjY4i/XLkkqc6fsqmi6r/3yu2QmlqnZaMyosO76KXH6X3fU2hyQF3xhphz
# foElb8hFhvv5FczCMOntxEMC0fh+EZHrmAWfe+Oj256h51vjQG1+26dlVJcR/Dtr
# i1Xfzrg=
# SIG # End signature block
