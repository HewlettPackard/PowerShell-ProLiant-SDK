####################################################################
#Directory Group setting
####################################################################

<#
.Synopsis
    This Script adds the directory groups with login privilege by default, modifies the directory settings and gets the same.

.DESCRIPTION
    This Script adds the directory groups with login privilege by default and other privileges that can be set by the user, modifies the directory settings and gets the same.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Add-HPEiLODirectoryGroup, Get-HPEiLODirectoryGroup, Get-HPEiLODirectorySetting, Set-HPEiLODirectorySettingStart-HPEiLODirectorySettingTest, Get-HPEiLODirectorySettingTestResult, Disconnect-HPEiLO, Disable-HPEiLOLog

.PARAMETER GroupName
	Specifies the Directory Group Name to be added.

.PARAMETER GroupSID
	Specifies the GroupSID for the group name.

.PARAMETER DirectoryServerAddress
	Specifies the Directory Server Address value.

.PARAMETER DirectoryServerPort
	Specifies the Directory Server Port value.

.PARAMETER UserContext
	Specifies the UserCOntext value.

.PARAMETER iLOConfigPrivilege
	Specifes whether iLO Config privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER LoginPrivilege
	Specifes whether user has login privilege or no. Valid values are "Yes", "No". Default value is "Yes".

.PARAMETER RemoteConsolePrivilege
	Specifes whether Remote Console Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER UserConfigPrivilege
	Specifes whether User Config Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER VirtualPowerAndResetPrivilege
	Specifes whether Virtual Power And Reset Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER VirtualMediaPrivilege
	Specifes whether Virtual Media Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.EXAMPLE
    
    PS C:\HPEiLOCmdlets\Samples\> .\DefaultDirectorySchemaSetting.ps1 -GroupName TesGroup -GroupSID S-1-3 -DirectoryServerAddress 10.18.10.1 -DirectoryServerPort 636 -UserContext TestSampleUser -iLOConfigPrivilege Yes -ADAdminCred (Get-Credential) -TestUserCredential (Get-Credential)
	
    This script takes the required input and creates a default directory schema settings for the given iLO's.
 
.INPUTS
	iLOInput.csv file in the script folder location having iLO IPv4 address, iLO Username and iLO Password.

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 2.1.0.0
    Date    : 04/15/2018 

.LINK
    http://www.hpe.com/servers/powershell
#>

#Command line parameters


Param(

    [Parameter(Mandatory=$true)]
    [string[]]$GroupName, 
    [string[]]$GroupSID, 
    [Parameter(Mandatory=$true)] 
    [string[]]$DirectoryServerAddress, 
    [Parameter(Mandatory=$true)] 
    [string[]]$DirectoryServerPort,
    [Parameter(Mandatory=$true)]
    [string[]]$UserContext,
    [ValidateSet("Yes","No")]
    [string[]]$iLOConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$LoginPrivilege="Yes",
    [ValidateSet("Yes","No")]
    [string[]]$RemoteConsolePrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$UserConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$VirtualPowerAndResetPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$VirtualMediaPrivilege="No",
    [Parameter(Mandatory=$true)]
    [PSCredential[]]$TestUserCredential,
    [Parameter(Mandatory=$true)]
    [PSCredential[]]$ADAdminCred

    )

try
{
    $path = Split-Path -Parent $PSCommandPath
    $path = join-Path $path "\iLOInput.csv"
    $inputcsv = Import-Csv $path
	if($inputcsv.IP.count -eq $inputcsv.Username.count -eq $inputcsv.Password.count -eq 0)
	{
		Write-Host "Provide values for IP, Username and Password columns in the iLOInput.csv file and try again."
        exit
	}

    $notNullIP = $inputcsv.IP | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullUsername = $inputcsv.Username | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullPassword = $inputcsv.Password | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
	if(-Not($notNullIP.Count -eq $notNullUsername.Count -eq $notNullPassword.Count))
	{
        Write-Host "Provide equal number of values for IP, Username and Password columns in the iLOInput.csv file and try again."
        exit
	}
}
catch
{
    Write-Host "iLOInput.csv file import failed. Please check the file path of the iLOInput.csv file and try again."
    Write-Host "iLOInput.csv file path: $path"
    exit
}

Clear-Host

# script execution started
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "This script allows user to add directory group, modify the directory settings and test the same.`n"

#Load HPEiLOCmdlets module
$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEiLOCmdlets"))
{
    Write-Host "Loading module :  HPEiLOCmdlets"
    Import-Module HPEiLOCmdlets
    if(($(Get-Module -Name "HPEiLOCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEiLOCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstallediLOModule  =  Get-Module -Name "HPEiLOCmdlets"
    Write-Host "HPEiLOCmdlets Module Version : $($InstallediLOModule.Version) is installed on your machine."
    Write-host ""
}

$Error.Clear()

#Enable logging feature
Write-Host "Enabling logging feature" -ForegroundColor Yellow
$log = Enable-HPEiLOLog
$log | fl

if($Error.Count -ne 0)
{ 
	Write-Host "`nPlease launch the PowerShell in administrator mode and run the script again." -ForegroundColor Yellow 
	Write-Host "`n****** Script execution terminated ******" -ForegroundColor Red 
	exit 
}	

try
{
	$ErrorActionPreference = "SilentlyContinue"
	$WarningPreference ="SilentlyContinue"

    [bool]$isParameterCountEQOne = $false;

    foreach ($key in $MyInvocation.BoundParameters.keys)
    {
        $count = $($MyInvocation.BoundParameters[$key]).Count
        if($count -ne 1 -and $count -ne $inputcsv.Count)
        {
            Write-Host "The input paramter value count and the input csv IP count does not match. Provide equal number of IP's and parameter values." -ForegroundColor Red    
            exit;
        }
        elseif($count -eq 1)
        {
            $isParameterCountEQOne = $true;
        }
    }
    Write-Host "`nConnecting using Connect-HPEiLO`n" -ForegroundColor Yellow
    $connection = Connect-HPEiLO -IP $inputcsv.IP -Username $inputcsv.Username -Password $inputcsv.Password -WarningAction SilentlyContinue -DisableCertificateAuthentication
    
	$Error.Clear()
	
    if($Connection -eq $null)
    {
        Write-Host "`nConnection could not be established to any target iLO.`n" -ForegroundColor Red
        $inputcsv.IP | fl
        exit;
    }

    if($Connection.count -ne $inputcsv.IP.count)
    {
        #List of IP's that could not be connected
        Write-Host "`nConnection failed for below set of targets" -ForegroundColor Red
        foreach($item in $inputcsv.IP)
        {
            if($Connection.IP -notcontains $item)
            {
                $item | fl
            }
        }

        #Prompt for user input
        $mismatchinput = Read-Host -Prompt 'Connection object count and parameter value count does not match. Do you want to continue? Enter Y to continue with script execution. Enter N to cancel.'
        if($mismatchinput -ne 'Y')
        {
            Write-Host "`n****** Script execution stopped ******" -ForegroundColor Yellow
            exit;
        }
    }

    foreach($connect in $connection)
    {

        Write-Host "`nAdding the Directory Group for $($connect.IP)" -ForegroundColor Green

        if($isParameterCountEQOne)
        {
            $appendText= " -GroupName " +$GroupName
            foreach ($key in $MyInvocation.BoundParameters.keys)
            {
               if($key -match "Privilege" -or $key -eq "GroupSID")
               {
                    $appendText +=" -"+$($key)+" "+$($MyInvocation.BoundParameters[$key])
               }
            }
        }
        else
        {
            $index = $inputcsv.IP.IndexOf($connect.IP)
            $appendText= " -GroupName " +$GroupName[$index]
            foreach ($key in $MyInvocation.BoundParameters.keys)
            {
               if($key -match "Privilege" -or $key -eq "GroupSID")
               {
                    $value = $($MyInvocation.BoundParameters[$key])
                    $appendText +=" -"+$($key)+" "+$value[$index]
               }
            }
        }
       
       
        #executing the cmdlet Add-HPEiLODirectoryGroup 
        $cmdletName = "Add-HPEiLODirectoryGroup"
        $expression = $cmdletName + " -connection $" + "connect" +$appendText
        $output = Invoke-Expression $expression

        if($output.StatusInfo -ne $null)
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to add directory group for $($output.IP): "$message -ForegroundColor Red
            if($message -contains "Feature not supported.")
            { continue; }
        }

        Write-Host "`nGetting the directory info for $($connect.IP)" -ForegroundColor Green
        $output = Get-HPEiLODirectoryGroup -Connection $connect
       
        #displaying Directory Group information

        if($output.Status -ne "OK")
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to add directory group for $($output.IP): "$message -ForegroundColor Red
        }
        else
        {  $output.GroupAccountInfo | Out-String }

        #getting the user context index where the User context has to be added for all the given iLO's
        $output = Get-HPEiLODirectorySetting -Connection $connect

        if($output.Status -eq "OK")
        {
            $output.UserContextInfo | ForEach-Object{ 
        
            if([string]::IsNullOrEmpty($_.UserContext)) 
            {
                $userContextIndex = $_.UserContextIndex 
                return
            } }
        }
        else
        {
            $userContextIndex += 1
        }

        #modifying directory settings.
        Write-Host "`nSetting the directory settings for $($connect.IP)." -ForegroundColor green
        if($isParameterCountEQOne)
        {
            $output = Set-HPEiLODirectorySetting -Connection $connect -LDAPDirectoryAuthentication DirectoryDefaultSchema -DirectoryServerAddress $DirectoryServerAddress -DirectoryServerPort $DirectoryServerPort -UserContextIndex $userContextIndex -UserContext $UserContext 
        }
        else
        {
            $output = Set-HPEiLODirectorySetting -Connection $connect -LDAPDirectoryAuthentication DirectoryDefaultSchema -DirectoryServerAddress $DirectoryServerAddress[$index] -DirectoryServerPort $DirectoryServerPort[$index] -UserContextIndex $userContextIndex -UserContext $UserContext[$index]
        }

        if($output.StatusInfo -ne $null)
        {  
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to set directory info for $($output.IP): "$message -ForegroundColor Red 
                
        }
     
         Write-Host "`nGetting the directory settings for $($connect.IP)" -ForegroundColor green
         $output = Get-HPEiLODirectorySetting -Connection $connect


        if($output.Status -eq "OK")
        {
            $directorySettingInfo = New-Object PSObject  
                                      
            $output.PSObject.Properties | ForEach-Object {
            if($_.Value -ne $null -and $_.Name -ne "UserContextInfo"){ $directorySettingInfo | add-member Noteproperty $_.Name  $_.Value}
            }

            $directorySettingInfo | out-String

            $output.UserContextInfo | out-string
        }
        else
        {
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to get Directory Group information for $($output.IP): "$message -ForegroundColor Red 
        }
        
        #Executing Directory Test commands 
        Write-Host "`nInvoking Directory test for $($connect.IP)." -ForegroundColor Green
        if($isParameterCountEQOne)
        {
           $output = Start-HPEiLODirectorySettingTest -Connection $connect -ADAdminCredential $ADAdminCred -TestUserCredential $TestUserCredential
        }
        else
        {
           $output = Start-HPEiLODirectorySettingTest -Connection $connect -ADAdminCredential $ADAdminCred[$index] -TestUserCredential $TestUserCredential[$index]
        }

        Write-Host "`nGetting directory test result for $($connect.IP)." -ForegroundColor Green
        $result = Get-HPEiLODirectorySettingTestResult -Connection $connect

        if($result.Status -eq "OK")
        {
            Write-Host "`nDirectory test results for $($result.IP)" -ForegroundColor Green
            $result.DirectoryTestResult | Out-String                     
                    
        }
        else
        {
            $message = $result.StatusInfo.Message; 
            Write-Host "`nFailed to get Directory test results for $($result.IP): "$message -ForegroundColor Red 
        }
    }
    
 }
 catch
 {  
 }
finally
{
    if($connection -ne $null)
    {
        #Disconnect 
		Write-Host "Disconnect using Disconnect-HPEiLO `n" -ForegroundColor Yellow
		$disconnect = Disconnect-HPEiLO -Connection $Connection
		$disconnect | fl
		Write-Host "All connections disconnected successfully.`n"
    }  
	
	#Disable logging feature
	Write-Host "Disabling logging feature`n" -ForegroundColor Yellow
	$log = Disable-HPEiLOLog
	$log | fl
	
	if($Error.Count -ne 0 )
    {
        Write-Host "`nScript executed with few errors. Check the log files for more information.`n" -ForegroundColor Red
    }
	
    Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
}