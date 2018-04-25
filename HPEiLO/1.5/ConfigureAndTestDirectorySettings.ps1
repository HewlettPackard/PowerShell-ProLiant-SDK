<#
.Synopsis
    This script allows user to get the directory settings, change some of the directory settings and test/verify the directory settings.

.DESCRIPTION
    This script allows user to get the current directory settings, change some of the directory settings and test them.
     LDAPDirectoryAuthentication- Use this option to enable or disable the LDAP Directory Authentication
     ServerAddress - Use this option to set the Directory server address
     ServerPort - Use this option to set the directory server port
     LOMObject- Use this option to set the LOM Object distinguished Name
     ADAdminCred - This is the Directory Administrator Distinguished name to run the Directory test
     TestUSerCredential - This is test user credentials to run the Directory test

.EXAMPLE
    ConfigureAndTestDirectorySettings.ps1
    This mode of execution of script will prompt for 
    Address    :- accpet IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    Credential :- prompts for username and password. In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials
    LDAPDirectoryAuthentication- allows you to disable or enable directory authentication.Possible values are Disable,Use_Directory_Default_Schema,Use_HP_Extended_Schema
    ServerAddress - allows to set the Directory server address
    ServerPort - allows to set the directory server port
    LOMObject- allows to set the LOM Object distinguished Name
    ADAdminCred - This is the Directory Administrator Distinguished name to run the Directory test
    TestUSerCredential - This is test user credentials to run the Directory test

.EXAMPLE
    ConfigureAndTestDirectorySettings.ps1 -Address "10.20.30.40,10.20.30.40.1" -Credential $Credential -ADAdminCred $ADAdminCred -TestUserCredential $TestUserCredential -LDAPDirectoryAuthentication $Auth -ServerAddress $ServerAddress -ServerPort $ServerPort -LOMObject $LOMObject

    This mode of script have input parameter for Address,Username, Password and location
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    -Credential :- prompts for username and password. In case of multiple iLO IP(s) or Hostname(s) it is recommended to use same user credentials
    -LDAPDirectoryAuthentication- Use this option to enable or disable the LDAP Directory Authentication
    -ServerAddress - Use this option to set the Directory server address
    -ServerPort - Use this option to set the directory server port
    -LOMObject- Use this option to set the LOM Object distinguished Name
    -ADAdminCred - This is the Directory Administrator Distinguished name to run the Directory test
    -TestUSerCredential - This is test user credentials to run the Directory test

.NOTES
    Company : Hewlett Packard Enterprise
    Version : 1.4.0.0

    
.INPUTS
    Inputs to this script file
    Address
    Username
    Password
    Location

'
l.OUTPUTS
    None (by default)

.LINK
    
    http://www.hpe.com/servers/powershell
#>

#Command line parameters
Param(
    [string]$Address,   # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [PSCredential]$Credential, # all server should have same ceredntial (in case of multiple addresses)
    [PSCredential]$TestUserCredential,
    [PSCredential]$ADAdminCred,
    [string]$LDAPDirectoryAuth,
    [string]$ServerAddress,
    [string]$ServerPort,
    [string]$LOMObject  
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
         $PingedServerList += $serverAddress
       }
       else
       {
        Write-Host "`nServer $serverAddress is not reachable. Please check network connectivity"
        $pingFailureCount ++
       }
}

if($pingFailureCount -eq $ListOfAddress.Count)
{
    Write-Host "`nServer(s) are not reachable please check network conectivity"
    exit
}
return $PingedServerList
}
#clear host
Clear-Host

# script execution started
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "This script allows user to change the directory settings and test the seettings that is made.`n"

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference ="SilentlyContinue"

#check powershell support
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "3")
{
    Write-Host "Your powershell version : $($PSVersionTable.PSVersion) is valid to execute this script`n"
}
else
{
    Write-Host "This script required PowerSehll 3 or above"
    Write-Host "Current installed PowerShell version is $($PSVersionTable.PSVersion)"
    Write-Host "Please Update PowerShell version`n"
    Write-Host "Exit...`n"
    exit
}

#Load HPiLOCmdlets module

$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPiLOCmdlets"))
{
    Write-Host "Loading module :  HPiLOCmdlets"
    Import-Module HPiLOCmdlets
    if(($(Get-Module -Name "HPiLOCmdlets")  -eq $null))
    {
        Write-Host "`nHPiLOCmdlets module cannot be loaded. Please fix the problem and try again`n"
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstallediLOModule  =  Get-Module -Name "HPiLOCmdlets"
    Write-Host "HPiLOCmdlets Module Version : $($InstallediLOModule.Version) is installed on your machine.`n"
}

# check for IP(s) or Hostname(s) Input. if not available prompt for Input
if($Address -eq "")
{
    $Address = Read-Host "`nEnter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}
    
[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "`nYou have not entered IP(s) or Hostname(s)`n"
    Write-Host "Exit..."
    exit
}

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password(Use same credential for multiple servers)"
}

#  Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

for($i=0;$i -lt $ListOfAddress.Count ;$i++)
{
    Write-Host("`nGetting Directory Settings for the server {0}" -f $ListOfAddress[$i]) -ForegroundColor Green
    $result = Get-HPiLODirectory -Server $ListOfAddress[$i] -Credential $Credential -DisableCertificateAuthentication       
    $tmpObj =New-Object PSObject
    $tmpObj | Add-Member NoteProperty "IP" $result.IP
    $tmpObj | Add-Member NoteProperty "HOSTNAME" $result.HOSTNAME
    $tmpObj | Add-Member NoteProperty "STATUS_TYPE" $result.STATUS_TYPE
    $tmpObj | Add-Member NoteProperty "STATUS_MESSAGE" $result.STATUS_MESSAGE
    $tmpObj | Add-Member NoteProperty "DIR_AUTHENTICATION_ENABLED" $result.DIR_AUTHENTICATION_ENABLED
    $tmpObj | Add-Member NoteProperty "DIR_OBJECT_DN" $result.DIR_OBJECT_DN
    $tmpObj | Add-Member NoteProperty "DIR_SERVER_ADDRESS" $result.DIR_SERVER_ADDRESS
    $tmpObj | Add-Member NoteProperty "DIR_SERVER_PORT" $result.DIR_SERVER_PORT
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_1" $result.DIR_USER_CONTEXT_1
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_2" $result.DIR_USER_CONTEXT_2
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_3" $result.DIR_USER_CONTEXT_3
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_4" $result.DIR_USER_CONTEXT_4
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_5" $result.DIR_USER_CONTEXT_5
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_6" $result.DIR_USER_CONTEXT_6
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_7" $result.DIR_USER_CONTEXT_7
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_8" $result.DIR_USER_CONTEXT_8
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_9" $result.DIR_USER_CONTEXT_9
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_10" $result.DIR_USER_CONTEXT_10
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_11" $result.DIR_USER_CONTEXT_11
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_12" $result.DIR_USER_CONTEXT_12
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_13" $result.DIR_USER_CONTEXT_13
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_14" $result.DIR_USER_CONTEXT_14
    $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_15" $result.DIR_USER_CONTEXT_15
    $tmpObj
}

$parameterMetaData = $(Get-Command -Name Set-HPiLODirectory).Parameters
$LDAPValidValues = $($parameterMetaData["LDAPDirectoryAuthentication"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
if($LDAPDirectoryAuth -eq "")
{
    $LDAPDirectoryAuth = Read-Host "`nEnter LDAP Directory Authentication value [Accepted values : ($($LDAPValidValues -join ","))]."
}

#$inputList =  ($LDAPDirectoryAuth.Trim().Split(','))

if($ServerAddress -eq "")
{
    $ServerAddress = Read-Host "`nEnter Directory Server Address"
}

if($ServerPort -eq "")
{
    $ServerPort = Read-Host "`nEnter Directory Server LDAP Port number"
}
if($LOMObject -eq "")
{
   $LOMObject = Read-Host "`nEnter LOM Object Distinguished name if any" 
}
$UserContextValue=Read-Host "`nDo you want to set UserContext values?(Y/N)"
if($UserContextValue -eq "Y")
{
    Write-Host "`nInput Hint : For multiple server please enter parameter values seprated by comma(|)" -ForegroundColor Yellow
    $UserContext1 = Read-Host "`nEnter UserContext1 value"
    $UserContext2 = Read-Host "`nEnter UserContext2 value"
}

Write-Host "`nChanging the directory settings" -ForegroundColor Green

$failureCount = 0
$inputAuthList=($LDAPDirectoryAuth.Trim().Split(','))
$inputServerAddressList=($ServerAddress.Trim().Split(','))
$inputServerPort=($ServerPort.Trim().Split(','))
$inputLOMObject=($LOMObject.Trim().Split(','))
$inputUserContext1=($UserContext1.Trim().Split('|'))
$inputUserContext2=($UserContext2.Trim().Split('|'))

for($i=0;$i -lt $ListOfAddress.Count;$i++)
{
    if($inputUserContext1[$i] -ne "" -and $inputUserContext2[$i] -ne "")
    {
        $result= Set-HPiloDirectory -Server $ListofAddress[$i] -Credential $Credential -LDAPDirectoryAuthentication $inputAuthList[$i] -ServerAddress $inputServerAddressList[$i] -ServerPort $inputServerPort[$i] -UserContext1 $inputUserContext1[$i] -UserContext2 $inputUserContext2[$i] -ObjectDN $inputLOMObject[$i] -DisableCertificateAuthentication
    }
    else
    {
        $result= Set-HPiloDirectory -Server $ListofAddress[$i] -Credential $Credential -LDAPDirectoryAuthentication $inputAuthList[$i] -ServerAddress $inputServerAddressList[$i] -ServerPort $inputServerPort[$i] -ObjectDN $inputLOMObject[$i] -DisableCertificateAuthentication
    }

    if($result.STATUS_TYPE -eq "Error")
    {
        Write-Host "`nFailed to change the Directory settings"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.STATUS_MESSAGE)"
        $failureCount++
    }
    else
    {
        Write-host "`nSuccessfully changed the directory settings" -ForegroundColor Green
    }
}

if($failureCount -ne $ListOfAddress.Count)
{
    for($i=0;$i -lt $ListOfAddress.Count;$i++)
    {
        Write-Host("`nGetting Directory Settings for the server {0}" -f $ListOfAddress[$i]) -ForegroundColor Green
        $result= Get-HPiLODirectory -Server $ListOfAddress[$i] -Credential $Credential -DisableCertificateAuthentication
        $tmpObj =New-Object PSObject
        $tmpObj | Add-Member NoteProperty "IP" $result.IP
        $tmpObj | Add-Member NoteProperty "HOSTNAME" $result.HOSTNAME
        $tmpObj | Add-Member NoteProperty "STATUS_TYPE" $result.STATUS_TYPE
        $tmpObj | Add-Member NoteProperty "STATUS_MESSAGE" $result.STATUS_MESSAGE
        $tmpObj | Add-Member NoteProperty "DIR_AUTHENTICATION_ENABLED" $result.DIR_AUTHENTICATION_ENABLED
        $tmpObj | Add-Member NoteProperty "DIR_OBJECT_DN" $result.DIR_OBJECT_DN
        $tmpObj | Add-Member NoteProperty "DIR_SERVER_ADDRESS" $result.DIR_SERVER_ADDRESS
        $tmpObj | Add-Member NoteProperty "DIR_SERVER_PORT" $result.DIR_SERVER_PORT
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_1" $result.DIR_USER_CONTEXT_1
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_2" $result.DIR_USER_CONTEXT_2
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_3" $result.DIR_USER_CONTEXT_3
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_4" $result.DIR_USER_CONTEXT_4
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_5" $result.DIR_USER_CONTEXT_5
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_6" $result.DIR_USER_CONTEXT_6
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_7" $result.DIR_USER_CONTEXT_7
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_8" $result.DIR_USER_CONTEXT_8
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_9" $result.DIR_USER_CONTEXT_9
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_10" $result.DIR_USER_CONTEXT_10
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_11" $result.DIR_USER_CONTEXT_11
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_12" $result.DIR_USER_CONTEXT_12
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_13" $result.DIR_USER_CONTEXT_13
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_14" $result.DIR_USER_CONTEXT_14
        $tmpObj | Add-Member NoteProperty "DIR_USER_CONTEXT_15" $result.DIR_USER_CONTEXT_15
        $tmpObj
    }
}
Write-Host "`nTesting Directory Settings...." -ForegroundColor Green

if($ADAdminCred -eq $null)
{
    $ADAdminCred = Get-Credential -Message "Enter ActiveDirectory Admin username and Password(Use same credential for multiple servers)"
}
if($TestUserCredential -eq $null)
{
    $TestUserCredential =Get-Credential -Message "Enter TestUser username and Password(Use same credential for multiple servers)"
}
for($i=0;$i -lt $ListOfAddress.Count;$i++)
{
    
    $result= Test-HPiLODirectoryUserAuthentication -Server $ListOfAddress[$i] -Credential $Credential -ActiveDirectoryAdminCredential $ADAdminCred -TestUserCredential $TestUserCred -DisableCertificateAuthentication
     
    if($result.STATUS_TYPE -eq "Error" -or $result.STATUS_TYPE -eq "Warning")
    {
        Write-Host "`nFailed to Test the Directory settings"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.STATUS_MESSAGE)"
        $failureCount++
    }
    else
    {
        $tmpObj = New-Object PSObject
        if($result.TEST_DIR_RESULTS -ne $null)
        {
            Write-Host "`nDirectory Test Results" -ForegroundColor Green

            $tmpObj | Add-Member NoteProperty "IP" $result.IP
            $tmpObj | Add-Member NoteProperty "HOSTNAME" $result.HOSTNAME
            $tmpObj | Add-Member NoteProperty "STATUS_TYPE" $result.STATUS_TYPE
            $tmpObj | Add-Member NoteProperty "STATUS_MESSAGE" $result.STATUS_MESSAGE

            $NotePropertyValue=$result.TEST_DIR_RESULTS.BIND_TO_DIRECTORY_SERVER.STATUS+"."+$result.TEST_DIR_RESULTS.BIND_TO_DIRECTORY_SERVER.DESCRIPTION
            $tmpObj | Add-Member NoteProperty "BIND_TO_DIRECTORY_SERVER" $NotePropertyValue

            $NotePropertyValue = $result.TEST_DIR_RESULTS.CONNECT_TO_DIRECTORY_SERVER.STATUS +"."+$result.TEST_DIR_RESULTS.CONNECT_TO_DIRECTORY_SERVER.DESCRIPTION
            $tmpObj | Add-Member NoteProperty "CONNECT_TO_DIRECTORY_SERVER" $NotePropertyValue
            
            $NotePropertyValue =$result.TEST_DIR_RESULTS.CONNECT_USING_SSL.STATUS+"."+$result.TEST_DIR_RESULTS.CONNECT_USING_SSL.DESCRIPTION
            $tmpObj | Add-Member NoteProperty "CONNECT_USING_SSL" $NotePropertyValue
            
            $NotePropertyValue=$result.TEST_DIR_RESULTS.DIRECTORY_ADMINISTRATOR_LOGIN.STATUS+"."+$result.TEST_DIR_RESULTS.DIRECTORY_ADMINISTRATOR_LOGIN.DESCRIPTION
            $tmpObj | Add-Member NoteProperty "DIRECTORY_ADMINISTRATOR_LOGIN" $NotePropertyValue
            
            $NotePropertyValue=$result.TEST_DIR_RESULTS.DIRECTORY_SERVER_DNS_NAME.STATUS+"."+$result.TEST_DIR_RESULTS.DIRECTORY_SERVER_DNS_NAME.DESCRIPTION
            $tmpObj | Add-Member NoteProperty "DIRECTORY_SERVER_DNS_NAME" $NotePropertyValue
            
            $NotePropertyValue=$result.TEST_DIR_RESULTS.DIRECTORY_USER_CONTEXTS.STATUS+"."+$result.TEST_DIR_RESULTS.DIRECTORY_USER_CONTEXTS.DESCRIPTION
            $tmpObj | Add-Member NoteProperty "DIRECTORY_USER_CONTEXTS" $NotePropertyValue
            
            $NotePropertyValue=$result.TEST_DIR_RESULTS.LOM_OBJECT_EXISTS.STATUS+"."+$result.TEST_DIR_RESULTS.LOM_OBJECT_EXISTS.DESCRIPTION
            $tmpObj | Add-Member NoteProperty "LOM_OBJECT_EXISTS" $NotePropertyValue
            
            $NotePropertyValue=$result.TEST_DIR_RESULTS.PING_DIRECTORY_SERVER.STATUS+"."+$result.TEST_DIR_RESULTS.PING_DIRECTORY_SERVER.DESCRIPTION
            $tmpObj | Add-Member NoteProperty "PING_DIRECTORY_SERVER" $NotePropertyValue
            
            $NotePropertyValue=$result.TEST_DIR_RESULTS.USER_AUTHENTICATION.STATUS+"."+$result.TEST_DIR_RESULTS.USER_AUTHENTICATION.DESCRIPTION
            $tmpObj | Add-Member NoteProperty "USER_AUTHENTICATION" $NotePropertyValue

            $tmpObj | FL
      }   
      else
      {
        Write-Host("`nFailed to run the test for the server{0}" -f $ListOfAddress[$i]) -ForegroundColor Yellow
      } 
      
    }
}
$ErrorActionPreference = "Continue"
$WarningPreference ="Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit