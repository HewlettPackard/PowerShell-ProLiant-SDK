########################################################
#Configure Network Settings
###################################################----#

<#
.Synopsis
    This script allows user to configure network settings of HPE Proliant Gen10 and Gen9 servers

.DESCRIPTION
    This script allows user to configure network settings of HPE Proliant Gen10 and Gen9 servers.
    This script  allows to change the DHCPv4 to enabled or disabled. When DHCPv4 value is set to disabled then it prompts the user to enter 
    IPV4Address, IPV4Gateway and other settings.

.EXAMPLE
     ConfigureNetworkBootsettings.ps1

     This mode of execution of script will prompt for 
     
     -Address :- Accept IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
     
     -Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
     
     -DHCPv4 :- it will prompt to eneter DHCPv4 value to set. User can enter "Enabled" or "Disabled".If the DHCPv4 value is Disabled then the
                 user will be prompted to enter the IPV4 settings.

.EXAMPLE
    ConfigureNetworkBootsettings.ps1 -Address "10.20.30.40,10.25.35.45" -DHCPv4 "Enabled"

    This mode of script have input parameter for Address and DHCPv4.
    
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -DHCPv4 :- Use this Parameter to specify DHCPv4. Supported values are "Enabled" or "Disabled".

    This script execution will prompt user to enter user credentials. It is recommended for this script to use same credential for multiple servers.

.EXAMPLE
    ConfigureNetworkBootsettings.ps1 -Address "10.20.30.40" -Credential $UserCredential -IPV4Address "10.20.11.12" -IPV4SubnetMask "255.255.255.0" -IPV4Gateway "10.20.12.1" -IPV4PrimaryDNS "10.20.11.12" -IPV4SecondaryDNS "11.15.12.1"
     
    This mode of script have input parameter for Address and DHCPv4.
	
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :-  to specify server credential
    
    -IPV4Address :- Use this Parameter to specify static IPV4Address. 
    
    -IPV4SubnetMask :-Use this Parameter to specify static IPv4 subnet mask.
    
    -IPV4Gateway :-Use this Parameter to specify static IPv4 gateway.
    
    -IPV4PrimaryDNS :-Use this Parameter to specify IPv4 primary DNS.
    
    -IPV4SecondaryDNS :-Use this Parameter to specify IPv4 secondary DNS.
    
.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 2.1.0.0
    Date    : 22/06/2017
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    DHCPv4

.OUTPUTS
    None (by default)

.LINK    
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param
(
        [string]$Address,  # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
        [PSCredential]$Credential, #In case of multiple servers it use same credential for all the servers
        [string]$DHCPv4,
        [string]$IPV4Address,
        [string]$IPV4SubnetMask,
        [string]$IPV4Gateway,
        [string]$IPV4PrimaryDNS,
        [string]$IPV4SecondaryDNS
         
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
Write-Host "******Script execution started******" -ForegroundColor Green
Write-Host ""
#Decribe what script does to the user

Write-Host "This script demonstrate how to configure the network settings .This script  allows to change the DHCPv4 to enabled or disabled. When DHCPv4 value is set to disabled then it prompts the user to enter 
    IPV4Address, IPV4Gateway and other settings"
Write-Host ""

#dont show error in script

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"
$ErrorActionPreference = "SilentlyContinue"

#check powershell support
    <#Write-Host "Checking PowerShell version support"
    Write-Host ""#>
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
    <#Write-Host "Checking HPEBIOSCmdlets module"
    Write-Host ""#>

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

#Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

# create connection object
[array]$ListOfConnection = @()

foreach($IPAddress in $ListOfAddress)
{
    
    Write-Host ""
    Write-Host "Connecting to server  : $IPAddress"
    $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential

    #Retry connection if it is failed because of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "The underlying connection was closed")
    {
       $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        $connection
        if($connection.ProductName.Contains("Gen9") -or $connection.ProductName.Contains("Gen10"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "Network Boot Settings is not supported on Server $($connection.IP)"
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
    Write-Host "Exit..."
    Write-Host ""
    exit
}


# Get current network settings
if($ListOfConnection.Count -ne 0)
{
    Write-Host ""
    Write-Host "Current Network Settings" -ForegroundColor Yellow
    Write-Host ""
    for($i=0; $i -lt $ListOfConnection.Count; $i++)
    {
        $result = $ListOfConnection[$i]| Get-HPEBIOSNetworkBootOption
        Write-Host  ("----------Server {0} ----------" -f ($i+1))  -ForegroundColor DarkYellow
        Write-Host ""
        $tmpObj =   New-Object PSObject        
                    $tmpObj | Add-Member NoteProperty "IP" $result.IP
                    $tmpObj | Add-Member NoteProperty "Hostname" $result.Hostname
                    $tmpObj | Add-Member NoteProperty "StatusType" $result.StatusType
                    $tmpObj | Add-Member NoteProperty "DHCPv4" $result.DHCPv4
                    $tmpObj | Add-Member NoteProperty "IPv4Address" $result.IPv4Address
                    $tmpObj | Add-Member NoteProperty "IPv4SubnetMask" $result.IPv4SubnetMask
                    $tmpObj | Add-Member NoteProperty "IPv4Gateway" $result.IPv4Gateway
                    $tmpObj | Add-Member NoteProperty "IPv4PrimaryDNS" $result.IPv4PrimaryDNS
                    $tmpObj | Add-Member NoteProperty "IPv4SecondaryDNS" $result.IPv4SecondaryDNS

        $tmpObj
    }
}


# Take user input to enable or disable DHCP 
 Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma (,)" -ForegroundColor Yellow
 Write-Host ""
if($DHCPv4 -eq "" -and $IPV4Address -eq "" -and $IPV4SubnetMask -eq "" -and $IPV4Gateway -eq "" -and $IPV4PrimaryDNS -eq "" -and $IPV4SecondaryDNS -eq "")
{
   
    $DHCPv4 = Read-Host "Enter DHCP value [Accepted values : (Enabled or Disabled)]"
    Write-Host ""
}
elseif($DHCPv4 -eq "" -and $IPV4Address -ne "" -and $IPV4SubnetMask -ne "" -and $IPV4Gateway -ne "" -and $IPV4PrimaryDNS -ne "" -and $IPV4SecondaryDNS -ne "")
{
    $DHCPv4="Disabled"
}

$inputDHCPv4List=@()
$IPV4AddressList =@()
$IPV4SubnetMaskList =@()
$IPV4GatewayList =@()
$IPV4PrimaryDNSList=@()
$IPV4SecondaryDNSList =@()

if($DHCPv4 -ne "")
{
    $inputDHCPv4List =  ($DHCPv4.Trim().Split(','))
}


if($inputDHCPv4List.Count -eq 0)
{
    Write-Host "You have not enterd DHCP value"
    Write-Host "Exit....."
    exit
}
[array]$DHCPToset = @()
[string]$DHCPDisabledIPList=$null
for($i=0; $i -lt $ListOfAddress.Count; $i++)
{
    if($inputDHCPv4List.Count -gt 1)
    {
        if($inputDHCPv4List[$i].ToLower().Equals("enabled"))
        {
            $DHCPToset += "Enabled";
            $DHCPEnabledConnectionList +=$ListOfConnection[$i]
        }
        elseif($inputDHCPv4List[$i].ToLower().Equals("disabled"))
        {
            $DHCPToset += "Disabled";
            $DHCPDisabledIPList += $ListOfAddress[$i] +" "
            $DHCPDisabledConnectionList+=$ListOfConnection[$i]
        }
        else
        {
            Write-Host "Invalid value" -ForegroundColor Red
            Write-Host "Exit..."
            exit
        }
    }
    else
    {
        if($inputDHCPv4List.ToLower().Equals("enabled"))
        {
            $DHCPToset += "Enabled";
            
        }
        elseif($inputDHCPv4List.ToLower().Equals("disabled"))
        {
            $DHCPToset += "Disabled";
            $DHCPDisabledIPList += $ListOfAddress[$i] +" "
        
        }
        else
        {
            Write-Host "Invalid value" -ForegroundColor Red
            Write-Host "Exit..."
            exit
        }
    }
 }

 if($DHCPDisabledIPList.Length -gt 0 -and $IPV4Address -eq "" -and $IPV4SubnetMask -eq "" -and $IPV4Gateway -eq "" -and $IPV4PrimaryDNS -eq "" -and $IPV4SecondaryDNS -eq "")
 {
    [string]$IPV4Address = Read-Host "Enter IPV4Address to be set for servers"  $DHCPDisabledIPList
    [string]$IPV4SubnetMask = Read-Host "Enter IPV4SubnetMask to be set for servers" $DHCPDisabledIPList
    [string]$IPV4Gateway = Read-Host "Enter IPV4Gateway to be set for servers" $DHCPDisabledIPList
    [string]$IPV4PrimaryDNS = Read-Host "Enter IPV4PrimaryDNS to be set for servers" $DHCPDisabledIPList
    [string]$IPV4SecondaryDNS = Read-Host "Enter IPV4SecondaryDNS to be set for servers" $DHCPDisabledIPList

 } 
 
 if($IPV4Address -ne "" -and $IPV4SubnetMask -ne "" -and $IPV4Gateway -ne "" -and $IPV4PrimaryDNS -ne "" -and $IPV4SecondaryDNS -ne "")
{
    $IPV4AddressList = ($IPV4Address.Trim().Split(','))
    $IPV4SubnetMaskList = ($IPV4SubnetMask.Trim().Split(','))
    $IPV4GatewayList = ($IPV4Gateway.Trim().Split(','))
    $IPV4PrimaryDNSList = ($IPV4PrimaryDNS.Trim().Split(','))
    $IPV4SecondaryDNSList = ($IPV4SecondaryDNS.Trim().Split(','))
}
 
Write-Host "Changing network setting ....." -ForegroundColor Green

if($ListOfConnection.Count -ne 0)
{
    $failureCount = 0
    if($ListOfConnection.Count -gt 1)
    {

        if($DHCPDisabledIPList.Length -gt 0)
        {
            $resultList = $DHCPDisabledConnectionList | Set-HPEBIOSNetworkBootOption -DHCPv4 Disabled -IPv4Address $IPV4Address -IPv4SubnetMask $IPV4SubnetMask -IPv4Gateway $IPV4Gateway -IPv4PrimaryDNS $IPV4PrimaryDNS -IPv4SecondaryDNS $IPV4SecondaryDNS
        }
        if($DHCPEnabledConnectionList.Count -gt 0)
        {
            $resultList = $DHCPEnabledConnectionList | Set-HPEBIOSNetworkBootOption -DHCPv4 Enabled
        }
    }
    else
    {
        if($IPV4Address -ne "" -and $IPV4SubnetMask -ne "" -and $IPV4Gateway -ne "" -and $IPV4PrimaryDNS -ne "" -and $IPV4SecondaryDNS -ne "")
        {
            $resultList = $ListOfConnection[0] | Set-HPEBIOSNetworkBootOption -DHCPv4 $DHCPToset[0] -IPv4Address $IPV4AddressList[0] -IPv4SubnetMask $IPV4SubnetMaskList[0] -IPv4Gateway $IPV4GatewayList[0] -IPv4PrimaryDNS $IPV4PrimaryDNSList[0] -IPv4SecondaryDNS $IPV4SecondaryDNSList[0]
        }
        else
        {
            $resultList = $ListOfConnection[0] | Set-HPEBIOSNetworkBootOption -DHCPv4 $DHCPToset[0]
        }
    }
    foreach($result in $resultList)
    {
        
		if($result.StatusType -eq "Error")
		{
			Write-Host ""
			Write-Host "Network settings Cannot be modified"
			Write-Host "Server : $($result.IP)"
			Write-Host "Error : $($result.StatusMessage)"
			Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
			Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
			Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
			$failureCount++
		}
    }
    

if($failureCount -ne $resultList.Count)
{
	Write-Host ""
	Write-host "Network settings changed successfully" -ForegroundColor Green
	Write-Host ""
}

if($ListOfConnection.Count -ne 0)
{
	for($i=0; $i -lt $ListOfConnection.Count; $i++)
	{
		$result = $ListOfConnection[$i]| Get-HPEBIOSNetworkBootOption
		Write-Host  ("----------Server {0} ----------" -f ($i+1))  -ForegroundColor DarkYellow
		Write-Host ""
		$tmpObj =   New-Object PSObject        
				$tmpObj | Add-Member NoteProperty "IP" $result.IP
				$tmpObj | Add-Member NoteProperty "Hostname" $result.Hostname
				$tmpObj | Add-Member NoteProperty "StatusType" $result.StatusType
				$tmpObj | Add-Member NoteProperty "DHCPv4" $result.DHCPv4
				$tmpObj | Add-Member NoteProperty "IPv4Address" $result.IPv4Address
				$tmpObj | Add-Member NoteProperty "IPv4SubnetMask" $result.IPv4SubnetMask
				$tmpObj | Add-Member NoteProperty "IPv4Gateway" $result.IPv4Gateway
				$tmpObj | Add-Member NoteProperty "IPv4PrimaryDNS" $result.IPv4PrimaryDNS
				$tmpObj | Add-Member NoteProperty "IPv4SecondaryDNS" $result.IPv4SecondaryDNS

		$tmpObj
	}
}
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "******Script execution completed******" -ForegroundColor Green
exit

}




# SIG # Begin signature block
# MIIjqAYJKoZIhvcNAQcCoIIjmTCCI5UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBof4R1MWz6SIDN
# rox34UHAvJz5bAy/TqRJ3veO4dRHXKCCHrMwggPuMIIDV6ADAgECAhB+k+v7fMZO
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
# lEM/RlUm1sT6iJXikZqjLQuF3qyM4PlncJ9xeQIx92GiKcQwggVqMIIEUqADAgEC
# AhEAp7f+kfK8y/XKvnoKBpdAGDANBgkqhkiG9w0BAQsFADB9MQswCQYDVQQGEwJH
# QjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3Jk
# MRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDEjMCEGA1UEAxMaQ09NT0RPIFJT
# QSBDb2RlIFNpZ25pbmcgQ0EwHhcNMTcwNTI2MDAwMDAwWhcNMTgwNTI2MjM1OTU5
# WjCB0jELMAkGA1UEBhMCVVMxDjAMBgNVBBEMBTk0MzA0MQswCQYDVQQIDAJDQTES
# MBAGA1UEBwwJUGFsbyBBbHRvMRwwGgYDVQQJDBMzMDAwIEhhbm92ZXIgU3RyZWV0
# MSswKQYDVQQKDCJIZXdsZXR0IFBhY2thcmQgRW50ZXJwcmlzZSBDb21wYW55MRow
# GAYDVQQLDBFIUCBDeWJlciBTZWN1cml0eTErMCkGA1UEAwwiSGV3bGV0dCBQYWNr
# YXJkIEVudGVycHJpc2UgQ29tcGFueTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAJ6VdqLTjoGE+GPiPE8LxjEMKQOW/4rFUFPo9ZWeLYcyUdOZlYC+Hgpa
# /qJXVLcrhNqe0Cazv6FPIc0sjYtk8gfJW/al17nz+e9olqgE7mFtu/YiFb/HMbJz
# JINNfnvlIAQW5ECQv+HkSm2Lboa7YxzsWKLbY17gOz6cJYxDNLqTgyI4GWnaYeSd
# ZklzdmpxWMrLAlzImRwQl76si0MHtJ8mrSaGUewmLmb9QnFeznQx1igYk5CsiIua
# vmjCGjQo8mymiaeWz1cldGqw5GLEyEu5aV7bP0v0z7IwwwWtt+YP6PUK7gzJdboj
# Rmxc3aqDAwD6z4p2tm7qzVW7dgar4WcCAwEAAaOCAY0wggGJMB8GA1UdIwQYMBaA
# FCmRYP+KTfrr+aZquM/55ku9Sc4SMB0GA1UdDgQWBBTMsuK5LRcd3jjKKo4TK1nD
# /5BaiDAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggr
# BgEFBQcDAzARBglghkgBhvhCAQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIx
# AQIBAwIwKzApBggrBgEFBQcCARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9D
# UFMwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5jb20vQ09N
# T0RPUlNBQ29kZVNpZ25pbmdDQS5jcmwwdAYIKwYBBQUHAQEEaDBmMD4GCCsGAQUF
# BzAChjJodHRwOi8vY3J0LmNvbW9kb2NhLmNvbS9DT01PRE9SU0FDb2RlU2lnbmlu
# Z0NBLmNydDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuY29tb2RvY2EuY29tMA0G
# CSqGSIb3DQEBCwUAA4IBAQBkfKIfp8al8qz+C5b52vHoS7EoTFAtTQLo0HdyQgdw
# hy9DlOiA/1OLESM6tWeHfi4lgKlzWafwetY1khHAgYwB2IKklC1OBBSynm/pl4rM
# hRPrPoDp4OwGrsW5tpCRZ27lQ6pPrPWochPNOg7qo3qbHDFmZygdgC9/d1bZUk23
# /UNLaCnieBvUPoGwpD0W/fpocueFSOwy0D9Xbct5hvc8Vk3N9dg5+Ey1t9uaGxTa
# j3kbcpDuq9XnbbYrtNfFGihtX5EmeCX1mp56ifBgYWAGXueN7ZUliYwQGJqgsher
# RVU8EVh9kELgM9xmzxUM3ueGnFHNMibWXUKeZfQxjtVNMIIFdDCCBFygAwIBAgIQ
# J2buVutJ846r13Ci/ITeIjANBgkqhkiG9w0BAQwFADBvMQswCQYDVQQGEwJTRTEU
# MBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAkBgNVBAsTHUFkZFRydXN0IEV4dGVybmFs
# IFRUUCBOZXR3b3JrMSIwIAYDVQQDExlBZGRUcnVzdCBFeHRlcm5hbCBDQSBSb290
# MB4XDTAwMDUzMDEwNDgzOFoXDTIwMDUzMDEwNDgzOFowgYUxCzAJBgNVBAYTAkdC
# MRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQx
# GjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSswKQYDVQQDEyJDT01PRE8gUlNB
# IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAkehUktIKVrGsDSTdxc9EZ3SZKzejfSNwAHG8U9/E+ioSj0t/EFa9
# n3Byt2F/yUsPF6c947AEYe7/EZfH9IY+Cvo+XPmT5jR62RRr55yzhaCCenavcZDX
# 7P0N+pxs+t+wgvQUfvm+xKYvT3+Zf7X8Z0NyvQwA1onrayzT7Y+YHBSrfuXjbvzY
# qOSSJNpDa2K4Vf3qwbxstovzDo2a5JtsaZn4eEgwRdWt4Q08RWD8MpZRJ7xnw8ou
# tmvqRsfHIKCxH2XeSAi6pE6p8oNGN4Tr6MyBSENnTnIqm1y9TBsoilwie7SrmNnu
# 4FGDwwlGTm0+mfqVF9p8M1dBPI1R7Qu2XK8sYxrfV8g/vOldxJuvRZnio1oktLqp
# Vj3Pb6r/SVi+8Kj/9Lit6Tf7urj0Czr56ENCHonYhMsT8dm74YlguIwoVqwUHZwK
# 53Hrzw7dPamWoUi9PPevtQ0iTMARgexWO/bTouJbt7IEIlKVgJNp6I5MZfGRAy1w
# dALqi2cVKWlSArvX31BqVUa/oKMoYX9w0MOiqiwhqkfOKJwGRXa/ghgntNWutMtQ
# 5mv0TIZxMOmm3xaG4Nj/QN370EKIf6MzOi5cHkERgWPOGHFrK+ymircxXDpqR+DD
# eVnWIBqv8mqYqnK8V0rSS527EPywTEHl7R09XiidnMy/s1Hap0flhFMCAwEAAaOB
# 9DCB8TAfBgNVHSMEGDAWgBStvZh6NLQm9/rEJlTvA73gJMtUGjAdBgNVHQ4EFgQU
# u69+Aj36pvE8hI6t7jiY7NkyMtQwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQF
# MAMBAf8wEQYDVR0gBAowCDAGBgRVHSAAMEQGA1UdHwQ9MDswOaA3oDWGM2h0dHA6
# Ly9jcmwudXNlcnRydXN0LmNvbS9BZGRUcnVzdEV4dGVybmFsQ0FSb290LmNybDA1
# BggrBgEFBQcBAQQpMCcwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVz
# dC5jb20wDQYJKoZIhvcNAQEMBQADggEBAGS/g/FfmoXQzbihKVcN6Fr30ek+8nYE
# bvFScLsePP9NDXRqzIGCJdPDoCpdTPW6i6FtxFQJdcfjJw5dhHk3QBN39bSsHNA7
# qxcS1u80GH4r6XnTq1dFDK8o+tDb5VCViLvfhVdpfZLYUspzgb8c8+a4bmYRBbMe
# lC1/kZWSWfFMzqORcUx8Rww7Cxn2obFshj5cqsQugsv5B5a6SE2Q8pTIqXOi6wZ7
# I53eovNNVZ96YUWYGGjHXkBrI/V5eu+MtWuLt29G9HvxPUsE2JOAWVrgQSQdso8V
# YFhH2+9uRv0V9dlfmrPb2LjkQLPNlzmuhbsdjrzch5vRpu/xO28QOG8wggXgMIID
# yKADAgECAhAufIfMDpNKUv6U/Ry3zTSvMA0GCSqGSIb3DQEBDAUAMIGFMQswCQYD
# VQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdT
# YWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDErMCkGA1UEAxMiQ09N
# T0RPIFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xMzA1MDkwMDAwMDBa
# Fw0yODA1MDgyMzU5NTlaMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVy
# IE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBD
# QSBMaW1pdGVkMSMwIQYDVQQDExpDT01PRE8gUlNBIENvZGUgU2lnbmluZyBDQTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKaYkGN3kTR/itHd6WcxEevM
# Hv0xHbO5Ylc/k7xb458eJDIRJ2u8UZGnz56eJbNfgagYDx0eIDAO+2F7hgmz4/2i
# aJ0cLJ2/cuPkdaDlNSOOyYruGgxkx9hCoXu1UgNLOrCOI0tLY+AilDd71XmQChQY
# USzm/sES8Bw/YWEKjKLc9sMwqs0oGHVIwXlaCM27jFWM99R2kDozRlBzmFz0hUpr
# D4DdXta9/akvwCX1+XjXjV8QwkRVPJA8MUbLcK4HqQrjr8EBb5AaI+JfONvGCF1H
# s4NB8C4ANxS5Eqp5klLNhw972GIppH4wvRu1jHK0SPLj6CH5XkxieYsCBp9/1QsC
# AwEAAaOCAVEwggFNMB8GA1UdIwQYMBaAFLuvfgI9+qbxPISOre44mOzZMjLUMB0G
# A1UdDgQWBBQpkWD/ik366/mmarjP+eZLvUnOEjAOBgNVHQ8BAf8EBAMCAYYwEgYD
# VR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEFBQcDAzARBgNVHSAECjAI
# MAYGBFUdIAAwTAYDVR0fBEUwQzBBoD+gPYY7aHR0cDovL2NybC5jb21vZG9jYS5j
# b20vQ09NT0RPUlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmwwcQYIKwYBBQUH
# AQEEZTBjMDsGCCsGAQUFBzAChi9odHRwOi8vY3J0LmNvbW9kb2NhLmNvbS9DT01P
# RE9SU0FBZGRUcnVzdENBLmNydDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuY29t
# b2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4ICAQACPwI5w+74yjuJ3gxtTbHxTpJP
# r8I4LATMxWMRqwljr6ui1wI/zG8Zwz3WGgiU/yXYqYinKxAa4JuxByIaURw61OHp
# Cb/mJHSvHnsWMW4j71RRLVIC4nUIBUzxt1HhUQDGh/Zs7hBEdldq8d9YayGqSdR8
# N069/7Z1VEAYNldnEc1PAuT+89r8dRfb7Lf3ZQkjSR9DV4PqfiB3YchN8rtlTaj3
# hUUHr3ppJ2WQKUCL33s6UTmMqB9wea1tQiCizwxsA4xMzXMHlOdajjoEuqKhfB/L
# YzoVp9QVG6dSRzKp9L9kR9GqH1NOMjBzwm+3eIKdXP9Gu2siHYgL+BuqNKb8jPXd
# f2WMjDFXMdA27Eehz8uLqO8cGFjFBnfKS5tRr0wISnqP4qNS4o6OzCbkstjlOMKo
# 7caBnDVrqVhhSgqXtEtCtlWdvpnncG1Z+G0qDH8ZYF8MmohsMKxSCZAWG/8rndvQ
# IMqJ6ih+Mo4Z33tIMx7XZfiuyfiDFJN2fWTQjs6+NX3/cjFNn569HmwvqI8MBlD7
# jCezdsn05tfDNOKMhyGGYf6/VXThIXcDCmhsu+TJqebPWSXrfOxFDnlmaOgizbjv
# mIVNlhE8CYrQf7woKBP7aspUjZJczcJlmAaezkhb1LU3k0ZBfAfdz/pD77pnYf99
# SeC7MH1cgOPmFjlLpzGCBEswggRHAgEBMIGSMH0xCzAJBgNVBAYTAkdCMRswGQYD
# VQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGjAYBgNV
# BAoTEUNPTU9ETyBDQSBMaW1pdGVkMSMwIQYDVQQDExpDT01PRE8gUlNBIENvZGUg
# U2lnbmluZyBDQQIRAKe3/pHyvMv1yr56CgaXQBgwDQYJYIZIAWUDBAIBBQCgfDAQ
# BgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgQBfahoGo
# llKDFui4fFf85vO0AGhnSHNfCqh53RnVfvUwDQYJKoZIhvcNAQEBBQAEggEAR16e
# 6o7WkG4CLsrEYfo15IyAjVRQKocTf7w4d9yYDIbBo/1DEcUaPy/TKYZDYmfhLNfs
# wY4jynajpUNCg8PDB5zwToGEZKIoyiBUiBmjmFdqCREhpH94Vb7pYU7ECNhAjvmr
# lGLb5aEamwz00EDvDFjub14XAn6EvWjpMThBA9yjRovmPmUnKpEUtdla3bYjBUlp
# J+wE00f95+GaLVIz1+W4JaWYnGhe9t11qKuwqc5Ga4D2w8dRiCs51RWNfRWkpSSG
# AQ+uwR8fR9FBD2S1PGlKEavtatoB/BjYvy8RPXMYZaS10MPsJrnsBaRdW6dteKBk
# OLhlYRBpv/31r3jDWKGCAgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4x
# CzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4G
# A1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAO
# z/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xODAzMDkxMDEwNDRaMCMGCSqGSIb3DQEJ
# BDEWBBTPqWLGXJLp5A9aZlZrcIZ4NfuMdzANBgkqhkiG9w0BAQEFAASCAQCct1tn
# fC05AiwABiSw2L9D1U/Ae2+RCp8TdQqJG0OUwB3r8uheJ3NAdvNJI80CSXVy8jYW
# 8wvgmaIT1JdED5gklghLXdCFw3GxHvZRWrXin6w57mw79AG2sgiAZAtt5SCGsebg
# UJWsrS2/eDinLoTE+oukjFKKmOr9R0F1U4sCG9ZuwEsQzmNlbqDv3F5I8njR4Bzz
# enMNPs4OBBuz0pZJuT1Ayud8OsbUc0AA5RyI0Q7TYoy27prEcbyf2pxSY5SEDN1q
# n8vEQi8vFVw4odM9hlY0bOWauz5bBnjs8saktxYaIg6cD8X6wbE8YHSqUpgpKbLC
# 2L8TV0btXbz0thcT
# SIG # End signature block
