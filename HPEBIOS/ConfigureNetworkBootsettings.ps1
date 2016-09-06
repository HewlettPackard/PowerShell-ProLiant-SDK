########################################################
#Configure Network Settings
###################################################----#

<#
.Synopsis
    This script allows user to configure network settings of HPE Proliant Gen 9 servers

.DESCRIPTION
    This script allows user to configure network settings of HPE Proliant Gen 9 servers.
    This script  allows to change the DHCPv4 to enabled or disabled. When DHCPv4 value is set to disabled then it prompts the user to enter 
    IPV4Address, IPV4Gateway and other settings.

.EXAMPLE
     ConfigureNetworkBootsettings.ps1
     This mode of execution of script will prompt for 
     Address :- accpet IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
     Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
     DHCPv4 :- it will prompt to eneter DHCPv4 value to set. User can enter "Enabled" or "Disabled".If the DHCPv4 value is Disabled then the
     user will be prompted to enter the IPV4 settings.

.EXAMPLE
    ConfigureNetworkBootsettings.ps1 -Address "10.20.30.40,10.25.35.45" -DHCPv4 "Enabled"

    This mode of script have input parameter for Address and DHCPv4
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -DHCPv4 :- Use this Parameter to specify DHCPv4. Supported values are "Enabled" or "Disabled".

    This script execution will prompt user to enter user credentials. It is recommended for this script to use same credential for multiple servers.
.EXAMPLE

    ConfigureNetworkBootsettings.ps1 -Address "10.20.30.40" -Credential $UserCredential -IPV4Address "10.20.11.12" -IPV4SubnetMask "255.255.255.0" -IPV4Gateway "10.20.12.1" -IPV4PrimaryDNS "10.20.11.12" -IPV4SecondaryDNS "11.15.12.1"
     
    This mode of script have input parameter for Address and DHCPv4
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :-  to specify server credential
    -IPV4Address :- Use this Parameter to specify static IPV4Address. 
    -IPV4SubnetMask :-Use this Parameter to specify static IPv4 subnet mask.
    -IPV4Gateway :-Use this Parameter to specify static IPv4 gateway.
    -IPV4PrimaryDNS :-Use this Parameter to specify IPv4 primary DNS.
    -IPV4SecondaryDNS :-Use this Parameter to specify IPv4 secondary DNS.
    
.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 1.1.0.0
    Date    : 8/8/2016
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    DHCPv4

.OUTPUTS
    None (by default)

.LINK
.LINK    
    http://www8.hp.com/in/en/products/server-software/product-detail.html?oid=5440657
#>



#Command line parameters
Param
(
        [string]$Address, 
        [PSCredential]$Credential,
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

#Load HPBIOSCmdlets module
    <#Write-Host "Checking HPBIOSCmdlets module"
    Write-Host ""#>

$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPBIOSCmdlets"))
{
    Write-Host "Loading module :  HPBIOSCmdlets"
    Import-Module HPBIOSCmdlets
    if(($(Get-Module -Name "HPBIOSCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPBIOSCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstalledBiosModule  =  Get-Module -Name "HPBIOSCmdlets"
    Write-Host "HPBIOSCmdlets Module Version : $($InstalledBiosModule.Version) is installed on your machine."
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
    $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential

    #Retry connection if it is failed because of invalid certificate with -DisableCertificateAuthentication switch parameter
    if($Error[0] -match "iLO SSL Certificate is not valid")
    {
       $connection = Connect-HPBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication
    } 

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        $connection
        if($connection.ConnectionInfo.ServerPlatformNumber -eq 9)
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "Network Boot Settings is not supported on Server $($connection.IP)"
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
        $result = $ListOfConnection[$i]| Get-HPBIOSNetworkBootOption
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
            $resultList = $DHCPDisabledConnectionList | Set-HPBIOSNetworkBootOption -DHCPv4 Disabled -IPv4Address $IPV4Address -IPv4SubnetMask $IPV4SubnetMask -IPv4Gateway $IPV4Gateway -IPv4PrimaryDNS $IPV4PrimaryDNS -IPv4SecondaryDNS $IPV4SecondaryDNS
        }
        if($DHCPEnabledConnectionList.Count -gt 0)
        {
            $resultList = $DHCPEnabledConnectionList | Set-HPBIOSNetworkBootOption -DHCPv4 Enabled
        }
    }
    else
    {
        if($IPV4Address -ne "" -and $IPV4SubnetMask -ne "" -and $IPV4Gateway -ne "" -and $IPV4PrimaryDNS -ne "" -and $IPV4SecondaryDNS -ne "")
        {
            $resultList = $ListOfConnection[0] | Set-HPBIOSNetworkBootOption -DHCPv4 $DHCPToset[0] -IPv4Address $IPV4AddressList[0] -IPv4SubnetMask $IPV4SubnetMaskList[0] -IPv4Gateway $IPV4GatewayList[0] -IPv4PrimaryDNS $IPV4PrimaryDNSList[0] -IPv4SecondaryDNS $IPV4SecondaryDNSList[0]
        }
        else
        {
            $resultList = $ListOfConnection[0] | Set-HPBIOSNetworkBootOption -DHCPv4 $DHCPToset[0]
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
		$result = $ListOfConnection[$i]| Get-HPBIOSNetworkBootOption
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
Disconnect-HPBIOSAllConnection    
$ErrorActionPreference = "Continue"
Write-Host "******Script execution completed******" -ForegroundColor Green
exit

}



