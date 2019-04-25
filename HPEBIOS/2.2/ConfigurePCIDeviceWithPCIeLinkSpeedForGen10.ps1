########################################################
#Configure PCI Device on Gen10 servers
###################################################----#

<#
.Synopsis
    This Script allows user to configure PCI device for HPE Proliant Gen10 servers

.DESCRIPTION
    This script allows user to configure PCI device.Following features can be configured. This script works for single server at a time.
    PCIDeviceEnable/PCIDeviceDisable
    PCIeLinkSpeed
    
.EXAMPLE
    ConfigurePCIDeviceWithPCIeLinkSpeedForGen10.ps1

    This mode of execution of script will prompt for 
   
    -Address    :- Accept IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
   
    -Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
   
    -PCIDevice   :- Accepted values are listed under enum [HPE.BIOS.PCIDeviceForGen10].
   
    -PCIeLinkSpeed :- Accepted values are listed under enum [HPE.BIOS.PCIeLinkSpeed].
      

.EXAMPLE
    ConfigurePCIDeviceWithPCIeLinkSpeedForGen10.ps1 -Address "10.20.30.40" -Credential $userCredential -PCIDevice @(,@("EmbeddedNIC","EmbeddedSAS1")) -PCIeLinkSpeed @(,@("Auto")) -EnablePCIDevice

    This mode of script have input parameter for Address, Credential, PCIDevice, PCIeLinkSpeed, EnablPCIDevice, and DisablePCIDevice.
   
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server.
   
    -Credential :- Use this parameter to specify user Credential.
   
    -PCIDevice :- Use this Parameter to specify PCIDevice.
   
    -PCIeLinkSpeed : - This parameter to specify PCIeLinkSpeed.
   
    -EnablPCIDevice :- Switch parameter to enable PCI device.
   
    -DisablePCIDevice :- Switch parameter to disable PCI device.
    

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.2.0.0
    Date    : 21/07/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    PCIDevice
    PCIeLinkSpeed
    

.OUTPUTS
    None (by default)

.LINK
    
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s),
    [PSCredential]$Credential, # credential for server
    [String[]]$PCIDevice,
    [String[]]$PCIeLinkSpeed,
    [Switch]$EnablePCIDevice,
    [Switch]$DisablePCIDevice
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

Write-Host "This script allows user to configure PCI Device on one target server.Following features can be configured."
Write-Host "Enabled and Disabled the PCI device"
Write-Host "Configure the PCIeLinkSpeed for the input PCIDevice"
Write-Host ""
Write-Host "This script works for single server at a time." -ForegroundColor Yellow

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
    $tempAddress = Read-Host "Enter single Server address (IP or Hostname)."

    if($tempAddress -ne "")
    {
        $Address = $tempAddress.Split(',')
    }
    else{
        Write-Host "You have not entered IP(s) or Hostname(s)"
        Write-Host "`nExit ..."
        exit
    }

}
    

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password"
    Write-Host ""
}

#Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($Address)

#Create connection object
[array]$ListOfConnection = @()
$connection = $null
[int] $connectionCount = 0

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
        if($connection.ProductName.Contains("Gen10"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "Get/Set-HPEBIOSPCIDeviceConfiguration  is not supported on server $($connection.IP)"
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
    Write-Host "`nExit"
    exit
}

# Get current PCIDeviceConfiguration

Write-Host "`nCurrent PCI Device Configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
        $getResult = $serverConnection | Get-HPEBIOSPCIDeviceConfiguration
        
        Write-Host "-------------------Server $($getResult.IP) -------------------" -ForegroundColor Yellow
        Write-Host ""
        $getResult.PCIDevice
        $CurrentPCIDeviceConfiguration += $getResult
        $counter++
}


# Get the valid value list fro each parameter
$workloadProfileParameterMetaData = $(Get-Command -Name Set-HPEBIOSWorkloadProfile).Parameters
$workloadProfileValidValues = $($workloadProfileParameterMetaData["WorkloadProfile"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

$PCIDeviceValidValues = [System.Enum]::GetNames([HPE.BIOS.PCIDeviceForGen10])
$PCIeLInkSpeedValidValues = [System.Enum]::GetNames([HPE.BIOS.PCIeLinkSpeed])

if($PCIDevice.Count -eq 0)
{
    $tempPCIDevice = Read-Host "Enter PCI device name [Accepted values : $($getResult.PCIDevice.Name -join ",")] "
    Write-Host ""
    if($tempPCIDevice -ne "")
    {
        $PCIDevice = $tempPCIDevice.Split(',')
    }
    else{
        Write-Host "No PCI device is provided"
        Write-Host "Exit....."
        exit
    }
}

if($PCIeLinkSpeed.Count -eq 0)
{
    $tempPCIeLinkSpeed = Read-Host "Enter PCIe link speed [Accepted values : $($PCIeLInkSpeedValidValues -join ",")]"
    Write-Host ""
    if($tempPCIeLinkSpeed -ne "")
    {
        $PCIeLinkSpeed = $tempPCIeLinkSpeed.Split(',')
    }
}


for($i = 0 ; $i -lt $PCIDevice.Count ;$i++)
{
    
    #validate user input PCIDevice
    if($($PCIDeviceValidValues | where{$_ -eq $PCIDevice[$i] }) -eq $null)
    {
        Write-Host "Invalid PCI device name" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

for($i = 0 ; $i -lt $PCIeLinkSpeed.Count ;$i++)
{
    #validate user input PCIeLinkSpeed
    if($($PCIeLInkSpeedValidValues | where{$_ -eq $PCIeLinkSpeed[$i] }) -eq $null)
    {
        Write-Host "Invalid PCIeLinkSpeed value" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Configuring PCIDevice ....." -ForegroundColor Green  
$failureCount = 0
$cmdletInput = New-Object -TypeName psobject

if($PCIeLinkSpeed.Count -ne 0)
{
    $cmdletInput | Add-Member "PCIDevice" @(,$PCIDevice)
    $cmdletInput | Add-Member "PCIeLinkSpeed" @(,$PCIeLinkSpeed)
}
else
{
   $cmdletInput | Add-Member "PCIDevice" @(,$PCIDevice) 
}

if($ListOfConnection.Count -ne 0)
{
    if($EnablePCIDevice){

        $setResult = $cmdletInput | Set-HPEBIOSPCIDeviceConfiguration -Connection $ListOfConnection -EnablePCIDevice
    }
    elseif($DisablePCIDevice){

        $setResult = $cmdletInput | Set-HPEBIOSPCIDeviceConfiguration -Connection $ListOfConnection -DisablePCIDevice
    }
    else
    {
        $setResult = Set-HPEBIOSPCIDeviceConfiguration -Connection $ListOfConnection
    }
    
        if($setResult -ne $null -and ($setResult.Status -eq "Error"))
        {
            Write-Host ""
            Write-Host "PCI device configuration cannot be changed"
            Write-Host "Server : $($setResult.IP)"
            Write-Host "Error : $($setResult.StatusInfo)"
		    Write-Host "StatusInfo.Category : $($setResult.StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($setResult.StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($setResult.StatusInfo.AffectedAttribute)"
            $failureCount++
        }
}


if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "PCI device configuration successfully changed" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $getResult = $serverConnection | Get-HPEBIOSPCIDeviceConfiguration
        Write-Host "-------------------Server $($getResult.IP)-------------------" -ForegroundColor Yellow
        Write-Host ""
        $getResult.PCIDevice
        $counter ++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit

# SIG # Begin signature block
# MIIjtQYJKoZIhvcNAQcCoIIjpjCCI6ICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAif0WpVyklv6Jz
# mNwlj4Tb6WFcLToVTkF1sCKsG0Pqe6CCHsIwggPuMIIDV6ADAgECAhB+k+v7fMZO
# WepLmnfUBvw7MA0GCSqGSIb3DQEBBQUAMIGLMQswCQYDVQQGEwJaQTEVMBMGA1UE
# CBMMV2VzdGVybiBDYXBlMRQwEgYDVQQHEwtEdXJiYW52aWxsZTEPMA0GA1UEChMG
# VGhhd3RlMR0wGwYDVQQLExRUaGF3dGUgQ2VydGlmaWNhdGlvbjEfMB0GA1UEAxMW
# VGhhd3RlIFRpbWVzdGFtcGluZyBDQTAeFw0xMjEyMjEwMDAwMDBaFw0yMDEyMzAy
# MzU5NTlaMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsayzSVRLlxwS
# CtgleZEiVypv3LgmxENza8K/LlBa+xTCdo5DASVDtKHiRfTot3vDdMwi17SUAAL3
# Te2/tLdEJGvNX0U70UTOQxJzF4KLabQry5kerHIbJk1xH7Ex3ftRYQJTpqr1SSwF
# eEWlL4nO55nn/oziVz89xpLcSvh7M+R5CvvwdYhBnP/FA1GZqtdsn5Nph2Upg4XC
# YBTEyMk7FNrAgfAfDXTekiKryvf7dHwn5vdKG3+nw54trorqpuaqJxZ9YfeYcRG8
# 4lChS+Vd+uUOpyyfqmUg09iW6Mh8pU5IRP8Z4kQHkgvXaISAXWp4ZEXNYEZ+VMET
# fMV58cnBcQIDAQABo4H6MIH3MB0GA1UdDgQWBBRfmvVuXMzMdJrU3X3vP9vsTIAu
# 3TAyBggrBgEFBQcBAQQmMCQwIgYIKwYBBQUHMAGGFmh0dHA6Ly9vY3NwLnRoYXd0
# ZS5jb20wEgYDVR0TAQH/BAgwBgEB/wIBADA/BgNVHR8EODA2MDSgMqAwhi5odHRw
# Oi8vY3JsLnRoYXd0ZS5jb20vVGhhd3RlVGltZXN0YW1waW5nQ0EuY3JsMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIBBjAoBgNVHREEITAfpB0wGzEZ
# MBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMTANBgkqhkiG9w0BAQUFAAOBgQADCZuP
# ee9/WTCq72i1+uMJHbtPggZdN1+mUp8WjeockglEbvVt61h8MOj5aY0jcwsSb0ep
# rjkR+Cqxm7Aaw47rWZYArc4MTbLQMaYIXCp6/OJ6HVdMqGUY6XlAYiWWbsfHN2qD
# IQiOQerd2Vc/HXdJhyoWBl6mOGoiEqNRGYN+tjCCBKMwggOLoAMCAQICEA7P9DjI
# /r81bgTYapgbGlAwDQYJKoZIhvcNAQEFBQAwXjELMAkGA1UEBhMCVVMxHTAbBgNV
# BAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1hbnRlYyBUaW1l
# IFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzIwHhcNMTIxMDE4MDAwMDAwWhcNMjAx
# MjI5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29y
# cG9yYXRpb24xNDAyBgNVBAMTK1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vydmlj
# ZXMgU2lnbmVyIC0gRzQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCi
# Yws5RLi7I6dESbsO/6HwYQpTk7CY260sD0rFbv+GPFNVDxXOBD8r/amWltm+YXkL
# W8lMhnbl4ENLIpXuwitDwZ/YaLSOQE/uhTi5EcUj8mRY8BUyb05Xoa6IpALXKh7N
# S+HdY9UXiTJbsF6ZWqidKFAOF+6W22E7RVEdzxJWC5JH/Kuu9mY9R6xwcueS51/N
# ELnEg2SUGb0lgOHo0iKl0LoCeqF3k1tlw+4XdLxBhircCEyMkoyRLZ53RB9o1qh0
# d9sOWzKLVoszvdljyEmdOsXF6jML0vGjG/SLvtmzV4s73gSneiKyJK4ux3DFvk6D
# Jgj7C72pT5kI4RAocqrNAgMBAAGjggFXMIIBUzAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBzBggrBgEFBQcBAQRn
# MGUwKgYIKwYBBQUHMAGGHmh0dHA6Ly90cy1vY3NwLndzLnN5bWFudGVjLmNvbTA3
# BggrBgEFBQcwAoYraHR0cDovL3RzLWFpYS53cy5zeW1hbnRlYy5jb20vdHNzLWNh
# LWcyLmNlcjA8BgNVHR8ENTAzMDGgL6AthitodHRwOi8vdHMtY3JsLndzLnN5bWFu
# dGVjLmNvbS90c3MtY2EtZzIuY3JsMCgGA1UdEQQhMB+kHTAbMRkwFwYDVQQDExBU
# aW1lU3RhbXAtMjA0OC0yMB0GA1UdDgQWBBRGxmmjDkoUHtVM2lJjFz9eNrwN5jAf
# BgNVHSMEGDAWgBRfmvVuXMzMdJrU3X3vP9vsTIAu3TANBgkqhkiG9w0BAQUFAAOC
# AQEAeDu0kSoATPCPYjA3eKOEJwdvGLLeJdyg1JQDqoZOJZ+aQAMc3c7jecshaAba
# tjK0bb/0LCZjM+RJZG0N5sNnDvcFpDVsfIkWxumy37Lp3SDGcQ/NlXTctlzevTcf
# Q3jmeLXNKAQgo6rxS8SIKZEOgNER/N1cdm5PXg5FRkFuDbDqOJqxOtoJcRD8HHm0
# gHusafT9nLYMFivxf1sJPZtb4hbKE4FtAC44DagpjyzhsvRaqQGvFZwsL0kb2yK7
# w/54lFHDhrGCiF3wPbRRoXkzKy57udwgCRNx62oZW8/opTBXLIlJP7nPf8m/PiJo
# Y1OavWl0rMUdPH+S4MO8HNgEdTCCBUwwggM0oAMCAQICEzMAAAA12NVZWwZxQSsA
# AAAAADUwDQYJKoZIhvcNAQEFBQAwfzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEpMCcGA1UEAxMgTWljcm9zb2Z0IENvZGUgVmVyaWZpY2F0aW9u
# IFJvb3QwHhcNMTMwODE1MjAyNjMwWhcNMjMwODE1MjAzNjMwWjBvMQswCQYDVQQG
# EwJTRTEUMBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAkBgNVBAsTHUFkZFRydXN0IEV4
# dGVybmFsIFRUUCBOZXR3b3JrMSIwIAYDVQQDExlBZGRUcnVzdCBFeHRlcm5hbCBD
# QSBSb290MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt/caM+byAAQt
# OeBOW+0fvGwPzbX6I7bO3psRM5ekKUx9k5+9SryT7QMa44/P5W1QWtaXKZRagLBJ
# etsulf24yr83OC0ePpFBrXBWx/BPP+gynnTKyJBU6cZfD3idmkA8Dqxhql4Uj56H
# oWpQ3NeaTq8Fs6ZxlJxxs1BgCscTnTgHhgKo6ahpJhiQq0ywTyOrOk+E2N/On+Fp
# b7vXQtdrROTHre5tQV9yWnEIN7N5ZaRZoJQ39wAvDcKSctrQOHLbFKhFxF0qfbe0
# 1sTurM0TRLfJK91DACX6YblpalgjEbenM49WdVn1zSnXRrcKK2W200JvFbK4e/vv
# 6V1T1TRaJwIDAQABo4HQMIHNMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBIGA1UdEwEB
# /wQIMAYBAf8CAQIwHQYDVR0OBBYEFK29mHo0tCb3+sQmVO8DveAky1QaMAsGA1Ud
# DwQEAwIBhjAfBgNVHSMEGDAWgBRi+wohW39DbhHaCVRQa/XSlnHxnjBVBgNVHR8E
# TjBMMEqgSKBGhkRodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9k
# dWN0cy9NaWNyb3NvZnRDb2RlVmVyaWZSb290LmNybDANBgkqhkiG9w0BAQUFAAOC
# AgEANiui8uEzH+ST9/JphcZkDsmbYy/kcDeY/ZTse8/4oUJG+e1qTo00aTYFVXoe
# u62MmUKWBuklqCaEvsG/Fql8qlsEt/3RwPQCvijt9XfHm/469ujBe9OCq/oUTs8r
# z+XVtUhAsaOPg4utKyVTq6Y0zvJD908s6d0eTlq2uug7EJkkALxQ/Xj25SOoiZST
# 97dBMDdKV7fmRNnJ35kFqkT8dK+CZMwHywG2CcMu4+gyp7SfQXjHoYQ2VGLy7BUK
# yOrQhPjx4Gv0VhJfleD83bd2k/4pSiXpBADxtBEOyYSe2xd99R6ljjYpGTptbEZL
# 16twJCiNBaPZ1STy+KDRPII51KiCDmk6gQn8BvDHWTOENpMGQZEjLCKlpwErULQo
# rttGsFkbhrObh+hJTjkLbRTfTAMwHh9fdK71W1kDU+yYFuDQYjV1G0i4fRPleki4
# d1KkB5glOwabek5qb0SGTxRPJ3knPVBzQUycQT7dKQxzscf7H3YMF2UE69JQEJJB
# SezkBn02FURvib9pfflNQME6mLagfjHSta7K+1PVP1CGzV6TO21dfJo/P/epJViE
# 3RFJAKLHyJ433XeObXGL4FuBNF1Uusz1k0eIbefvW+Io5IAbQOQPKtF/IxVlWqyZ
# lEM/RlUm1sT6iJXikZqjLQuF3qyM4PlncJ9xeQIx92GiKcQwggVhMIIESaADAgEC
# AhAqT4Pyvdhuo5d93/tcx5MDMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAkdC
# MRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQx
# GDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEkMCIGA1UEAxMbU2VjdGlnbyBSU0Eg
# Q29kZSBTaWduaW5nIENBMB4XDTE5MDMyMDAwMDAwMFoXDTIwMDMxOTIzNTk1OVow
# gdIxCzAJBgNVBAYTAlVTMQ4wDAYDVQQRDAU5NDMwNDELMAkGA1UECAwCQ0ExEjAQ
# BgNVBAcMCVBhbG8gQWx0bzEcMBoGA1UECQwTMzAwMCBIYW5vdmVyIFN0cmVldDEr
# MCkGA1UECgwiSGV3bGV0dCBQYWNrYXJkIEVudGVycHJpc2UgQ29tcGFueTEaMBgG
# A1UECwwRSFAgQ3liZXIgU2VjdXJpdHkxKzApBgNVBAMMIkhld2xldHQgUGFja2Fy
# ZCBFbnRlcnByaXNlIENvbXBhbnkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDn3NkEtHc2vZmifE+fkbv0Te0rbApjdvvfhWPS81WRyenb2r6sKGESIuzU
# 9ARHtyeM1SJ+eH40epB5E5BwLHwGJkmxOq932AWzGMVpkgmGcdt0z5k3w5o1cE1g
# PQbBLhuqosgiPXg1uarX0wa9Zz4kXUOc/zeGlT36XP6+DFEweCfkH3pkQL7cV+MT
# b4P0VLEHreYIanmmgUEF4ShVRC7kGWFCaxSUB0FgeUZkFNRbcAj37PlGmWUUfUKh
# tZCMRzmgWAdBi6zJxsa5DyWVqjUudW6oDcx7lEz17o66xSqjzFsY6zULTAbuRxS4
# RlzQW82ousMPEtdnguMNjJa/MjSNAgMBAAGjggGGMIIBgjAfBgNVHSMEGDAWgBQO
# 4TqoUzox1Yq+wbutZxoDha00DjAdBgNVHQ4EFgQURYzDFvRBGf9VAOi47qj/TNPi
# rngwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMEAGA1UdIAQ5MDcwNQYMKwYBBAGyMQEC
# AQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMEMGA1Ud
# HwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1JTQUNv
# ZGVTaWduaW5nQ0EuY3JsMHMGCCsGAQUFBwEBBGcwZTA+BggrBgEFBQcwAoYyaHR0
# cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNBQ29kZVNpZ25pbmdDQS5jcnQw
# IwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMA0GCSqGSIb3DQEB
# CwUAA4IBAQBSyWs6upTbe3D8lo7wR9SiLvFoKvfe8wMNVoGwiJW2oLF9Ee/e5biJ
# 6rJBDiyDYKuUtp4gX1cKYX6nENBx/wN+RocfR5iQGmZAPGKNqQZ/7un9Onw5lK67
# y1ps4R6rNLMTRuZcXbyRwwPw2Xj46QICrot/v5d2GqDUhgYZt5W3hSTiLK9OitVr
# KJol/yUaG8NyZBM307pnWBYfR0LuMQ24WQFCY5ztDuQvTJcRO3hEhSmOyJ+AsIBB
# lj97QUqSmlnmGrmG1DcWP60mRZH5U/0zkTZ4mj1qlPHpsMkhfkAoR+pu6jVGIDci
# xDVQ3DErjyMuIE7W4vfSmLzHX/c52Wd/MIIFdzCCBF+gAwIBAgIQE+oocFv07O0M
# NmMJgGFDNjANBgkqhkiG9w0BAQwFADBvMQswCQYDVQQGEwJTRTEUMBIGA1UEChML
# QWRkVHJ1c3QgQUIxJjAkBgNVBAsTHUFkZFRydXN0IEV4dGVybmFsIFRUUCBOZXR3
# b3JrMSIwIAYDVQQDExlBZGRUcnVzdCBFeHRlcm5hbCBDQSBSb290MB4XDTAwMDUz
# MDEwNDgzOFoXDTIwMDUzMDEwNDgzOFowgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhl
# IFVTRVJUUlVTVCBOZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNBIENlcnRp
# ZmljYXRpb24gQXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
# AgEAgBJlFzYOw9sIs9CsVw127c0n00ytUINh4qogTQktZAnczomfzD2p7PbPwdzx
# 07HWezcoEStH2jnGvDoZtF+mvX2do2NCtnbyqTsrkfjib9DsFiCQCT7i6HTJGLSR
# 1GJk23+jBvGIGGqQIjy8/hPwhxR79uQfjtTkUcYRZ0YIUcuGFFQ/vDP+fmyc/xad
# GL1RjjWmp2bIcmfbIWax1Jt4A8BQOujM8Ny8nkz+rwWWNR9XWrf/zvk9tyy29lTd
# yOcSOk2uTIq3XJq0tyA9yn8iNK5+O2hmAUTnAU5GU5szYPeUvlM3kHND8zLDU+/b
# qv50TmnHa4xgk97Exwzf4TKuzJM7UXiVZ4vuPVb+DNBpDxsP8yUmazNt925H+nND
# 5X4OpWaxKXwyhGNVicQNwZNUMBkTrNN9N6frXTpsNVzbQdcS2qlJC9/YgIoJk2KO
# tWbPJYjNhLixP6Q5D9kCnusSTJV882sFqV4Wg8y4Z+LoE53MW4LTTLPtW//e5XOs
# IzstAL81VXQJSdhJWBp/kjbmUZIO8yZ9HE0XvMnsQybQv0FfQKlERPSZ51eHnlAf
# V1SoPv10Yy+xUGUJ5lhCLkMaTLTwJUdZ+gQek9QmRkpQgbLevni3/GcV4clXhB4P
# Y9bpYrrWX1Uu6lzGKAgEJTm4Diup8kyXHAc/DVL17e8vgg8CAwEAAaOB9DCB8TAf
# BgNVHSMEGDAWgBStvZh6NLQm9/rEJlTvA73gJMtUGjAdBgNVHQ4EFgQUU3m/Wqor
# Ss9UgOHYm8Cd8rIDZsswDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8w
# EQYDVR0gBAowCDAGBgRVHSAAMEQGA1UdHwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwu
# dXNlcnRydXN0LmNvbS9BZGRUcnVzdEV4dGVybmFsQ0FSb290LmNybDA1BggrBgEF
# BQcBAQQpMCcwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20w
# DQYJKoZIhvcNAQEMBQADggEBAJNl9jeDlQ9ew4IcH9Z35zyKwKoJ8OkLJvHgwmp1
# ocd5yblSYMgpEg7wrQPWCcR23+WmgZWnRtqCV6mVksW2jwMibDN3wXsyF24HzloU
# QToFJBv2FAY7qCUkDrvMKnXduXBBP3zQYzYhBx9G/2CkkeFnvN4ffhkUyWNnkepn
# B2u0j4vAbkN9w6GAbLIevFOFfdyQoaS8Le9Gclc1Bb+7RrtubTeZtv8jkpHGbkD4
# jylW6l/VXxRTrPBPYer3IsynVgviuDQfJtl7GQVoP7o81DgGotPmjw7jtHFtQELF
# hLRAlSv0ZaBIefYdgWOWnU914Ph85I6p0fKtirOMxyHNwu8wggX1MIID3aADAgEC
# AhAdokgwb5smGNCC4JZ9M9NqMA0GCSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAc
# BgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0
# IFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xODExMDIwMDAwMDBaFw0z
# MDEyMzEyMzU5NTlaMHwxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1h
# bmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGlt
# aXRlZDEkMCIGA1UEAxMbU2VjdGlnbyBSU0EgQ29kZSBTaWduaW5nIENBMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhiKNMoV6GJ9J8JYvYwgeLdx8nxTP
# 4ya2JWYpQIZURnQxYsUQ7bKHJ6aZy5UwwFb1pHXGqQ5QYqVRkRBq4Etirv3w+Bis
# p//uLjMg+gwZiahse60Aw2Gh3GllbR9uJ5bXl1GGpvQn5Xxqi5UeW2DVftcWkpwA
# L2j3l+1qcr44O2Pej79uTEFdEiAIWeg5zY/S1s8GtFcFtk6hPldrH5i8xGLWGwuN
# x2YbSp+dgcRyQLXiX+8LRf+jzhemLVWwt7C8VGqdvI1WU8bwunlQSSz3A7n+L2U1
# 8iLqLAevRtn5RhzcjHxxKPP+p8YU3VWRbooRDd8GJJV9D6ehfDrahjVh0wIDAQAB
# o4IBZDCCAWAwHwYDVR0jBBgwFoAUU3m/WqorSs9UgOHYm8Cd8rIDZsswHQYDVR0O
# BBYEFA7hOqhTOjHVir7Bu61nGgOFrTQOMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdJQQWMBQGCCsGAQUFBwMDBggrBgEFBQcDCDARBgNV
# HSAECjAIMAYGBFUdIAAwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC51c2Vy
# dHJ1c3QuY29tL1VTRVJUcnVzdFJTQUNlcnRpZmljYXRpb25BdXRob3JpdHkuY3Js
# MHYGCCsGAQUFBwEBBGowaDA/BggrBgEFBQcwAoYzaHR0cDovL2NydC51c2VydHJ1
# c3QuY29tL1VTRVJUcnVzdFJTQUFkZFRydXN0Q0EuY3J0MCUGCCsGAQUFBzABhhlo
# dHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBDAUAA4ICAQBNY1Dt
# RzRKYaTb3moqjJvxAAAeHWJ7Otcywvaz4GOz+2EAiJobbRAHBE++uOqJeCLrD0bs
# 80ZeQEaJEvQLd1qcKkE6/Nb06+f3FZUzw6GDKLfeL+SU94Uzgy1KQEi/msJPSrGP
# JPSzgTfTt2SwpiNqWWhSQl//BOvhdGV5CPWpk95rcUCZlrp48bnI4sMIFrGrY1rI
# FYBtdF5KdX6luMNstc/fSnmHXMdATWM19jDTz7UKDgsEf6BLrrujpdCEAJM+U100
# pQA1aWy+nyAlEA0Z+1CQYb45j3qOTfafDh7+B1ESZoMmGUiVzkrJwX/zOgWb+W/f
# iH/AI57SHkN6RTHBnE2p8FmyWRnoao0pBAJ3fEtLzXC+OrJVWng+vLtvAxAldxU0
# ivk2zEOS5LpP8WKTKCVXKftRGcehJUBqhFfGsp2xvBwK2nxnfn0u6ShMGH7EezFB
# cZpLKewLPVdQ0srd/Z4FUeVEeN0B3rF1mA1UJP3wTuPi+IO9crrLPTru8F4Xkmht
# yGH5pvEqCgulufSe7pgyBYWe6/mDKdPGLH29OncuizdCoGqC7TtKqpQQpOEN+BfF
# tlp5MxiS47V1+KHpjgolHuQe8Z9ahyP/n6RRnvs5gBHN27XEp6iAb+VT1ODjosLS
# Wxr6MiYtaldwHDykWC6j81tLB9wyWfOHpxptWDGCBEkwggRFAgEBMIGQMHwxCzAJ
# BgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcT
# B1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEkMCIGA1UEAxMbU2Vj
# dGlnbyBSU0EgQ29kZSBTaWduaW5nIENBAhAqT4Pyvdhuo5d93/tcx5MDMA0GCWCG
# SAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisG
# AQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcN
# AQkEMSIEIKu50+ydkvwPEau1E0II5N4wZFznzXJpslco18HtiuHfMA0GCSqGSIb3
# DQEBAQUABIIBALGy4apy3CubUwft40OMjkSGKFN6N+5Nr1e4ANotQPwYvFqg1CB2
# bZlePP+X0W9HajA83R/stpEIEx7toeGuAaO6aJioSV4gd8w9iAckTP/wurYD/maG
# /+hpLqtnBwGTeLkapxfse0AryitbMP1mOdq9FCIGXEVSFs4ZMIBccZQ3tjvBFxKW
# dz8zeDMhY2bjCCzERuvotouDk0tlfo79PevM/Typd7HUgfjN6HqNuo4LyoWW7anb
# WOaHYG15t3L15FUgUTlY/IXSb/JCgxec/m7Fe2ONxrGDH6+x3tKCb/rsLqounYpv
# HgL3Gaa57HuCksgXLUO/uUEXYuKcTNp6po+hggILMIICBwYJKoZIhvcNAQkGMYIB
# +DCCAfQCAQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29y
# cG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vydmlj
# ZXMgQ0EgLSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZI
# hvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkwNDIzMDYxMzAy
# WjAjBgkqhkiG9w0BCQQxFgQUd2Xsy2Em8v0BtFZL5i9lNU4+MHswDQYJKoZIhvcN
# AQEBBQAEggEAepvvAhKpXJmcAKj1tsQgIzMhOpff1eDO4UUDF6qzF5iZ4myxd/bL
# 2TKvy6CWkHashuQywKXz3GOOCZwqLxNOI7ReA+DdnRMNOVAtJDuc4pyqw+xIhaYl
# J7KhReiySA2h5wHxpv6x9qKZmWQhCPcoXY/LOQNNKENrVcX5+a4N4Tl9J1Hl9E0F
# Bm5hwpEfmNDVNGEcveHhgXOL51hTxjigpwp5T2/MCOjJDojq7GFBT7h5l1mGvLFG
# aIlAS8gtTZrOUAHUGVXGH4Uk6062iBB8tiSILY4gujL9NObkIIqjFTWisIpTJNwD
# 17i9Sf2Db4GmOjm031GoXlgZri6IZD9NWw==
# SIG # End signature block
