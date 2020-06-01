##############################################################
#Configuring Workload profile
##########################################################----#

<#
.Synopsis
    This Script allows user to configure work load profile for HPE Proliant Gen10 servers

.DESCRIPTION
    This script allows user to configure work load profile.Following features can be configured.
    WorkloadProfile

.EXAMPLE
    ConfigureWorkloadProfileForGen10.ps1

    This mode of execution of script will prompt for 
    
    -Address    :- Accept IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    -Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    -WorkloadProfile   :- Accepted values are GeneralPowerEfficientCompute, GeneralPeakFrequencyCompute, GeneralThroughputCompute, VirtualizationPowerEfficient, VirtualizationMaximumPerformance, LowLatency, MissionCritical, TransactionalApplicationProcessing, HighPerformanceCompute, DecisionSupport, GraphicProcessing, IOThroughput, WebE-Commerce, ExtremeEfficientCompute, and Custom.
   

.EXAMPLE
    ConfigureWorkloadProfileForGen10.ps1 -Address "10.20.30.40" -Credential $userCredential -WorkloadProfile Custom

    This mode of script have input parameter for Address, Credential, ThermalConfiguration, FanFailurePolicy and FanInstallationRequirement.
    
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to specify user Credential.In the case of multiple servers use same credential for all the servers
    
    -WorkloadProfile :- Use this Parameter to specify Workload profile.
    

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 11/04/2020
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    WorkloadProfile

.OUTPUTS
    None (by default)

.LINK
    
   http://www.hpe.com/servers/powershell
   https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    [string[]]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # In the case of multiple servers it use same credential for all the servers
    [String[]]$WorkloadProfile
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

Write-Host "This script allows user to configure Workload profile.Following features can be configured."
Write-Host "Workload Profile"
Write-Host ""

#dont show error in scrip

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

if($Address.Count -eq 0)
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}
    
[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)"
    Write-Host ""
    Write-Host "Exit ..."
    exit
}

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password(Use same credential for multiple servers)"
    Write-Host ""
}

#Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

#Create connection object
[array]$ListOfConnection = @()
$connection = $null
[int] $connectionCount = 0

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
            Write-Host "WorkloadProfile  is not supported on Server $($connection.IP)"
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
    Write-Host "Exit"
    Write-Host ""
    exit
}

# Get current WorkloadProfile

Write-Host ""
Write-Host "Current workload profile" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
        $result = $serverConnection | Get-HPEBIOSWorkloadProfile
        
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $result
        $CurrentWorkloadProfile += $result
        $counter++
}

# Get the valid value list fro each parameter
$workloadProfileParameterMetaData = $(Get-Command -Name Set-HPEBIOSWorkloadProfile).Parameters
$workloadProfileValidValues = $($workloadProfileParameterMetaData["WorkloadProfile"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues


#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

if($WorkloadProfile.Count -eq 0)
{
    $tempWorkloadProfile = Read-Host "Enter Workload profile [Accepted values : ($($workloadProfileValidValues -join ","))]"
    Write-Host ""
    $WorkloadProfile = $tempWorkloadProfile.Trim().Split(',')

}

if($WorkloadProfile.Count -eq 0)
{
    Write-Host "You have not entered value for parameters"
    Write-Host "Exit....."
    exit
}

for($i = 0 ; $i -lt $WorkloadProfile.Count ;$i++)
{
    
    #validate user input workload profile
    if($($workloadProfileValidValues | where{$_ -eq $WorkloadProfile[$i] }) -eq $null)
    {
        Write-Host "Invalid value for workload profile" -ForegroundColor Red
        Write-Host "Exit...."
        exit
    }
}

Write-Host "Changing workload profile ....." -ForegroundColor Green  
$failureCount = 0

if($ListOfConnection.Count -ne 0)
{
    $setResult = Set-HPEBIOSWorkloadProfile -Connection $ListOfConnection -WorkloadProfile $WorkloadProfile
    
    for($i =0; $i -lt $ListOfConnection.Count ; $i++)
    {        
        if(($setResult[$i].Status -eq "Error"))
        {
            Write-Host ""
            Write-Host "Workload profile cannot be changed"
            Write-Host "Server : $($setResult[$i].IP)"
            Write-Host "Error : $($setResult[$i].StatusInfo)"
		    Write-Host "StatusInfo.Category : $($setResult[$i].StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($setResult[$i].StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($setResult[$i].StatusInfo.AffectedAttribute)"
            $failureCount++
        }
    }
}


if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "Workload profile successfully changed" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $workloadProfileResult = $serverConnection | Get-HPEBIOSWorkloadProfile
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $workloadProfileResult
        $counter ++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit

# SIG # Begin signature block
# MIIkXwYJKoZIhvcNAQcCoIIkUDCCJEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD+10XWe6+Hq9MU
# A78I3kU0KBNAjF29tFtKjgwoo0/8xaCCH04wggSEMIIDbKADAgECAhBCGvKUCYQZ
# H1IKS8YkJqdLMA0GCSqGSIb3DQEBBQUAMG8xCzAJBgNVBAYTAlNFMRQwEgYDVQQK
# EwtBZGRUcnVzdCBBQjEmMCQGA1UECxMdQWRkVHJ1c3QgRXh0ZXJuYWwgVFRQIE5l
# dHdvcmsxIjAgBgNVBAMTGUFkZFRydXN0IEV4dGVybmFsIENBIFJvb3QwHhcNMDUw
# NjA3MDgwOTEwWhcNMjAwNTMwMTA0ODM4WjCBlTELMAkGA1UEBhMCVVMxCzAJBgNV
# BAgTAlVUMRcwFQYDVQQHEw5TYWx0IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVT
# RVJUUlVTVCBOZXR3b3JrMSEwHwYDVQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5j
# b20xHTAbBgNVBAMTFFVUTi1VU0VSRmlyc3QtT2JqZWN0MIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAzqqBP6OjYXiqMQBVlRGeJw8fHN86m4JoMMBKYR3x
# Lw76vnn3pSPvVVGWhM3b47luPjHYCiBnx/TZv5TrRwQ+As4qol2HBAn2MJ0Yipey
# qhz8QdKhNsv7PZG659lwNfrk55DDm6Ob0zz1Epl3sbcJ4GjmHLjzlGOIamr+C3bJ
# vvQi5Ge5qxped8GFB90NbL/uBsd3akGepw/X++6UF7f8hb6kq8QcMd3XttHk8O/f
# Fo+yUpPXodSJoQcuv+EBEkIeGuHYlTTbZHko/7ouEcLl6FuSSPtHC8Js2q0yg0Hz
# peVBcP1lkG36+lHE+b2WKxkELNNtp9zwf2+DZeJqq4eGdQIDAQABo4H0MIHxMB8G
# A1UdIwQYMBaAFK29mHo0tCb3+sQmVO8DveAky1QaMB0GA1UdDgQWBBTa7WR0FJwU
# PKvdmam9WyhNizzJ2DAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAR
# BgNVHSAECjAIMAYGBFUdIAAwRAYDVR0fBD0wOzA5oDegNYYzaHR0cDovL2NybC51
# c2VydHJ1c3QuY29tL0FkZFRydXN0RXh0ZXJuYWxDQVJvb3QuY3JsMDUGCCsGAQUF
# BwEBBCkwJzAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AudXNlcnRydXN0LmNvbTAN
# BgkqhkiG9w0BAQUFAAOCAQEATUIvpsGK6weAkFhGjPgZOWYqPFosbc/U2YdVjXkL
# Eoh7QI/Vx/hLjVUWY623V9w7K73TwU8eA4dLRJvj4kBFJvMmSStqhPFUetRC2vzT
# artmfsqe6um73AfHw5JOgzyBSZ+S1TIJ6kkuoRFxmjbSxU5otssOGyUWr2zeXXbY
# H3KxkyaGF9sY3q9F6d/7mK8UGO2kXvaJlEXwVQRK3f8n3QZKQPa0vPHkD5kCu/1d
# Di4owb47Xxo/lxCEvBY+2KOcYx1my1xf2j7zDwoJNSLb28A/APnmDV1n0f2gHgMr
# 2UD3vsyHZlSApqO49Rli1dImsZgm7prLRKdFWoGVFRr1UTCCBOYwggPOoAMCAQIC
# EGJcTZCM1UL7qy6lcz/xVBkwDQYJKoZIhvcNAQEFBQAwgZUxCzAJBgNVBAYTAlVT
# MQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtlIENpdHkxHjAcBgNVBAoT
# FVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMYaHR0cDovL3d3dy51c2Vy
# dHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNFUkZpcnN0LU9iamVjdDAeFw0xMTA0
# MjcwMDAwMDBaFw0yMDA1MzAxMDQ4MzhaMHoxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# ExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGjAYBgNVBAoT
# EUNPTU9ETyBDQSBMaW1pdGVkMSAwHgYDVQQDExdDT01PRE8gVGltZSBTdGFtcGlu
# ZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKqC8YSpW9hxtdJd
# K+30EyAM+Zvp0Y90Xm7u6ylI2Mi+LOsKYWDMvZKNfN10uwqeaE6qdSRzJ6438xqC
# pW24yAlGTH6hg+niA2CkIRAnQJpZ4W2vPoKvIWlZbWPMzrH2Fpp5g5c6HQyvyX3R
# TtjDRqGlmKpgzlXUEhHzOwtsxoi6lS7voEZFOXys6eOt6FeXX/77wgmN/o6apT9Z
# RvzHLV2Eh/BvWCbD8EL8Vd5lvmc4Y7MRsaEl7ambvkjfTHfAqhkLtv1Kjyx5VbH+
# WVpabVWLHEP2sVVyKYlNQD++f0kBXTybXAj7yuJ1FQWTnQhi/7oN26r4tb8QMspy
# 6ggmzRkCAwEAAaOCAUowggFGMB8GA1UdIwQYMBaAFNrtZHQUnBQ8q92Zqb1bKE2L
# PMnYMB0GA1UdDgQWBBRkIoa2SonJBA/QBFiSK7NuPR4nbDAOBgNVHQ8BAf8EBAMC
# AQYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEFBQcDCDARBgNV
# HSAECjAIMAYGBFUdIAAwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2NybC51c2Vy
# dHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0LmNybDB0BggrBgEFBQcBAQRo
# MGYwPQYIKwYBBQUHMAKGMWh0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9VVE5BZGRU
# cnVzdE9iamVjdF9DQS5jcnQwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0
# cnVzdC5jb20wDQYJKoZIhvcNAQEFBQADggEBABHJPeEF6DtlrMl0MQO32oM4xpK6
# /c3422ObfR6QpJjI2VhoNLXwCyFTnllG/WOF3/5HqnDkP14IlShfFPH9Iq5w5Lfx
# sLZWn7FnuGiDXqhg25g59txJXhOnkGdL427n6/BDx9Avff+WWqcD1ptUoCPTpcKg
# jvlP0bIGIf4hXSeMoK/ZsFLu/Mjtt5zxySY41qUy7UiXlF494D01tLDJWK/HWP9i
# dBaSZEHayqjriwO9wU6uH5EyuOEkO3vtFGgJhpYoyTvJbCjCJWn1SmGt4Cf4U6d1
# FbBRMbDxQf8+WiYeYH7i42o5msTq7j/mshM/VQMETQuQctTr+7yHkFGyOBkwggT+
# MIID5qADAgECAhArc9t0YxFMWlsySvIwV3JJMA0GCSqGSIb3DQEBBQUAMHoxCzAJ
# BgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcT
# B1NhbGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSAwHgYDVQQDExdD
# T01PRE8gVGltZSBTdGFtcGluZyBDQTAeFw0xOTA1MDIwMDAwMDBaFw0yMDA1MzAx
# MDQ4MzhaMIGDMQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVz
# dGVyMRAwDgYDVQQHDAdTYWxmb3JkMRgwFgYDVQQKDA9TZWN0aWdvIExpbWl0ZWQx
# KzApBgNVBAMMIlNlY3RpZ28gU0hBLTEgVGltZSBTdGFtcGluZyBTaWduZXIwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC/UjaCOtx0Nw141X8WUBlm7boa
# mdFjOJoMZrJA26eAUL9pLjYvCmc/QKFKimM1m9AZzHSqFxmRK7VVIBn7wBo6bco5
# m4LyupWhGtg0x7iJe3CIcFFmaex3/saUcnrPJYHtNIKa3wgVNzG0ba4cvxjVDc/+
# teHE+7FHcen67mOR7PHszlkEEXyuC2BT6irzvi8CD9BMXTETLx5pD4WbRZbCjRKL
# Z64fr2mrBpaBAN+RfJUc5p4ZZN92yGBEL0njj39gakU5E0Qhpbr7kfpBQO1NArRL
# f9/i4D24qvMa2EGDj38z7UEG4n2eP1OEjSja3XbGvfeOHjjNwMtgJAPeekyrAgMB
# AAGjggF0MIIBcDAfBgNVHSMEGDAWgBRkIoa2SonJBA/QBFiSK7NuPR4nbDAdBgNV
# HQ4EFgQUru7ZYLpe9SwBEv2OjbJVcjVGb/EwDgYDVR0PAQH/BAQDAgbAMAwGA1Ud
# EwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQAYDVR0gBDkwNzA1Bgwr
# BgEEAbIxAQIBAwgwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9D
# UFMwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2NybC5zZWN0aWdvLmNvbS9DT01P
# RE9UaW1lU3RhbXBpbmdDQV8yLmNybDByBggrBgEFBQcBAQRmMGQwPQYIKwYBBQUH
# MAKGMWh0dHA6Ly9jcnQuc2VjdGlnby5jb20vQ09NT0RPVGltZVN0YW1waW5nQ0Ff
# Mi5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMA0GCSqG
# SIb3DQEBBQUAA4IBAQB6f6lK0rCkHB0NnS1cxq5a3Y9FHfCeXJD2Xqxw/tPZzeQZ
# pApDdWBqg6TDmYQgMbrW/kzPE/gQ91QJfurc0i551wdMVLe1yZ2y8PIeJBTQnMfI
# Z6oLYre08Qbk5+QhSxkymTS5GWF3CjOQZ2zAiEqS9aFDAfOuom/Jlb2WOPeD9618
# KB/zON+OIchxaFMty66q4jAXgyIpGLXhjInrbvh+OLuQT7lfBzQSa5fV5juRvgAX
# IW7ibfxSee+BJbrPE9D73SvNgbZXiU7w3fMLSjTKhf8IuZZf6xET4OHFA61XHOFd
# kga+G8g8P6Ugn2nQacHFwsk+58Vy9+obluKUr4YuMIIFYjCCBEqgAwIBAgIRANR2
# kzqKoZX+RrdM/1yI/T8wDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCR0IxGzAZ
# BgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYG
# A1UEChMPU2VjdGlnbyBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdvIFJTQSBDb2Rl
# IFNpZ25pbmcgQ0EwHhcNMjAwMTI5MDAwMDAwWhcNMjEwMTI4MjM1OTU5WjCB0jEL
# MAkGA1UEBhMCVVMxDjAMBgNVBBEMBTk0MzA0MQswCQYDVQQIDAJDQTESMBAGA1UE
# BwwJUGFsbyBBbHRvMRwwGgYDVQQJDBMzMDAwIEhhbm92ZXIgU3RyZWV0MSswKQYD
# VQQKDCJIZXdsZXR0IFBhY2thcmQgRW50ZXJwcmlzZSBDb21wYW55MRowGAYDVQQL
# DBFIUCBDeWJlciBTZWN1cml0eTErMCkGA1UEAwwiSGV3bGV0dCBQYWNrYXJkIEVu
# dGVycHJpc2UgQ29tcGFueTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AL8epE5dUMGOUz2I7X4s8X56DzeaecMPHktm6YS8rZcHGCt/oGmed4ks5mtntjPW
# +b4+qYU8FGmOjW+92e5oaNu9GXv34QpjxD4tpRCUpI/ohkpaxRg58ThDOmCKrU/O
# teZBOwlFYEA8au5zgICRcQOwYCCT6/cLLIeYsd3JyS+lq2CJZhnvfs4HqMoavfL1
# PQ+DmnVH7l16UYV0Aat6HclxOwQAA0oVaxbTpnPM4AZZN4rr6QWl9jOL1RLnJCSv
# iEPJT94laOxm6RYyl53odyXJ8R8vnB2zdc5G49QZH8rLi18pbMFgfAVkGx2aVA+w
# pP12xML1pcJzAYNtaExvBT0CAwEAAaOCAYYwggGCMB8GA1UdIwQYMBaAFA7hOqhT
# OjHVir7Bu61nGgOFrTQOMB0GA1UdDgQWBBTRFDTpXovrGAcWDXCcM97sDQ9v9jAO
# BgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcD
# AzARBglghkgBhvhCAQEEBAMCBBAwQAYDVR0gBDkwNzA1BgwrBgEEAbIxAQIBAwIw
# JTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwQwYDVR0fBDww
# OjA4oDagNIYyaHR0cDovL2NybC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNBQ29kZVNp
# Z25pbmdDQS5jcmwwcwYIKwYBBQUHAQEEZzBlMD4GCCsGAQUFBzAChjJodHRwOi8v
# Y3J0LnNlY3RpZ28uY29tL1NlY3RpZ29SU0FDb2RlU2lnbmluZ0NBLmNydDAjBggr
# BgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQELBQAD
# ggEBAB1f93wVCCqZ7SPJTRJIh+G9WIP4BR23cIbSQVeC0wL4bZJ7s8j12L2wvn+0
# k770YeALaU0LVeGGA60/7uXcWVDnKEAVcWc3hd9gsCKvzd+x/elKzAwhL4/wWY6Q
# C66I15Q7FMIoGgvXIIHhLN6q+I1H30y9bv8EMq4tAUirkUhZL5FRZ88htPYNyaCc
# 9ytTA1jOzQ0GcKEyX65JBjA2m7aw/uHZ4mfZYHq8gTWCaEPV5sXvTG8ohlzTxpcI
# TEjBBf/JuGlVWlp+2p+fjbhYP3rYhFTHtZMBc1dfI+WCmHQEAEPzFbiXkV0po6wE
# T17JamN5tDi8ek3rIQTtQeydGO4wggV3MIIEX6ADAgECAhAT6ihwW/Ts7Qw2YwmA
# YUM2MA0GCSqGSIb3DQEBDAUAMG8xCzAJBgNVBAYTAlNFMRQwEgYDVQQKEwtBZGRU
# cnVzdCBBQjEmMCQGA1UECxMdQWRkVHJ1c3QgRXh0ZXJuYWwgVFRQIE5ldHdvcmsx
# IjAgBgNVBAMTGUFkZFRydXN0IEV4dGVybmFsIENBIFJvb3QwHhcNMDAwNTMwMTA0
# ODM4WhcNMjAwNTMwMTA0ODM4WjCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5l
# dyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNF
# UlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNh
# dGlvbiBBdXRob3JpdHkwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCA
# EmUXNg7D2wiz0KxXDXbtzSfTTK1Qg2HiqiBNCS1kCdzOiZ/MPans9s/B3PHTsdZ7
# NygRK0faOca8Ohm0X6a9fZ2jY0K2dvKpOyuR+OJv0OwWIJAJPuLodMkYtJHUYmTb
# f6MG8YgYapAiPLz+E/CHFHv25B+O1ORRxhFnRghRy4YUVD+8M/5+bJz/Fp0YvVGO
# NaanZshyZ9shZrHUm3gDwFA66Mzw3LyeTP6vBZY1H1dat//O+T23LLb2VN3I5xI6
# Ta5MirdcmrS3ID3KfyI0rn47aGYBROcBTkZTmzNg95S+UzeQc0PzMsNT79uq/nRO
# acdrjGCT3sTHDN/hMq7MkztReJVni+49Vv4M0GkPGw/zJSZrM233bkf6c0Plfg6l
# ZrEpfDKEY1WJxA3Bk1QwGROs0303p+tdOmw1XNtB1xLaqUkL39iAigmTYo61Zs8l
# iM2EuLE/pDkP2QKe6xJMlXzzawWpXhaDzLhn4ugTncxbgtNMs+1b/97lc6wjOy0A
# vzVVdAlJ2ElYGn+SNuZRkg7zJn0cTRe8yexDJtC/QV9AqURE9JnnV4eeUB9XVKg+
# /XRjL7FQZQnmWEIuQxpMtPAlR1n6BB6T1CZGSlCBst6+eLf8ZxXhyVeEHg9j1uli
# utZfVS7qXMYoCAQlObgOK6nyTJccBz8NUvXt7y+CDwIDAQABo4H0MIHxMB8GA1Ud
# IwQYMBaAFK29mHo0tCb3+sQmVO8DveAky1QaMB0GA1UdDgQWBBRTeb9aqitKz1SA
# 4dibwJ3ysgNmyzAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zARBgNV
# HSAECjAIMAYGBFUdIAAwRAYDVR0fBD0wOzA5oDegNYYzaHR0cDovL2NybC51c2Vy
# dHJ1c3QuY29tL0FkZFRydXN0RXh0ZXJuYWxDQVJvb3QuY3JsMDUGCCsGAQUFBwEB
# BCkwJzAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkq
# hkiG9w0BAQwFAAOCAQEAk2X2N4OVD17Dghwf1nfnPIrAqgnw6Qsm8eDCanWhx3nJ
# uVJgyCkSDvCtA9YJxHbf5aaBladG2oJXqZWSxbaPAyJsM3fBezIXbgfOWhRBOgUk
# G/YUBjuoJSQOu8wqdd25cEE/fNBjNiEHH0b/YKSR4We83h9+GRTJY2eR6mcHa7SP
# i8BuQ33DoYBssh68U4V93JChpLwt70ZyVzUFv7tGu25tN5m2/yOSkcZuQPiPKVbq
# X9VfFFOs8E9h6vcizKdWC+K4NB8m2XsZBWg/ujzUOAai0+aPDuO0cW1AQsWEtECV
# K/RloEh59h2BY5adT3Xg+HzkjqnR8q2Ks4zHIc3C7zCCBfUwggPdoAMCAQICEB2i
# SDBvmyYY0ILgln0z02owDQYJKoZIhvcNAQEMBQAwgYgxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UE
# ChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNB
# IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTE4MTEwMjAwMDAwMFoXDTMwMTIz
# MTIzNTk1OVowfDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hl
# c3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MSQwIgYDVQQDExtTZWN0aWdvIFJTQSBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCGIo0yhXoYn0nwli9jCB4t3HyfFM/jJrYl
# ZilAhlRGdDFixRDtsocnppnLlTDAVvWkdcapDlBipVGREGrgS2Ku/fD4GKyn/+4u
# MyD6DBmJqGx7rQDDYaHcaWVtH24nlteXUYam9CflfGqLlR5bYNV+1xaSnAAvaPeX
# 7Wpyvjg7Y96Pv25MQV0SIAhZ6DnNj9LWzwa0VwW2TqE+V2sfmLzEYtYbC43HZhtK
# n52BxHJAteJf7wtF/6POF6YtVbC3sLxUap28jVZTxvC6eVBJLPcDuf4vZTXyIuos
# B69G2flGHNyMfHEo8/6nxhTdVZFuihEN3wYklX0Pp6F8OtqGNWHTAgMBAAGjggFk
# MIIBYDAfBgNVHSMEGDAWgBRTeb9aqitKz1SA4dibwJ3ysgNmyzAdBgNVHQ4EFgQU
# DuE6qFM6MdWKvsG7rWcaA4WtNA4wDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQI
# MAYBAf8CAQAwHQYDVR0lBBYwFAYIKwYBBQUHAwMGCCsGAQUFBwMIMBEGA1UdIAQK
# MAgwBgYEVR0gADBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0cnVz
# dC5jb20vVVNFUlRydXN0UlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmwwdgYI
# KwYBBQUHAQEEajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVzdC5j
# b20vVVNFUlRydXN0UlNBQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0dHA6
# Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQEMBQADggIBAE1jUO1HNEph
# pNveaiqMm/EAAB4dYns61zLC9rPgY7P7YQCImhttEAcET7646ol4IusPRuzzRl5A
# RokS9At3WpwqQTr81vTr5/cVlTPDoYMot94v5JT3hTODLUpASL+awk9KsY8k9LOB
# N9O3ZLCmI2pZaFJCX/8E6+F0ZXkI9amT3mtxQJmWunjxucjiwwgWsatjWsgVgG10
# Xkp1fqW4w2y1z99KeYdcx0BNYzX2MNPPtQoOCwR/oEuuu6Ol0IQAkz5TXTSlADVp
# bL6fICUQDRn7UJBhvjmPeo5N9p8OHv4HURJmgyYZSJXOSsnBf/M6BZv5b9+If8Aj
# ntIeQ3pFMcGcTanwWbJZGehqjSkEAnd8S0vNcL46slVaeD68u28DECV3FTSK+TbM
# Q5Lkuk/xYpMoJVcp+1EZx6ElQGqEV8aynbG8HArafGd+fS7pKEwYfsR7MUFxmksp
# 7As9V1DSyt39ngVR5UR43QHesXWYDVQk/fBO4+L4g71yuss9Ou7wXheSaG3IYfmm
# 8SoKC6W59J7umDIFhZ7r+YMp08Ysfb06dy6LN0KgaoLtO0qqlBCk4Q34F8W2Wnkz
# GJLjtXX4oemOCiUe5B7xn1qHI/+fpFGe+zmAEc3btcSnqIBv5VPU4OOiwtJbGvoy
# Ji1qV3AcPKRYLqPzW0sH3DJZ84enGm1YMYIEZzCCBGMCAQEwgZEwfDELMAkGA1UE
# BhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2Fs
# Zm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdv
# IFJTQSBDb2RlIFNpZ25pbmcgQ0ECEQDUdpM6iqGV/ka3TP9ciP0/MA0GCWCGSAFl
# AwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQB
# gjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkE
# MSIEIFFbkxqYwuYfzyrhRkVKZzcUiuqyRtWLbXHDAAXP6vngMA0GCSqGSIb3DQEB
# AQUABIIBAAPw7XbQSJGdLtzsLzsO39XHfShZy3uRy/Q1Aa9bxlCa8nOL+tPEgU9i
# eb+sW0IJxiMGktn/okYnLunT9CwFeceDZcpgW6gYTYN4jKzXCvJ7tabQ2ZUAiDt5
# ANFFKKGDNbk7ZD/c2/pzMR1H2qQSUfi8DLaOf88gANBRt9PJrHJg7dCpJruHocpi
# 8x0nW2fO0PN4GCGYSIeBXOoalvNFTHW83iiD/9aq7WgljvIPpLlM4YUewwcGE3oM
# oCH8TC4q4bdqLRlW7u2whjAT+V52PodaYBD1vp076HCf8qknuEevFf+/Br8ipOUi
# kC08swzSbSiakL5SckNiQ23fYxmaNq2hggIoMIICJAYJKoZIhvcNAQkGMYICFTCC
# AhECAQEwgY4wejELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hl
# c3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0
# ZWQxIDAeBgNVBAMTF0NPTU9ETyBUaW1lIFN0YW1waW5nIENBAhArc9t0YxFMWlsy
# SvIwV3JJMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwG
# CSqGSIb3DQEJBTEPFw0yMDA1MTgxMjAyNTlaMCMGCSqGSIb3DQEJBDEWBBSo6B2F
# U6ddpi9mvc54D1CCkAwF+jANBgkqhkiG9w0BAQEFAASCAQBX/u6xXP3GvpVL0ksG
# /tQK5+WoJr5nu2VgB8/lqS/pRGuDb240Bcg+ztjHZ5KMMaLIDp7Ho6FOEAvwR4gb
# HIrwJcZ53rRga6U3Geg+UpGgEKYNy5RQcm6gBnDzScp5yc9n45LaTAb2qm2m7T6G
# jYrzKzfV9zr8wOuv+Vb0pa6S05lLHn81ehATWqb+Q2ONQZpPmFvaZUMdJXjmzdVq
# hfx0+28rYQ6o0KoOZ/GIArRTQYD4XgoHJqa7YZYkzTbMcJWzAb6Sy0GmClKe1iAc
# R8g4E3vGAVszL0ppqahr15MFAkXJATO9L0oRnBuwULj6TjsyOZvnFjkbOHenk692
# Xke8
# SIG # End signature block
