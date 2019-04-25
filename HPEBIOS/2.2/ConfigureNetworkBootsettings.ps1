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
    Version : 2.2.0.0
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
         Write-Host "Connection cannot be established to the server : $IPAddress" -ForegroundColor Red        
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
# MIIkbgYJKoZIhvcNAQcCoIIkXzCCJFsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAtFGa/rQcR94AN
# +/PJgwJSvBZQgP8/hIxvwR6wko4IdqCCHuQwggQUMIIC/KADAgECAgsEAAAAAAEv
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
# oy0Lhd6sjOD5Z3CfcXkCMfdhoinEMIIFYTCCBEmgAwIBAgIQKk+D8r3YbqOXfd/7
# XMeTAzANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3Jl
# YXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0
# aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBD
# QTAeFw0xOTAzMjAwMDAwMDBaFw0yMDAzMTkyMzU5NTlaMIHSMQswCQYDVQQGEwJV
# UzEOMAwGA1UEEQwFOTQzMDQxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlQYWxvIEFs
# dG8xHDAaBgNVBAkMEzMwMDAgSGFub3ZlciBTdHJlZXQxKzApBgNVBAoMIkhld2xl
# dHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBhbnkxGjAYBgNVBAsMEUhQIEN5YmVy
# IFNlY3VyaXR5MSswKQYDVQQDDCJIZXdsZXR0IFBhY2thcmQgRW50ZXJwcmlzZSBD
# b21wYW55MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA59zZBLR3Nr2Z
# onxPn5G79E3tK2wKY3b734Vj0vNVkcnp29q+rChhEiLs1PQER7cnjNUifnh+NHqQ
# eROQcCx8BiZJsTqvd9gFsxjFaZIJhnHbdM+ZN8OaNXBNYD0GwS4bqqLIIj14Nbmq
# 19MGvWc+JF1DnP83hpU9+lz+vgxRMHgn5B96ZEC+3FfjE2+D9FSxB63mCGp5poFB
# BeEoVUQu5BlhQmsUlAdBYHlGZBTUW3AI9+z5RpllFH1CobWQjEc5oFgHQYusycbG
# uQ8llao1LnVuqA3Me5RM9e6OusUqo8xbGOs1C0wG7kcUuEZc0FvNqLrDDxLXZ4Lj
# DYyWvzI0jQIDAQABo4IBhjCCAYIwHwYDVR0jBBgwFoAUDuE6qFM6MdWKvsG7rWca
# A4WtNA4wHQYDVR0OBBYEFEWMwxb0QRn/VQDouO6o/0zT4q54MA4GA1UdDwEB/wQE
# AwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEGCWCGSAGG
# +EIBAQQEAwIEEDBABgNVHSAEOTA3MDUGDCsGAQQBsjEBAgEDAjAlMCMGCCsGAQUF
# BwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzBDBgNVHR8EPDA6MDigNqA0hjJo
# dHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29SU0FDb2RlU2lnbmluZ0NBLmNy
# bDBzBggrBgEFBQcBAQRnMGUwPgYIKwYBBQUHMAKGMmh0dHA6Ly9jcnQuc2VjdGln
# by5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5nQ0EuY3J0MCMGCCsGAQUFBzABhhdo
# dHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAUslrOrqU
# 23tw/JaO8EfUoi7xaCr33vMDDVaBsIiVtqCxfRHv3uW4ieqyQQ4sg2CrlLaeIF9X
# CmF+pxDQcf8DfkaHH0eYkBpmQDxijakGf+7p/Tp8OZSuu8tabOEeqzSzE0bmXF28
# kcMD8Nl4+OkCAq6Lf7+Xdhqg1IYGGbeVt4Uk4iyvTorVayiaJf8lGhvDcmQTN9O6
# Z1gWH0dC7jENuFkBQmOc7Q7kL0yXETt4RIUpjsifgLCAQZY/e0FKkppZ5hq5htQ3
# Fj+tJkWR+VP9M5E2eJo9apTx6bDJIX5AKEfqbuo1RiA3IsQ1UNwxK48jLiBO1uL3
# 0pi8x1/3OdlnfzCCBXcwggRfoAMCAQICEBPqKHBb9OztDDZjCYBhQzYwDQYJKoZI
# hvcNAQEMBQAwbzELMAkGA1UEBhMCU0UxFDASBgNVBAoTC0FkZFRydXN0IEFCMSYw
# JAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5hbCBUVFAgTmV0d29yazEiMCAGA1UEAxMZ
# QWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9vdDAeFw0wMDA1MzAxMDQ4MzhaFw0yMDA1
# MzAxMDQ4MzhaMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEU
# MBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0
# d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhv
# cml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAIASZRc2DsPbCLPQ
# rFcNdu3NJ9NMrVCDYeKqIE0JLWQJ3M6Jn8w9qez2z8Hc8dOx1ns3KBErR9o5xrw6
# GbRfpr19naNjQrZ28qk7K5H44m/Q7BYgkAk+4uh0yRi0kdRiZNt/owbxiBhqkCI8
# vP4T8IcUe/bkH47U5FHGEWdGCFHLhhRUP7wz/n5snP8WnRi9UY41pqdmyHJn2yFm
# sdSbeAPAUDrozPDcvJ5M/q8FljUfV1q3/875PbcstvZU3cjnEjpNrkyKt1yatLcg
# Pcp/IjSufjtoZgFE5wFORlObM2D3lL5TN5BzQ/Myw1Pv26r+dE5px2uMYJPexMcM
# 3+EyrsyTO1F4lWeL7j1W/gzQaQ8bD/MlJmszbfduR/pzQ+V+DqVmsSl8MoRjVYnE
# DcGTVDAZE6zTfTen6106bDVc20HXEtqpSQvf2ICKCZNijrVmzyWIzYS4sT+kOQ/Z
# Ap7rEkyVfPNrBaleFoPMuGfi6BOdzFuC00yz7Vv/3uVzrCM7LQC/NVV0CUnYSVga
# f5I25lGSDvMmfRxNF7zJ7EMm0L9BX0CpRET0medXh55QH1dUqD79dGMvsVBlCeZY
# Qi5DGky08CVHWfoEHpPUJkZKUIGy3r54t/xnFeHJV4QeD2PW6WK61l9VLupcxigI
# BCU5uA4rqfJMlxwHPw1S9e3vL4IPAgMBAAGjgfQwgfEwHwYDVR0jBBgwFoAUrb2Y
# ejS0Jvf6xCZU7wO94CTLVBowHQYDVR0OBBYEFFN5v1qqK0rPVIDh2JvAnfKyA2bL
# MA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MBEGA1UdIAQKMAgwBgYE
# VR0gADBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3JsLnVzZXJ0cnVzdC5jb20v
# QWRkVHJ1c3RFeHRlcm5hbENBUm9vdC5jcmwwNQYIKwYBBQUHAQEEKTAnMCUGCCsG
# AQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBDAUA
# A4IBAQCTZfY3g5UPXsOCHB/Wd+c8isCqCfDpCybx4MJqdaHHecm5UmDIKRIO8K0D
# 1gnEdt/lpoGVp0bagleplZLFto8DImwzd8F7MhduB85aFEE6BSQb9hQGO6glJA67
# zCp13blwQT980GM2IQcfRv9gpJHhZ7zeH34ZFMljZ5HqZwdrtI+LwG5DfcOhgGyy
# HrxThX3ckKGkvC3vRnJXNQW/u0a7bm03mbb/I5KRxm5A+I8pVupf1V8UU6zwT2Hq
# 9yLMp1YL4rg0HybZexkFaD+6PNQ4BqLT5o8O47RxbUBCxYS0QJUr9GWgSHn2HYFj
# lp1PdeD4fOSOqdHyrYqzjMchzcLvMIIF9TCCA92gAwIBAgIQHaJIMG+bJhjQguCW
# fTPTajANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5l
# dyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNF
# UlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNh
# dGlvbiBBdXRob3JpdHkwHhcNMTgxMTAyMDAwMDAwWhcNMzAxMjMxMjM1OTU5WjB8
# MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
# VQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMT
# G1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAIYijTKFehifSfCWL2MIHi3cfJ8Uz+MmtiVmKUCGVEZ0MWLF
# EO2yhyemmcuVMMBW9aR1xqkOUGKlUZEQauBLYq798PgYrKf/7i4zIPoMGYmobHut
# AMNhodxpZW0fbieW15dRhqb0J+V8aouVHltg1X7XFpKcAC9o95ftanK+ODtj3o+/
# bkxBXRIgCFnoOc2P0tbPBrRXBbZOoT5Xax+YvMRi1hsLjcdmG0qfnYHEckC14l/v
# C0X/o84Xpi1VsLewvFRqnbyNVlPG8Lp5UEks9wO5/i9lNfIi6iwHr0bZ+UYc3Ix8
# cSjz/qfGFN1VkW6KEQ3fBiSVfQ+noXw62oY1YdMCAwEAAaOCAWQwggFgMB8GA1Ud
# IwQYMBaAFFN5v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1UdDgQWBBQO4TqoUzox1Yq+
# wbutZxoDha00DjAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADAd
# BgNVHSUEFjAUBggrBgEFBQcDAwYIKwYBBQUHAwgwEQYDVR0gBAowCDAGBgRVHSAA
# MFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9VU0VS
# VHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDB2BggrBgEFBQcBAQRq
# MGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9VU0VSVHJ1
# c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AudXNl
# cnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEATWNQ7Uc0SmGk295qKoyb8QAA
# Hh1iezrXMsL2s+Bjs/thAIiaG20QBwRPvrjqiXgi6w9G7PNGXkBGiRL0C3danCpB
# OvzW9Ovn9xWVM8Ohgyi33i/klPeFM4MtSkBIv5rCT0qxjyT0s4E307dksKYjallo
# UkJf/wTr4XRleQj1qZPea3FAmZa6ePG5yOLDCBaxq2NayBWAbXReSnV+pbjDbLXP
# 30p5h1zHQE1jNfYw08+1Cg4LBH+gS667o6XQhACTPlNdNKUANWlsvp8gJRANGftQ
# kGG+OY96jk32nw4e/gdREmaDJhlIlc5KycF/8zoFm/lv34h/wCOe0h5DekUxwZxN
# qfBZslkZ6GqNKQQCd3xLS81wvjqyVVp4Pry7bwMQJXcVNIr5NsxDkuS6T/Fikygl
# Vyn7URnHoSVAaoRXxrKdsbwcCtp8Z359LukoTBh+xHsxQXGaSynsCz1XUNLK3f2e
# BVHlRHjdAd6xdZgNVCT98E7j4viDvXK6yz067vBeF5Jobchh+abxKgoLpbn0nu6Y
# MgWFnuv5gynTxix9vTp3Los3QqBqgu07SqqUEKThDfgXxbZaeTMYkuO1dfih6Y4K
# JR7kHvGfWocj/5+kUZ77OYARzdu1xKeogG/lU9Tg46LC0lsa+jImLWpXcBw8pFgu
# o/NbSwfcMlnzh6cabVgxggTgMIIE3AIBATCBkDB8MQswCQYDVQQGEwJHQjEbMBkG
# A1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENvZGUg
# U2lnbmluZyBDQQIQKk+D8r3YbqOXfd/7XMeTAzANBglghkgBZQMEAgEFAKB8MBAG
# CisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCKCdEP7nKM
# cE0SatKXnvutJcqMyGlIsTP/DJcs2vmhdzANBgkqhkiG9w0BAQEFAASCAQA0Nf7J
# X4sBEEkvcLb3IDOu8LPrrkej4xIuHt8m2+q/NtdEZwcdAEB9/dKql0EEd3SK+VmB
# yNawXIAdI96leZJvWA7QC7YoVu+z0vDgBuWoxNoTWtQh/hNyYq9z0p+NxJmbtOXc
# IV4QbhWFC6JI0fEF04la9I/6kY6tc4W8MFQderBQt0hzOMA6iPlEC3rMHdqhKFpE
# rdKlrNgyG5VdCPOtK4sw5LF/xXpAmMXnafiHgUxPesakrbjwy9XKs0eDACAGk2DC
# yzdMy1jVD9sDjEbqDKjDmo3mkBMzK4T7ewjIWjrRlmz9K80RJVvZ+yQGnoMvqYrx
# pIkU3JY6fxuTbxLaoYICojCCAp4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMT
# H0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZ
# zFNBFDAJBgUrDgMCGgUAoIH9MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJ
# KoZIhvcNAQkFMQ8XDTE5MDQyMzA2MTEzMFowIwYJKoZIhvcNAQkEMRYEFPYb34+1
# //gKj6txHD0Xdm1/z9ybMIGdBgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUY7gv
# q2H1g5CWlQULACScUCkz7HkwbDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoT
# EEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1w
# aW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNBFDANBgkqhkiG9w0BAQEFAASC
# AQCUSwDu+oCy/j6eBmtcx1cTqOH14KD9rjHhPish6oSStNfFWnLBcuhElUUm9mvq
# VOaL8+Tpccjw5xw0KzBRiDO8oPJ52p3U4D0A2OQANK0kiRO2WldT0EGk5PMiHb8D
# zdy+1qDU8pyjNX4eErhzezAvqco346kRWCb5L0oibYM+9mg6l3z70KG0RK6hnhxk
# oyVUhy1FQ8Bu2P7uz5dgIdeakLTShUFHRE5yhqm4dfS5sPVRkiDg99o43GXZXu2L
# uNABPsasxh3AjyRLKToOPQrTqbK+Oaj3I+Lc4L1xq39cEMibR3uNhSHx8WvQkEY8
# eTE7/zDkuLdl9xMqcXKXaZ6p
# SIG # End signature block
