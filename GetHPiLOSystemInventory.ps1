## -------------------------------------------------------------------------------------------------------------
##      Description: Inventory of server
##
## DISCLAIMER
## The sample scripts are not supported under any HP standard support program or service.
## The sample scripts are provided AS IS without warranty of any kind. 
## HP further disclaims all implied warranties including, without limitation, any implied 
## warranties of merchantability or of fitness for a particular purpose. 
##
##    
## Scenario
##     	Use HPiLOCmdlets to collect information about servers
##
## Reference
##     https://www.hpe.com/us/en/product-catalog/detail/pip.5440657.html
##		
##
## Input parameters:
##
##       InputiLOCSV -> Path to the Input CSV file containing iLO IP, Username and Password   
##       OutputCSV    -> Path of Output csv file. Path should contain filename with .csv extension
##       iLOIP        -> Parameter to give iLO IP via command line
##       iLOUsername  -> Parameter to give iLO Username via command line
##       iLOPassword  -> Parameter to give iLO Password via command line
##
##       Option 1: Specify InputiLOCSV
##                 Specify list of iLO IP addresses along with Username and Password in a CSV file.
##                 Format is :  IP,Username,Password
##                 Parameter OutputCSV is optional. If it is not specified, output file is created in the current directory.
##                 
##
##       Option 2: Specify iLOIP, iLOUsername and iLOPassword
##       Parameter OutputCSV is optional. If it is not specified, output file is created in the current directory. 
##
## Prerequisites
##     	 Microsoft .NET Framework 4.5
##       HPiLOCmdlets latest (1.4.0.x) - http://h20566.www2.hpe.com/hpsc/swd/public/readIndex?sp4ts.oid=1008862655&lang=en&cc=us
##	     Powershell Version 4.0 and above
##       Prepare a CSV file with following fields (Optional) - IP, Username, Password
##
## Platform tested
##        Gen8 and Gen9 servers
##
## -------------------------------------------------------------------------------------------------------------


    <#
  .SYNOPSIS
    Performs an inventory of server Hardware components.  
  
  .DESCRIPTION
    Performs an inventory of server hardware components using HPiLOCmdlets. There are two ways to supply the input. Either the parameters InputiLOCSV and OutputCSV should be given or, iLOIP, iLOUsername and iLOPassword should be specified.
    This works on G8 and Gen 9 servers. 
        
  .EXAMPLE
    PS C:\> .\GetHPiLOSystemInventory.ps1 -InputiLOCSV C:\Users\admin\Desktop\JIO\iloserver.csv -OutputCSV C:\output.csv
            Output file path -> C:\output.csv

    In this example, path of the input CSV file is speecified for "InputiLOCSV" and path of output CSV file is given for "OutputCSV"

  .EXAMPLE        
    PS C:\> .\GetHPiLOSystemInventory.ps1 -iLOIP 192.168.10.12 -iLOUsername admin -iLOPassword admin123 
            Output file path -> C:\SystemInventory_13Jul2017.csv

    In this example, iLO Ip address, it's username and password are specified.

  .EXAMPLE        
    PS C:\> .\GetHPiLOSystemInventory.ps1 -iLOIP 192.168.10.12 -iLOUsername admin -iLOPassword admin123 
            Output file path -> C:\SystemInventory_13Jul2017.csv

    In this example, a range is specified for IP along with username and password.

  .PARAMETER InputiLOCSV
    Name of the CSV file containing iLO IP Address, ILO Username and iLO Password.
    The format is: IP,Username,Password

  .PARAMETER OutputCSV
    Path of Output CSV file. Path should contain filename with .csv extension.
    If this parameter is not specified, then output file will be created in the current working directory.

  .PARAMETER iLOIP
    IP address of the ILO. A range of iLO IPs and multiple IPS can also be provided. 
    Example1 - 30.40.50.60
    Example2 - 30.40.50.1-50
    Example3 - 30.40.50.1,30.40.50.2,30.40.50.3

  .PARAMETER iLOUsername
    Specifies the single username for all the iLOs or a list of usernames for each iLO in the input iLO list.

  .PARAMETER iLOPassword
    Specifies the single password for all the iLOs or a list of passwords for each iLO in the input iLO list.

  .PARAMETER DisableCertificateAuthentication
    If this switch parameter is present then server certificate authentication is disabled for the execution of this cmdlet. If not present it will execute according to the 
    global certificate authentication setting. The default is to authenticate server certificates.

  .Notes
   
  .Link
    http://www.hpe.com/servers/powershell

 #>

    [CmdletBinding(DefaultParametersetName="CSVInput")] 
    Param (

    [Parameter(ParameterSetName="CSVInput")]
        [string]$InputiLOCSV ="",

    [Parameter(ParameterSetName="CSVInput")]
    [Parameter(ParameterSetName="CommandLine")]
        [string]$OutputCSV ="",

    [Parameter(ParameterSetName="CommandLine")]
        [Array]$iLOIP        = "",

    [Parameter(ParameterSetName="CommandLine",Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [Array]$iLOUsername = "",

    [Parameter(ParameterSetName="CommandLine",Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [Array]$iLOPassword  = "",

    [Parameter(Mandatory=$false)]
    [switch] $DisableCertificateAuthentication

    )

    ## -------------------------------------------------------------------------------------------------------------
    ##                     FUNTION TO RETRIEVE IPs WHICH HAVE A VALID CERTIFICATE   
    ## -------------------------------------------------------------------------------------------------------------
    function Get-ValidIPs{
        
        Param (
            [Array]$IPs,
            [Array]$Usernames,
            [Array]$Passwords
        )
        Write-Verbose "Validating certificates for the given IPs."
        $ReturnArray = @{}
        for($i=0; $i -lt $IPs.Count; $i++)
        {
            $Error.Clear()
            if(($IPs.Count -ne 1) -and (($Usernames.Count -ne 1) -and ($Passwords.Count -ne 1)))
            {
                if(-not $DisableCertificateAuthentication)
                {
                    $AssetOutputs = Get-HPiLOAssetTag -Server $IPs[$i] -Username $Usernames[$i] -Password $Passwords[$i] -ErrorAction SilentlyContinue
                }
                else
                {
                    $AssetOutputs = Get-HPiLOAssetTag -Server $IPs[$i] -Username $Usernames[$i] -Password $Passwords[$i] -DisableCertificateAuthentication -ErrorAction SilentlyContinue
                }
                if($Error.Count -eq 0)
                {
                    [Array]$ReturnArray.IPs += $IPs[$i]
                    [Array]$ReturnArray.Usernames += $Usernames[$i]
                    [Array]$ReturnArray.Passwords += $Passwords[$i]                     
                }
                else
                {
                    $WarningVariable = $IPs[$i]
                    $WarningVariable += " Skipped due to Invalid Certificate."
                    Write-Warning $WarningVariable
                }
            }
            else
            {
                if(-not $DisableCertificateAuthentication)
                {
                    $AssetOutputs = Get-HPiLOAssetTag -Server $IPs[$i] -Username $Usernames -Password $Passwords -ErrorAction SilentlyContinue
                }
                else
                {
                    $AssetOutputs = Get-HPiLOAssetTag -Server $IPs[$i] -Username $Usernames -Password $Passwords -DisableCertificateAuthentication -ErrorAction SilentlyContinue
                }
                if($Error.Count -eq 0)
                {
                    [Array]$ReturnArray.IPs += $IPs[$i]
                    [Array]$ReturnArray.Usernames += $Usernames
                    [Array]$ReturnArray.Passwords += $Passwords                     
                }
                else
                {
                    $WarningVariable = $IPs[$i]
                    $WarningVariable += " Skipped due to Invalid Certificate."
                    Write-Warning $WarningVariable
                }
            }
        }
        return $ReturnArray
    }

    #called from Find-HPiLO, a helper function to check whether input IPv4 is valid or not
    #returns the total number of "." in an IPv4 address
    #for example: if input $strIP is "1...1", the return value is 3
    function Get-IPv4-Dot-Num{
        param (
            [parameter(Mandatory=$true)] [String] $strIP
        )
        [int]$dotnum = 0
        for($i=0;$i -lt $strIP.Length; $i++)
        {
            if($strIP[$i] -eq '.')
            {
                $dotnum++
            }
        }
    
        return $dotnum
    }

    ## -------------------------------------------------------------------------------------------------------------
    ##                     FUNTION TO RETRIEVE SYSTEM INVENTORY DATA USING iLO CMDLETS
    ##               Find-HPiLO, Get-HPiLOHealthSummary,Get-HPiLOERSSetting, Get-HPiLOFirmwareInfo  
    ## -------------------------------------------------------------------------------------------------------------
    Function GetData
    {
        Param (
            [Array]$iLOIP,
            [Array]$iLOUsername,
            [Array]$iLOPassword,
            [switch]$DisableCertificateAuthentication 
        )

        #Header for the output csv file
    
        $Header = "iLOIP,Server S/N,Model,System Health,Power Supply,Power Supply Status,IRS Register,iLO FW,System ROM,Smart Array,Dynamic Smart Array,Smart HBA,HP Ethernet Adapter,Intelligent Platform Abstraction Data,Power Management Controller Firmware,Power Management Controller FW Bootloader,SAS Programmable Logic Device,Server Platform Services (SPS) Firmware,System Programmable Logic Device,Redundant System ROM,TPM Firmware"
        $HeaderArray = @(
                        "iLO","System ROM", "Smart Array",
                        "Dynamic Smart Array","Smart HBA","HP Ethernet","Intelligent Platform Abstraction Data",
                        "Power Management Controller Firmware","Power Management Controller FW Bootloader",
                        "SAS Programmable Logic Device","Server Platform Services (SPS) Firmware",
                        "System Programmable Logic Device","Redundant System ROM","TPM Firmware"

                        )
        Set-content -Path $script:SystemInventoryFile -Value $Header
        $ipv6_one_section="[0-9A-Fa-f]{1,4}"
        $ipv6_one_section_phen="$ipv6_one_section(-$ipv6_one_section)?"
	    $ipv6_one_section_phen_comma="$ipv6_one_section_phen(,$ipv6_one_section_phen)*"

        $ipv4_one_section="(2[0-4]\d|25[0-5]|[01]?\d\d?)"
	    $ipv4_one_section_phen="$ipv4_one_section(-$ipv4_one_section)?"
	    $ipv4_one_section_phen_comma="$ipv4_one_section_phen(,$ipv4_one_section_phen)*"

        $ipv4_regex_inipv6="${ipv4_one_section_phen_comma}(\.${ipv4_one_section_phen_comma}){3}"  
        $ipv4_one_section_phen_comma_dot_findhpilo="(\.\.|\.|${ipv4_one_section_phen_comma}|\.${ipv4_one_section_phen_comma}|${ipv4_one_section_phen_comma}\.)"

        $port_regex = ":([1-9]|[1-9]\d|[1-9]\d{2}|[1-9]\d{3}|[1-5]\d{4}|6[0-4]\d{3}|65[0-4]\d{2}|655[0-2]\d|6553[0-5])"
	    $ipv6_regex_findhpilo="^\s*(${ipv4_regex_inipv6}|${ipv6_one_section_phen_comma}|((${ipv6_one_section_phen_comma}:){1,7}(${ipv6_one_section_phen_comma}|:))|((${ipv6_one_section_phen_comma}:){1,6}(:${ipv6_one_section_phen_comma}|${ipv4_regex_inipv6}|:))|((${ipv6_one_section_phen_comma}:){1,5}(((:${ipv6_one_section_phen_comma}){1,2})|:${ipv4_regex_inipv6}|:))|((${ipv6_one_section_phen_comma}:){1,4}(((:${ipv6_one_section_phen_comma}){1,3})|((:${ipv6_one_section_phen_comma})?:${ipv4_regex_inipv6})|:))|((${ipv6_one_section_phen_comma}:){1,3}(((:${ipv6_one_section_phen_comma}){1,4})|((:${ipv6_one_section_phen_comma}){0,2}:${ipv4_regex_inipv6})|:))|((${ipv6_one_section_phen_comma}:){1,2}(((:${ipv6_one_section_phen_comma}){1,5})|((:${ipv6_one_section_phen_comma}){0,3}:${ipv4_regex_inipv6})|:))|((${ipv6_one_section_phen_comma}:){1}(((:${ipv6_one_section_phen_comma}){1,6})|((:${ipv6_one_section_phen_comma}){0,4}:${ipv4_regex_inipv6})|:))|(:(((:${ipv6_one_section_phen_comma}){1,7})|((:${ipv6_one_section_phen_comma}){0,5}:${ipv4_regex_inipv6})|:)))(%.+)?\s*$" 
	    $ipv6_regex_findhpilo_with_bra ="^\s*\[(${ipv4_regex_inipv6}|${ipv6_one_section_phen_comma}|((${ipv6_one_section_phen_comma}:){1,7}(${ipv6_one_section_phen_comma}|:))|((${ipv6_one_section_phen_comma}:){1,6}(:${ipv6_one_section_phen_comma}|${ipv4_regex_inipv6}|:))|((${ipv6_one_section_phen_comma}:){1,5}(((:${ipv6_one_section_phen_comma}){1,2})|:${ipv4_regex_inipv6}|:))|((${ipv6_one_section_phen_comma}:){1,4}(((:${ipv6_one_section_phen_comma}){1,3})|((:${ipv6_one_section_phen_comma})?:${ipv4_regex_inipv6})|:))|((${ipv6_one_section_phen_comma}:){1,3}(((:${ipv6_one_section_phen_comma}){1,4})|((:${ipv6_one_section_phen_comma}){0,2}:${ipv4_regex_inipv6})|:))|((${ipv6_one_section_phen_comma}:){1,2}(((:${ipv6_one_section_phen_comma}){1,5})|((:${ipv6_one_section_phen_comma}){0,3}:${ipv4_regex_inipv6})|:))|((${ipv6_one_section_phen_comma}:){1}(((:${ipv6_one_section_phen_comma}){1,6})|((:${ipv6_one_section_phen_comma}){0,4}:${ipv4_regex_inipv6})|:))|(:(((:${ipv6_one_section_phen_comma}){1,7})|((:${ipv6_one_section_phen_comma}){0,5}:${ipv4_regex_inipv6})|:)))(%.+)?\]($port_regex)?\s*$" 	
        $ipv4_regex_findhpilo="^\s*${ipv4_one_section_phen_comma_dot_findhpilo}(\.${ipv4_one_section_phen_comma_dot_findhpilo}){0,3}($port_regex)?\s*$"

  		
        #Step2 - Show progress of Determing if Input is IP address or Hostname
        $Step       = 2
        $StepText   = "Determing if Input is IP address or Hostname ..."    
        Write-Progress -Id $Id -Activity $Activity -Status (&$StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

        $IsIPAddress = $null
        foreach($IP in $iLOIP)
        {      
            if(
                (($IP -match $ipv4_regex_findhpilo) -and (4 -ge (Get-IPv4-Dot-Num -strIP  $IP))) -or
                (($IP -match $ipv6_regex_findhpilo -or $IP -match $ipv6_regex_findhpilo_with_bra) -and
                 (-not ($IP.contains("]") -and $IP.Split("]")[0].Replace("[","").Trim() -match $ipv4_regex_findhpilo))
                )
              )
            {
                if($IsIPAddress -eq $false)
                {
                    Write-Host "Enter all IP Addresses or all HostNames in the Input."
                    Return
                }
                $IsIPAddress = $true
            }
           
            else  #suppose to be host name
            {
                if($IsIPAddress -eq $true)
                {
                    Write-Host "Enter all IP Addresses or all HostNames in the Input."
                    Return
                }
                $IsIPAddress = $false
                try
	            {
		            #if hostname is "1", it returns "0.0.0.1" and the uploadstring later will hang
		            $dns = [System.Net.Dns]::GetHostAddresses($IP)
		            [Array]$IPFromHost += [string]$dns.IPAddressToString
	            }
	            catch
	            {
		            [Array]$IPFromHost += $null
                    Write-Host "Invalid Hostname: IP Address translation not available for hostname $IP."
                    Write-Host "$_.Exception"
                }							             
            }
        }

        #Step3 - Show progress of Determing Valid IPs
        $Step       = 3
        $StepText   = "Determing Valid IPs in the Input....."    
        Write-Progress -Id $Id -Activity $Activity -Status (&$StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

        [Array]$InputIPs=@()
        [Array]$InputUsernames=@()
        [Array]$InputPasswords=@()
        Write-Verbose "Executing Find-HPiLO"
        if(-not $IsIPAddress)#For iLO IP
        {
            if($IPFromHost.Count -ne 0)
            {
                [Array]$FindiLOOutput = Find-HPiLO -Range $IPFromHost
            }
            else
            {
                Write-Host "No valid IPs found for the specified Hostnames."
                return
            }
            [Array]$ReturnArray = Get-ValidIPs -IPs $iLOIP -Usernames $iLOUsername -Passwords $iLOPassword
            $HOSTNAMES = @()
            foreach($ReturnIP in $ReturnArray.IPs)
            {
                $dns = [System.Net.Dns]::GetHostAddresses($ReturnIP)
                $HOSTNAMES+= [string]$dns.IPAddressToString
            }
            if($HOSTNAMES.Count -ne 0)
            {
                [Array]$FindiLOOutput = Find-HPiLO -Range $HOSTNAMES -WarningAction SilentlyContinue
            }
            else
            {
                 Write-Host "No valid IPs found for the specified Hostnames."
                 return  
            }
            $InputIPs = $HOSTNAMES
            $InputUsernames = $ReturnArray.Usernames
            $InputPasswords = $ReturnArray.Passwords
        }
        else
        {
            $ReturnArray = @{} 

            [Array]$NotRangeIPs
            $RangeMatch = $iLOIP -match $ipv4_regex_findhpilo
            if($RangeMatch.Count -eq 0)
            {
                $RangeMatch = $iLOIP -match $ipv6_regex_findhpilo
            }
            if($RangeMatch.Count -eq 0)
            {
                $RangeMatch = $iLOIP -match $ipv6_regex_findhpilo_with_bra
            }

            if($RangeMatch -eq $null)
            {
                if($iLOIP -ne 0)
                {
                    [Array]$FindiLOOutput = Find-HPiLO -Range $iLOIP
                }
                else
                {
                    Write-Host "No Valid IPs found."
                    Return
                }
                [Array]$ReturnArray = Get-ValidIPs -IPs $FindiLOOutput.IP -Usernames $iLOUsername -Passwords $iLOPassword
                if($ReturnArray.IPs -ne 0)
                {
                    [Array]$FindiLOOutput = Find-HPiLO -Range $ReturnArray.IPs -WarningAction SilentlyContinue
                }
                else
                {
                    Write-Host "No valid IPs found."
                    return
                }
                $InputIPs = $ReturnArray.IPs
                $InputUsernames = $ReturnArray.Usernames
                $InputPasswords = $ReturnArray.Passwords            
            }
            else
            {      
                #mulltiple Ip ranges with a single USername or password
                if(($iLOIP.Count -gt 1) -and ($iLOUsername.Count -eq 1))
                {
                   $InputUsernames = $iLOUsername
                   $InputPasswords = $iLOPassword
                }
                [Array]$ReturnArray = $null
                for($j=0;$j -lt $RangeMatch.Count; $j++)
                {
                    [Array]$tempArray = Find-HPiLO -Range $iLOIP[$j] -WarningAction SilentlyContinue
         
                    $ReturnArray1 = @()
                    if(($iLOIP.Count -gt 1) -and ($iLOUsername.Count -eq 1))
                    {
                        $ReturnArray1 = Get-ValidIPs -IPs $tempArray.IP -Usernames $iLOUsername -Passwords $iLOPassword
                    }
                    else
                    {
                        $ReturnArray1 = Get-ValidIPs -IPs $tempArray.IP -Usernames $iLOUsername[$j] -Passwords $iLOPassword[$j]
                    }
                    [Array]$ReturnArray += $ReturnArray1
                    if($ReturnArray1.Count -ne 0)
                    {
                        [Array]$FindiLOOutput += Find-HPiLO -Range $ReturnArray1.IPs -WarningAction SilentlyContinue
                        $InputIPs += $ReturnArray1.IPs
                        if(-not (($iLOIP.Count -gt 1) -and ($iLOUsername.Count -eq 1)))
                        {
                            foreach($item in $ReturnArray1.IPs)
                            {
                                $InputUsernames += $iLOUsername[$j]
                                $InputPasswords += $iLOPassword[$j] 
                            }
                         }
                    }
                }
            }
       }
       if($InputIPs.Count -eq 0)
       {
            Write-Host "No IPs are available in the given input."
            return
       }

       #Step4 - Show progress of Retrieving Data Using HPiLOCmdlets
       $Step       = 4
       $StepText   = "Retrieving Data Using HPiLOCmdlets....."    
       Write-Progress -Id $Id -Activity $Activity -Status (&$StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)
       if($DisableCertificateAuthentication)
       {
            Write-Verbose "Executing Get-HPiLOHealthSummary"
            [Array]$HealthSummaryOutput = Get-HPiLOHealthSummary -Server $InputIPs -Username $InputUsernames -Password $InputPasswords -DisableCertificateAuthentication
            Write-Verbose "Executing Get-HPiLOPowerSupply"
            [Array]$PowerSUpplyOutput = Get-HPiLOPowerSupply -Server $InputIPs -Username $InputUsernames -Password $InputPasswords -DisableCertificateAuthentication
            Write-Verbose "Executing Get-HPiLOERSSetting"
            [Array]$ERSSettingOutput = Get-HPiLOERSSetting -Server $InputIPs -Username $InputUsernames -Password $InputPasswords -DisableCertificateAuthentication
            Write-Verbose "Executing Get-HPiLOFirmwareInfo"
            [Array]$FirmwareInfoOutput = Get-HPiLOFirmwareInfo -Server $InputIPs -Username $InputUsernames -Password $InputPasswords -DisableCertificateAuthentication
        }
        else
        {
            Write-Verbose "Executing Get-HPiLOHealthSummary"
            [Array]$HealthSummaryOutput = Get-HPiLOHealthSummary -Server $InputIPs -Username $InputUsernames -Password $InputPasswords
            Write-Verbose "Executing Get-HPiLOPowerSupply"
            [Array]$PowerSUpplyOutput = Get-HPiLOPowerSupply -Server $InputIPs -Username $InputUsernames -Password $InputPasswords
            Write-Verbose "Executing Get-HPiLOERSSetting"
            [Array]$ERSSettingOutput = Get-HPiLOERSSetting -Server $InputIPs -Username $InputUsernames -Password $InputPasswords
            Write-Verbose "Executing Get-HPiLOFirmwareInfo"
            [Array]$FirmwareInfoOutput = Get-HPiLOFirmwareInfo -Server $InputIPs -Username $InputUsernames -Password $InputPasswords 
        }

        #Step5 - Creating Output file with system Inventory Details....
        $Step       = 5
        $StepText   = "Creating Output file with system Inventory Details.... "    
        Write-Progress -Id $Id -Activity $Activity -Status (&$StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)
        
        Write-Verbose "Forming the Output"
        #Concatenating the properties in $output
        for($i=0; $i -lt $ReturnArray.IPs.Count; $i++)
        {            
            if($IsIPAddress)
            {
                [String]$output += $FindiLOOutput[$i].IP+","+$FindiLOOutput[$i].SerialNumber+","+$FindiLOOutput[$i].SPN+","
            }
            else
            {
                [String]$output += $FindiLOOutput[$i].HOSTNAME+","+$FindiLOOutput[$i].SerialNumber+","+$FindiLOOutput[$i].SPN+","
            }
            if($HealthSummaryOutput[$i].STATUS_TYPE.Equals("OK"))
            {    
                $output += $HealthSummaryOutput[$i].BIOS_HARDWARE_STATUS + ","
            }
            else
            {
                $output += "LOGIN FAILED" + ","
            }

            if($PowerSUpplyOutput[$i].supply.label -eq $null)
            {
                $output += "N/A" + ","
            }
            else
            {
                $labels = $PowerSUpplyOutput[$i].supply.label
                foreach($label in $labels)
                {
	                $output+=$label + ";"
                }
                $output = $output.TrimEnd(";")
                $output+=","
            }
                       
            if($HealthSummaryOutput[$i].POWER_SUPPLIES_STATUS -ne $null)
            {
	            $output += $HealthSummaryOutput[$i].POWER_SUPPLIES_STATUS + ","
            }
            elseif(($HealthSummaryOutput[$i].POWER_SUPPLIES.REDUNDANCY -ne $null) -and ($HealthSummaryOutput[$i].POWER_SUPPLIES.REDUNDANCY.Contains("Redundant")))
            {
	            $output += $HealthSummaryOutput[$i].POWER_SUPPLIES.STATUS + ","
            }
            elseif(($HealthSummaryOutput[$i].POWER_SUPPLIES.REDUNDANCY -ne $null) -and ($HealthSummaryOutput[$i].POWER_SUPPLIES.REDUNDANCY.Contains("Not Redundant")))
            {
	            $output += $HealthSummaryOutput[$i].POWER_SUPPLIES.REDUNDANCY + ","
            }
            else
            {
                $Output += "N/A" + ","
            }

            if($ERSSettingOutput[$i].STATUS_TYPE.Equals("OK"))
            {
                if($ERSSettingOutput[$i].ERS_STATE -eq 1)
                {
                    $output += "Yes"+","
                }
                elseif($ERSSettingOutput[$i].ERS_STATE -eq 0)
                {
                    $output += "No"+","
                }
                else
                {
                    $output += "N/A"+","
                }
            }
            else
            {
                $output += "LOGIN FAILED" + ","
            }
            
            [Array]$FirmwareInfo = $FirmwareInfoOutput[$i].FirmwareInfo 

            if($FirmwareInfoOutput[$i].STATUS_TYPE.Equals("OK"))
            {
                for($j=0; $j -lt $HeaderArray.Count; $j++ )
                {
                    $HeaderFound = $false
                    for($k=0; $k -lt $FirmwareInfo.Count; $k++ )
                    {
                        if($HeaderArray[$j].Contains("Dynamic Smart Array") -or $HeaderArray[$j].Contains("Smart HBA") -or $HeaderArray[$j].Contains("HP Ethernet") -or $HeaderArray[$j].Contains("Smart Array"))
                        {
                            if($FirmwareInfo[$k].FIRMWARE_NAME -match $HeaderArray[$j]) 
                            {
                                $output+=$FirmwareInfo[$k].FIRMWARE_VERSION + "(" + $FirmwareInfo[$k].FIRMWARE_NAME.Substring($HeaderArray[$j].Length) + ")" + ","
                                $HeaderFound = $true
                                break
                            }
                        }
                        elseif($HeaderArray[$j].Contains("Power Management Controller FW Bootloader"))
                        {
                            if($FirmwareInfo[$k].FIRMWARE_NAME -match "Power Management Controller\s\w*\sBootloader") 
                            {
                                $output+=$FirmwareInfo[$k].FIRMWARE_VERSION + ","
                                $HeaderFound = $true
                                break
                            }
                        }
                        elseif($HeaderArray[$j].Contains("System ROM"))
                        {
                            if($FirmwareInfo[$k].FIRMWARE_NAME.Contains("System ROM") -or
                                $FirmwareInfo[$k].FIRMWARE_NAME.Contains("HP ProLiant System ROM")
                                ) 
                            {
                                $output+=$FirmwareInfo[$k].FIRMWARE_VERSION + ","
                                $HeaderFound = $true
                                break
                            }
                        }
                        else
                        {
                            if($FirmwareInfo[$k].FIRMWARE_NAME -eq $HeaderArray[$j]) 
                            {
                                $output+=$FirmwareInfo[$k].FIRMWARE_VERSION + ","
                                $HeaderFound = $true
                                break
                            }
                        }
                    }
                    
                    if(-not $HeaderFound)
                    {
                        $output+="N/A"+","
                    }
                }
                $output += "`n"  
            }
            else
            {
                $output += "LOGIN FAILED`n"
            }
        }
        Add-content -Path $script:SystemInventoryFile -Value $output
        Write-Progress -Id $Id -Completed -Activity $Activity
    }

    $iLOCmdlets       = 'HPiLOCmdlets' 
    $HPiLOCmdletModule = 'C:\Program Files\Hewlett-Packard\PowerShell\Modules\HPiLOCmdlets\HPiLOCmdlets.psm1'

    $Activity = "System Inventory Tool Progress"
    $Id       = 1    
    $TotalSteps = 5
    $StatusText = '"Step $($Step.ToString().PadLeft($TotalSteps.Count.ToString().Length)) of $TotalSteps | $StepText"'
    $StatusBlock = [ScriptBlock]::Create($StatusText) 

    #Step1 - Show progress of Prerequisities
    $Step       = 1
    $StepText   = "Checking Prerequisities ..."    
    Write-Progress -Id $Id -Activity $Activity -Status (&$StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

    if (-not (test-path $HPiLOCmdletModule))
    {
        write-host -foreground YELLOW "HPiLOCmdlets module is not installed. Please install the module from `"http://www.hpe.com/servers/powershell`"" 
        return
    }
        
    import-module $HPiLOCmdletModule 
    #Validate Output csv file path
    if(-not $OutputCSV)
    {
        $TimeStamp = get-date -format ddMMMyyyyhhmmss 
        $script:SystemInventoryFile  = "SystemInventory_$TimeStamp.csv"
        write-host "Output File path is not given. Output file will be created in the current directory."
    }
    elseif([IO.Path]::GetExtension($OutputCSV) -ne ".csv")
    {
        $TimeStamp = get-date -format ddMMMyyyyhhmmss
        $script:SystemInventoryFile  = "SystemInventory_$TimeStamp.csv"
        write-host "Output File path is not valid. Output file will be created in the current directory."
    }
    else
    {
       $script:SystemInventoryFile  = $OutputCSV
    }
     
    if (-not (test-path $Script:SystemInventoryFile))
    {
       $SystemInventoryCSV = New-Item $script:SystemInventoryFile  -type file -force
    }
    [Environment]::CurrentDirectory = pwd
    $OutputFileFullPath = [IO.Path]::GetFullPath($script:SystemInventoryFile)
    Write-Host "Output file path -> $OutputFileFullPath"

    switch ($PSCmdlet.ParameterSetName)
    {

        "CommandLine" 
        {
            if ( -not( [string]::IsNullOrEmpty($iLOUsername) -or [string]::IsNullOrEmpty($iLOPassword) ))
            {
                if($DisableCertificateAuthentication)
                {
                    GetData -iLOIP $iLOIP -iLOUsername $iLOUsername -iLOPassword $iLOPassword -DisableCertificateAuthentication
                }
                else
                {
                    GetData -iLOIP $iLOIP -iLOUsername $iLOUsername -iLOPassword $iLOPassword
                }
            }
            else
            {
                write-host " ILO Username and Password are not specified." 
            }
        }

        "CSVInput"
        {
            #Validate Input csv file path
            if ( -not $InputiLOCSV)
            {
                write-host "Input CSV file is not specified for the parameter InputiLOCSV."
                return
            }
            if ( -not (Test-path $InputiLOCSV) )
            {
                write-host "File $InputiLOCSV does not exist."
                return
            }
            if([IO.Path]::GetExtension($InputiLOCSV) -ne ".csv")
            {
                write-host "Specify the full path of the input csv."
                return
            }

  
            $ListofServers = import-csv $InputiLOCSV
            if($DisableCertificateAuthentication)
            {
                GetData -iLOIP $ListofServers.IP -iLOUsername $ListofServers.Username -iLOPassword $ListofServers.Password -DisableCertificateAuthentication 
            }
            else
            {
                GetData -iLOIP $ListofServers.IP -iLOUsername $ListofServers.Username -iLOPassword $ListofServers.Password
            }
        }
    }