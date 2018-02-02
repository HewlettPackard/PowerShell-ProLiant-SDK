<#
(c) Copyright 2016-2018 Hewlett Packard Enterprise Development LP

Licensed under the Apache License, Version 2.0 (the "License");
You may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 




These examples use HPE Redfish PowerShell cmdlets available at http://www.powershellgallery.com/packages/HPERedfishCmdlets/.
These scripts provide examples of using HPE Redfish API on HPE iLO for common use cases.

These examples use the following base set of cmdlets:

Connect-HPERedfish
Disable-HPERedfishCertificateAuthentication
Disconnect-HPERedfish
Edit-HPERedfishData
Enable-HPERedfishCertificateAuthentication
Find-HPERedfish
Format-HPERedfishDir
Get-HPERedfishData
Get-HPERedfishDataRaw
Get-HPERedfishDir
Get-HPERedfishHttpData
Get-HPERedfishIndex
Get-HPERedfishMessage
Get-HPERedfishModuleVersion
Get-HPERedfishSchema
Get-HPERedfishSchemaExtref
Get-HPERedfishUriFromOdataId
Invoke-HPERedfishAction
Remove-HPERedfishData
Set-HPERedfishData
Test-HPERedfishCertificateAuthentication

#>


 
#iLO IP address and credentials to access the iLO
$Address = '192.168.21.12'
$cred = Get-Credential
Disable-HPERedfishCertificateAuthentication

function Reset-ServerExample1
{
param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $Action,

        [System.String]
        $PropertyName,

        [System.String]
        $PropertyValue
    )

    Write-Host 'Example 1: Reset the server.'
    
    #create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    # getting system list
    $systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/systems/' -Session $session
    foreach($sys in $systems.members.'@odata.id') # /redfish/v1/systems/1/, /redfish/v1/system/2/
    {
        $sysData = Get-HPERedfishDataRaw -odataid $sys -Session $session

        # creating setting object to invoke reset action. 
        # Details of invoking reset (or other possible actions) is present in 'Actions' of system data  
        $dataToPost = @{}
        $dataToPost.Add($PropertyName,$PropertyValue)
        
        # Sending reset request to system using 'POST' in Invoke-HPERedfishAction
        $ret = Invoke-HPERedfishAction -odataid $sysData.Actions.'#ComputerSystem.Reset'.target -Data $dataToPost -Session $session

        # processing message obtained by executing Set- cmdlet
        if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
        {
            foreach($msgID in $ret.error.'@Message.ExtendedInfo')
            {
                $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }

    # disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
#Reset-ServerExample1 -Address $Address -Credential $cred -Action Reset -PropertyName ResetType -PropertyValue ForceRestart

function Set-SecureBootExample2
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $SecureBootProperty, # schema allows changing values for SecureBootEnable, ResetToDefaultKeys, ResetAllKeys

        [Boolean]
        $Value #value must be a boolean i.e. $true or $false
    )

    Write-Host 'Example 2: Enable/Disable UEFI secure boot'
    
    #create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    $systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/systems/' -Session $session
    foreach($sys in $systems.members.'@odata.id') # /redfish/v1/systems/1/, /redfish/v1/system/2/
    {
        #Get secure boot URI
        $sysData = Get-HPERedfishDataRaw -odataid $sys -Session $session
        
        # for iLO 5
        $secureBootOdataId = $sysData.SecureBoot.'@odata.id'
        
        ## for iLO 4
        #$secureBootOdataId = $sysData.Oem.Hp.Links.SecureBoot.'@odata.id'
    
        #get secure boot data and display original value
        $secureBootData = Get-HPERedfishDataRaw -odataid $secureBootOdataId -Session $session
        $secureBootData

        #if property to be modified is not present in the secure boot data, then print error message and return
        if(-not(($secureBootData|Get-Member).Name -Contains $SecureBootProperty))
        {
            Write-Host "Property $SecureBootProperty is not supported on this system"
        }
        else
        {
            # use Set cmdlet at Secure Boot odataid to update secure boot property. Here only boolean values are allowed for Value parameter
            # creating hashtable object with property and value
            $secureBootSetting = @{$SecureBootProperty=$Value}
            
            # Execute Set- cmdlet to post enable/disable setting at odataid for secure boot
            $ret = Set-HPERedfishData -odataid $secureBootOdataId -Setting $SecureBootSetting -Session $session
            
            # processing message obtained by executing Set- cmdlet
            if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
            {
                foreach($msgID in $ret.error.'@Message.ExtendedInfo')
                {
                    $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }

            # get and display updated value of the property
            $secureBootData = Get-HPERedfishDataRaw -odataid $secureBootOdataId -Session $session
            $secureBootData        
        }
    }

    # disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
#Set-SecureBootExample2 -Address $Address -Credential $cred -SecureBootProperty 'SecureBootEnable' -Value $false

function Set-TempBootOrderExample3
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $BootTarget
    )

    Write-Host 'Example 3: Set one-time(temporary)boot order'
    
    #create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    #Get system list
    $systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/systems/' -Session $session
    foreach($sys in $systems.Members.'@odata.id') # /redfish/v1/systems/1/, /redfish/v1/system/2/
    {
        # get boot data for the system
        $sysData = Get-HPERedfishDataRaw -odataid $sys -Session $session
        Write-Host $sysData.Boot

        # create object to PATCH
        $tempBoot = @{'BootSourceOverrideTarget'=$BootTarget}
        $OneTimeBoot = @{'Boot'=$tempBoot}

        # PATCH the data using Set-HPERedfishData cmdlet
        $ret = Set-HPERedfishData -odataid $sys -Setting $OneTimeBoot -Session $session
            
        #process message returned by Set-HPERedfishData cmdlet
        if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
        {
            foreach($msgID in $ret.error.'@Message.ExtendedInfo')
            {
                $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }

        #get and print updated value
        $bootData = Get-HPERedfishDataRaw -odataid $sys -Session $session
        $bootData.Boot
    }

    # disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
## NOTE:  The value is case sensitive. 
#check the boot targets supported:
# in iLO 5 check BootSourceOverrideTarget@Redfish.AllowableValues and UefiTargetBootSourceOverride@Redfish.AllowableValues under $sysData.Boot
# in iLO 4 check BootSourceOverrideSupported $sysData.Boot.BootSourceOverrideSupported).

## E.g. Pxe will work, pxe will not
#Set-TempBootOrderExample3 -Address $Address -Credential $cred -BootTarget 'Hdd'

function Get-iLOMACAddressExample4
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    Write-Host "Example 4: Find iLO's MAC addresses"
    
    #create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/managers/' -Session $session
    foreach($manager in $managers.members.'@odata.id') # /redfish/v1/managers/1/, /redfish/v1/managers/2/
    {
        #Get manager data
        $managerData = Get-HPERedfishDataRaw -odataid $manager -Session $session
        
        # retrieve ethernet NIC details
        $nicURI = $managerData.EthernetInterfaces.'@odata.id'
        $nicListData = Get-HPERedfishDataRaw -odataid $nicURI -Session $session

        foreach($nicOdataId in $nicListData.Members.'@odata.id')
        {
            $nicData = Get-HPERedfishDataRaw -odataid $nicOdataId -Session $session
            Write-Host $nicData.Name - $nicData.MacAddress 
        }
    }

    # disconnect session after use
    Disconnect-HPERedfish -Session $session
}
#Get-iLOMACAddressExample4 -Address $Address -Credential $cred

function Add-iLOUserAccountExample5
{
# NOTE: '(400) Bad Request' error will be thrown if the user already exists
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $newiLOLoginName,

        [System.String]
        $newiLOUserName,

        [System.String]
        $newiLOPassword,

        [Boolean]
        $RemoteConsolePriv = $false,

        [Boolean]
        $ConfigPriv = $false,

        [Boolean]
        $VirtualMediaPriv = $false,

        [Boolean]
        $UserConfigPriv = $false,

        [Boolean]
        $VirtualPowerResetPriv = $false
    )

    Write-Host 'Example 5: Create an iLO user account.'

    #create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    # Get AccountService data to obtain Accounts odataid
    $accData = Get-HPERedfishDataRaw -odataid '/redfish/v1/AccountService/' -Session $session
    $accOdataId = $accData.Accounts.'@odata.id'

    # create iLO user object
    # add permissions
    $priv = @{}
    $priv.Add('RemoteConsolePriv',$RemoteConsolePriv)
    $priv.Add('iLOConfigPriv',$ConfigPriv)
    $priv.Add('VirtualMediaPriv',$VirtualMediaPriv)
    $priv.Add('UserConfigPriv',$UserConfigPriv)
    $priv.Add('VirtualPowerAndResetPriv',$VirtualPowerResetPriv)

    # add login name
    $hp = @{}
    $hp.Add('LoginName',$newiLOLoginName)
    $hp.Add('Privileges',$priv)
    
    $oem = @{}
    # for iLO 5
    $oem.Add('Hpe',$hp)
    
    ## for iLO 4
    #$oem.Add('Hp',$hp)

    # add username and password for access
    $user = @{}
    $user.Add('UserName',$newiLOUserName)
    $user.Add('Password',$newiLOPassword)
    $user.Add('Oem',$oem)

    # execute HTTP POST method using Invoke-HPERedfishAction to add user data at Accounts odata_id
    $ret = Invoke-HPERedfishAction -odataid $accOdataId -Data $user -Session $session
    $ret

    # disconnect session after use
    Disconnect-HPERedfish -Session $session
}
#Add-iLOUserAccountExample5 -Address $Address -Credential $cred -newiLOLoginName 'timh1' -newiLOUserName 'TimHorton' -newiLOPassword 'timPassword123' -RemoteConsolePriv $true

function Set-iLOUserAccountExample6
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $LoginNameToModify,

        [System.String]
        $newLoginName = '',

        [System.String]
        $newUsername = '',

        [System.String]
        $newPassword = '',

        [System.Object]
        $RemoteConsolePriv = $null,

        [System.Object]
        $ConfigPriv = $null,

        [System.Object]
        $VirtualMediaPriv = $null,

        [System.Object]
        $UserConfigPriv = $null,

        [System.Object]
        $VirtualPowerResetPriv = $null
    )

    Write-Host 'Example 6: Modify an iLO user account.'

    #create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    # get the odataid of the iLO user accounts
    $accData = Get-HPERedfishDataRaw -odataid '/redfish/v1/AccountService/' -Session $session
    $accOdataId = $accData.Accounts.'@odata.id'

    $accounts = Get-HPERedfishDataRaw -odataid $accOdataId -Session $session
    $foundFlag = $false
    $requiredAccountOdataId = ''
    $user = $null

    foreach($accountMemberOdataId in $accounts.Members.'@odata.id')
    {
        $accountDetails = Get-HPERedfishDataRaw -odataid $accountMemberOdataId -Session $session

        # check if user is present in the user list
        if($accountDetails.Username -eq $LoginNameToModify)
        {
            $foundFlag = $true
            $requiredAccountOdataId = $accountDetails.'@odata.id'
            
            # Create user object with new value(s)
            $priv = @{}
            if($RemoteConsolePriv -ne $null){$priv.Add('RemoteConsolePriv',[System.Convert]::ToBoolean($RemoteConsolePriv))}
            if($ConfigPriv -ne $null){$priv.Add('iLOConfigPriv',[System.Convert]::ToBoolean($ConfigPriv))}
            if($VirtualMediaPriv -ne $null){$priv.Add('VirtualMediaPriv',[System.Convert]::ToBoolean($VirtualMediaPriv))}
            if($UserConfigPriv -ne $null){$priv.Add('UserConfigPriv',[System.Convert]::ToBoolean($UserConfigPriv))}
            if($VirtualPowerResetPriv -ne $null){$priv.Add('VirtualPowerAndResetPriv',[System.Convert]::ToBoolean($VirtualPowerResetPriv))}

            $hp = @{}
            if($newLoginName -ne ''){$hp.Add('LoginName',$newLoginName)}
            if($priv.Count -gt 0){$hp.Add('Privileges',$priv)}
    
            $oem = @{}
            # for iLO 5
            if($hp.Count -gt 0){$oem.Add('Hpe',$hp)}
            
            ## for iLO 4
            #if($hp.Count -gt 0){$oem.Add('Hp',$hp)}

            $user = @{}
            if($newUserName -ne ''){$user.Add('UserName',$newUserName)}
            if($newPassword -ne ''){$user.Add('Password',$newPassword)}
            if($oem.Count -gt 0){$user.Add('Oem',$oem)}
            break
        }
    }
    if($foundFlag -eq $true)
    {
        # WARNING: If you don't change anything, you will get an HTTP 400 back 
        # PATCH the data using Set-HPERedfishData
        $ret = Set-HPERedfishData -odataid $requiredAccountOdataId -Setting $user -Session $session
        if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
        {
            foreach($msgID in $ret.error.'@Message.ExtendedInfo')
            {
                $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }
    # If user name is not found, print message
    else
    {
        Write-Error "$LoginNameToModify not present"
    }

    # Disconnect session after use
    Disconnect-HPERedfish -Session $session
}
#Set-iLOUserAccountExample6 -Address $Address -Credential $cred -LoginNameToModify 'TimHorton' -RemoteConsolePriv $false

function Remove-iLOUserAccountExample7
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $LoginNameToRemove
    )

    Write-Host 'Example 7: Delete an iLO user account.'

    #create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    $accData = Get-HPERedfishDataRaw -odataid '/redfish/v1/AccountService/' -Session $session
    $accountsOdataId = $accData.Accounts.'@odata.id'

    $accounts = Get-HPERedfishDataRaw -odataid $accountsOdataId -Session $session
    $foundFlag = $false
    $requiredAccOdataId = ''
    foreach($accOdataId in $accounts.Members.'@odata.id')
    {
        $acc = Get-HPERedfishDataRaw -odataid $accOdataId -Session $session

        # If user to delete is found in user list, store the odataid for that user in $requiredAccOdataId variable
        if($acc.Username -eq $LoginNameToRemove)
        {
            $foundFlag = $true
            $requiredAccOdataId = $acc.'@odata.id'
            break
        }
    }
    if($foundFlag -eq $true)
    {
        # If the user was found, executet the HTTP DELETE method on the odataid of the user to be deleted.
        $ret = Remove-HPERedfishData -odataid $requiredAccOdataId -Session $session
        
        # process message(s) from Remove-HPERedfishData cmdlet
        if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
        {
            foreach($msgID in $ret.error.'@Message.ExtendedInfo')
            {
                $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }

        # print list of users. Deleted user will not be present in the list
        $accData = Get-HPERedfishDataRaw -odataid $accData.Accounts.'@odata.id' -Session $session
        foreach($mem in $accData.Members."@odata.id")
        {
            $memData = Get-HPERedfishDataRaw -odataid $mem -Session $session
            $memData
        }
    }
    else
    {
        Write-Error "$LoginNameToRemove not present"
    }

    # Disconnect session after use
    Disconnect-HPERedfish -Session $session
}
#Remove-iLOUserAccountExample7 -Address $Address -Credential $cred -LoginNameToRemove TimHorton

function Get-ActiveiLONICExample8
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 8: Retrieve active iLO NIC information'

    # create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # retrieve manager list
    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/Managers/' -Session $session
    foreach($manager in $managers.Members.'@odata.id')
    {
        # retrieve manager details and the ethernetNIC odataid from that
        $managerData = Get-HPERedfishDataRaw -odataid $manager -Session $session
        $nicURI = $managerData.EthernetInterfaces.'@odata.id'

        # retrieve all NIC information
        $nics = Get-HPERedfishDataRaw -odataid $nicURI -Session $session

        # print NIC details for enabled i.e. active NIC
        foreach($nic in $nics.Members.'@odata.id')
        {
            $nicData = Get-HPERedfishDataRaw -odataid $nic -Session $session
            if($nicData.Status.State -eq 'Enabled')
            {
                $nicData
            }
        }
    }

    # Disconnect session after use
    Disconnect-HPERedfish -Session $session
}
#Get-ActiveiLONICExample8 -Address $Address -Credential $cred

function Get-SessionExample9
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 9: Retrieve current session information'

    # connect session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    # retrieve all sessions
    $sessions = Get-HPERedfishDataRaw -odataid '/redfish/v1/Sessionservice/' -Session $session
    
    #get the details of current session
    foreach($ses in $sessions.Sessions.'@odata.id')
    {
        $sesData = Get-HPERedfishDataRaw -odataid $ses -Session $session
        
        # for iLO 5
        $mySesOdataId = $sesData.Oem.Hpe.Links.MySession.'@odata.id'
        
        ## for iLO 4
        #$mySesOdataId = $sesData.Oem.Hp.Links.MySession.'@odata.id'

        foreach($mySes in $mySesOdataId)
        {
            $mySesData = Get-HPERedfishDataRaw $mySes -Session $session
            # for iLO 5
            if($mySesData.Oem.Hpe.MySession -eq $true)
            {
                $mySesData
                $mySesData.oem.hpe
            }

            ##for iLO 4            
            #if($mySesData.Oem.Hp.MySession -eq $true)
            #{
            #    $mySesData
            #    $mySesData.oem.hp
            #}
        }
    }

    # disconnect session after use
    Disconnect-HPERedfish -Session $session
}
#Get-SessionExample9 -Address $Address -Credential $cred

function Set-UIDStateExample10
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [ValidateSet('Lit','Off')]
        [System.String]
        $UIDState # Use 'Lit' or 'Off'. Value identified by 'IndicatorLED' field in 'redfish/v1/Systems/1'. The value 'Blinking' in mentioned in the schema is not settable by the user.
    )

    Write-Host 'Example 10: Change UID/IndicatorLED status'

    # connect session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # retrieve list of systems
    $systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/' -Session $session
    foreach($sys in $systems.Members.'@odata.id')
    {
        # get the odataid of the system to PATCH the Indicator LED value
        $sysData = Get-HPERedfishDataRaw -odataid $sys -Session $session
        $sysURI = $sysData.'@odata.id'

        # create hashtable object to PATCH
        $UIDSetting = @{'IndicatorLED'=$UIDState}

        # PATCH the data using Set-HPERedfishData cmdlet
        $ret = Set-HPERedfishData -odataid $sysURI -Setting $UIDSetting -Session $session

        # process the message(s) from Set-HPERedfishData
        if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
        {
            foreach($msgID in $ret.error.'@Message.ExtendedInfo')
            {
                $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
## NOTE: UID State - Unknown, Lit, Blinking, Off. Unknown and Blinking cannot be set by user
#Set-UIDStateExample10 -Address $Address -Credential $cred -UIDState 'Off'

function Get-ComputerSystemExample11
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 11: Retrieve information of computer systems'

    # connect session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # retrieve list of computer systems
    $systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/' -Session $session

    # print details of all computer systems
    foreach($sys in $systems.Members.'@odata.id')
    {
        $sysData = Get-HPERedfishDataRaw -odataid $sys -Session $session
        $sysData
    }

    # Disconnect session after use
    Disconnect-HPERedfish -Session $session    
}
#Get-ComputerSystemExample11 -Address $Address -Credential $cred

function Set-VirutalMediaExample12
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.Object]
        $IsoUrl = $null,

        [System.Object]
        $BootOnNextReset = $null
    )

    # NOTE: if ISO URL is blank and BootOnNextReset are blank/null, the virtual media is unmounted
    Write-Host 'Example 12 : Mount/Unmount virtual media DVD using URL'

    # Connect session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/Managers/' -Session $session
    foreach($mgr in $managers.Members.'@odata.id')
    {
        
        $mgrData = Get-HPERedfishDataRaw -odataid $mgr -Session $session
        # Check if virtual media is supported
        if($mgrData.PSObject.Properties.name -Contains 'VirtualMedia' -eq $false)
        {
            # If virtual media is not present in links under manager details, print error
            Write-Host 'Virtual media not available in Manager links'
        }
        else
        {
            
            $vmOdataId = $mgrData.VirtualMedia.'@odata.id'
            $vmData = Get-HPERedfishDataRaw -odataid $vmOdataId -Session $session
            foreach($vm in $vmData.Members.'@odata.id')
            {
                $data = Get-HPERedfishDataRaw -odataid $vm -Session $session
                # select the media option which contains DVD
                if($data.MediaTypes -contains 'DVD')
                {
                    # Create object to PATCH to update ISO image URI and to set
                    if($IsoUrl -eq $null)
                    {
                        $mountSetting = @{'Image'=$null}
                    }
                    else
                    {
                        $mountSetting = @{'Image'=[System.Convert]::ToString($IsoUrl)}
                    }
                    if($BootOnNextReset -ne $null -and $IsoUrl -ne $null)
                    {
                        # Create object to PATCH 
                        # for iLO 5
                        $oem = @{'Hpe'=@{'BootOnNextServerReset'=[System.Convert]::ToBoolean($BootOnNextReset)}}
                        
                        ## for iLO 4
                        #$oem = @{'Hp'=@{'BootOnNextServerReset'=[System.Convert]::ToBoolean($BootOnNextReset)}}

                        $mountSetting.Add('Oem',$oem)
                    }
                    # PATCH the data to $vm odataid by using Set-HPERedfishData
                    #Disconnect-HPERedfish -Session $session
                    $ret = Set-HPERedfishData -odataid $vm -Setting $mountSetting -Session $session
                    
                    # Process message(s) returned from Set-HPERedfishData
                    if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
                    {
                        foreach($msgID in $ret.error.'@Message.ExtendedInfo')
                        {
                            $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                            $status
                        }
                    }
                    Get-HPERedfishDataRaw -odataid $vm -Session $session
                }
            }        
        }
    }
    # Disconnect session after use
    Disconnect-HPERedfish -Session $session
}
<#
# will return '(400) Bad Request' error if the virtual media is already in this state.
# IsoUrl = $null will dismount the virtual media. IsoUrl = '' will give 400 Bad Request error.

#unmount
Set-VirutalMediaExample12 -Address $Address -Credential $cred -IsoUrl $null -BootOnNextReset $false

#Mount
Set-VirutalMediaExample12 -Address $Address -Credential $cred -IsoUrl 'http://192.168.217.158/iso/Windows/en_windows_server_2012.iso' -BootOnNextReset $true

#unmount
Set-VirutalMediaExample12 -Address $Address -Credential $cred
#>

function Set-AssetTagExample13
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $AssetTag
    )
    Write-Host 'Example 13: Update AssetTag value.'

    # Connect sesion
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # Retrieve list of systems
    $systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/' -Session $session
    foreach($sys in $systems.Members.'@odata.id')
    {
        # Get each system odataid by first retrieving each system data and then extracting odataid from it
        $sysData = Get-HPERedfishDataRaw -odataid $sys -Session $session
        $sysOdataId = $sysData.'@odata.id'

        # Create hashtable object to PATCH to odataid of the system
        $assetTagSetting = @{'AssetTag'= $AssetTag}
        # PATCH data using Set-HPERedfishData cmdlet
        $ret = Set-HPERedfishData -odataid $sysOdataId -Setting $assetTagSetting -Session $session

        # Process message(s) from Set-HPERedfishData
        if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
        {
            foreach($msgID in $ret.error.'@Message.ExtendedInfo')
            {
                $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }
    # Disconnect session after use
    Disconnect-HPERedfish -Session $session
}
#Set-AssetTagExample13 -Address $Address -Credential $cred -AssetTag 'TestAssetTag'

function Reset-iLOExample14
{
param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    Write-Host 'Example 14: Reset the iLO.'
    
    #create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    # Get list of managers
    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/Managers/' -Session $session
    foreach($mgrOdataId in $managers.Members.'@odata.id') # /redfish/v1/managers/1/, /redfish/v1/managers/2/
    {
        # for possible operations on the manager check 'Actions' field in manager data
        $mgrData = Get-HPERedfishDataRaw -odataid $mgrOdataId -Session $session

        $resetTarget = $mgrData.Actions.'#Manager.Reset'.target

        #Since there is no other allowable values or options for iLO Reset, we do not provide -Data parameter value.
                
        # Send POST request using Invoke-HPERedfishAction
        $ret = Invoke-HPERedfishAction -odataid $resetTarget -Session $session
        Write-Host $ret.error
        # resetting iLO will delete all active sessions.

    }
    #automatically closes all connections
    #Disconnect-HPERedfish -Session $session
}
#Reset-iLOExample14 -Address $Address -Credential $cred

function Get-iLONICExample15
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [ValidateSet('Active','Inactive','All')]
        [System.String]
        $NICState = 'Active'
    )
    Write-Host 'Example 15: Retrieve iLO NIC information'

    # Create Session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # Retrieve list of managers
    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/Managers/' -Session $session
    foreach($manager in $managers.Members.'@odata.id')
    {
        # Retrieve manager data to extract Ethernet Interface odataid
        $managerData = Get-HPERedfishDataRaw -odataid $manager -Session $session
        $nicOdataId = $managerData.EthernetInterfaces.'@odata.id'

        # Retrieve ethernet NIC details
        $nics = Get-HPERedfishDataRaw -odataid $nicOdataId -Session $session

        # Display NIC accoring to the NICState parameter
        foreach($nicMemberOdataId in $nics.Members.'@odata.id')
        {
            $nicData = Get-HPERedfishDataRaw -odataid $nicMemberOdataId -Session $session
            if($nicData.Status.State -eq 'Enabled')
            {
                if($NICState -eq 'Active')
                {
                    $nicData
                    break
                }
                if($NICState -eq 'All')
                {
                    $nicData
                }
            }
            if($nicData.Status.State -eq 'Disabled')
            {
                if($NICState -eq 'Inactive')
                {
                    $nicData
                    break
                }
                if($NICState -eq 'All')
                {
                    $nicData
                }
            }
        }
    }
    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
#Get-iLONICExample15 -Address $Address -Credential $cred -NICState 'Active'

function Set-ActiveiLONICExample16
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [Boolean]
        $SharedNIC = $false
    )
    Write-Host 'Example 16: Set the active iLO NIC'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # Retrieve list of managers
    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/Managers/' -Session $session
    foreach($manager in $managers.Members.'@odata.id')
    {
        
        $managerData = Get-HPERedfishDataRaw -odataid $manager -Session $session
        $nicsOdataId = $managerData.EthernetInterfaces.'@odata.id'
        $nics = Get-HPERedfishDataRaw -odataid $nicsOdataId -Session $session
        $selectedNICOdataId = ''
        foreach($nic in $nics.Members.'@odata.id')
        {
            $nicData = Get-HPERedfishDataRaw -odataid $nic -Session $session
            if($SharedNIC -eq $true)
            {
                # if a shared NIC setting is required, then check for LOM or Flexible LOM select URI where LOM/FlexLOM is present
                if($nicData.Oem.hpe.SupportsFlexibleLOM -eq $null -and $nicData.Oem.hpe.SupportsLOM -eq $null)
                {
                    continue;
                }
                else
                {
                    if($nicData.Oem.hpe.SupportsFlexibleLOM -eq $true)
                    {
                        $selectedNICOdataId = $nicData.'@odata.id'
                        break
                    }
                    elseif($nicData.Oem.hpe.SupportsLOM -eq $true)
                    {
                        $selectedNICOdataId = $nicData.'@odata.id'
                        break
                    }
                    else
                    {
                        Write-Host 'Shared NIC not supported.'
                    }
                }
            }
            else #if sharedNic set to false, select the odataid of NIC where LOM/FlexLOM are not present
            {
                if($nicData.Oem.hpe.SupportsFlexibleLOM -eq $null -and $nicData.Oem.hpe.SupportsLOM -eq $null)
                {
                    $selectedNICOdataId = $nicData.'@odata.id'
                    break
                }
            }
            
            ## for iLO 4
            <#
            if($SharedNIC -eq $true)
            {
                # if a shared NIC setting is required, then check for LOM or Flexible LOM select URI where LOM/FlexLOM is present
                if($nicData.Oem.hp.SupportsFlexibleLOM -eq $null -and $nicData.Oem.hp.SupportsLOM -eq $null)
                {
                    continue;
                }
                else
                {
                    if($nicData.Oem.hp.SupportsFlexibleLOM -eq $true)
                    {
                        $selectedNICOdataId = $nicData.'@odata.id'
                        break
                    }
                    elseif($nicData.Oem.hp.SupportsLOM -eq $true)
                    {
                        $selectedNICOdataId = $nicData.'@odata.id'
                        break
                    }
                    else
                    {
                        Write-Host 'Shared NIC not supported.'
                    }
                }
            }
            else #if sharedNic set to false, select the odataid of NIC where LOM/FlexLOM are not present
            {
                if($nicData.Oem.hp.SupportsFlexibleLOM -eq $null -and $nicData.Oem.hp.SupportsLOM -eq $null)
                {
                    $selectedNICOdataId = $nicData.'@odata.id'
                    break
                }
            }
            #>
        }

        if($selectedNICOdataId -ne '')
        {
            # for iLO 5
            $req = @{'Oem'=@{'Hpe'=@{'NICEnabled' = $true}}}
            
            ## for iLO 4
            #$req = @{'Oem'=@{'Hp'=@{'NICEnabled' = $true}}}

            $ret = Set-HPERedfishData -odataid $selectedNICOdataId -Setting $req -Session $session

            # Process message(s) returned from Set-HPERedfishData cmdlet
            if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
            {
                foreach($msgID in $ret.error.'@Message.ExtendedInfo')
                {
                    $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
#Set-ActiveiLONICExample16 -Address $Address -Credential $cred

function Get-IMLExample17
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 17: Retrieve Integrated Management Log (IML)'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # Retrieve systems list
    $systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/systems/' -Session $session
    foreach($sys in $systems.Members.'@odata.id')
    {
        # Check if logs are available
        $systemData = Get-HPERedfishDataRaw -odataid $sys -Session $session
        if($systemData.PSObject.properties.name -notcontains 'LogServices')
        {
            Write-Host 'Logs not available'
        }
        else
        {
            # Retrieve the IML odataid
            $logServicesOdataId = $systemData.LogServices.'@odata.id'
            $logServicesData = Get-HPERedfishDataRaw -odataid $logServicesOdataId -Session $session
            $imlOdataId = ''
            foreach($link in $logServicesData.Members.'@odata.id')
            {
                $spl = $link.split('`/')
                if($spl[$spl.length-2] -match 'IML')
                {
                    $imlOdataId = $link
                    break
                }
            }

            # retrieve and display IML log entries
            $imlData = Get-HPERedfishDataRaw -odataid $imlOdataId -Session $session
            foreach($entryOdataId in $imlData.Entries.'@odata.id')
            {
                $entries = Get-HPERedfishDataRaw -odataid $entryOdataId -Session $session
                foreach($entryOdataId in $entries.Members.'@odata.id')
                {
                    $imlEntry = Get-HPERedfishDataRaw -odataid $entryOdataId -Session $session
                    $imlEntry
                }
            }
        }
    }
    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
#Get-IMLExample17 -Address $Address -Credential $cred

function Get-iLOEventLogExample18
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 18: Retrieve iLO Event Log'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/managers/' -Session $session
    foreach($mgr in $managers.Members.'@odata.id')
    {
        $managerData = Get-HPERedfishDataRaw -odataid $mgr -Session $session
        if($managerData.PSObject.properties.name -notcontains 'LogServices')
        {
            Write-Host 'Logs not available'
        }
        else
        {
            # get the odataid for iLO event logs
            $logServicesOdataId = $managerData.LogServices.'@odata.id'
            $logServicesData = Get-HPERedfishDataRaw -odataid $logServicesOdataId -Session $session
            $ielOdataId = ''
            foreach($link in $logServicesData.Members.'@odata.id')
            {
                $spl = $link.split('`/')
                if($spl[$spl.length-2] -match 'IEL')
                {
                    $ielOdataId = $link
                    break
                }
            }

            # Retrieve and display the log entries
            $ielData = Get-HPERedfishDataRaw -odataid $ielOdataId -Session $session
            foreach($entryOdataId in $ielData.Entries.'@odata.id')
            {
                $entries = Get-HPERedfishDataRaw -odataid $entryOdataId -Session $session
                foreach($entryOdataId in $entries.Members.'@odata.id')
                {
                    $ielEntry = Get-HPERedfishDataRaw -odataid $entryOdataId -Session $session
                    $ielEntry
                }
            }
        }
    }
    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
#Get-iLOEventLogExample18 -Address $Address -Credential $cred

function Clear-IMLExample19
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 19: Clear Integrated Management Log'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    #remember system list
    $systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/systems/' -Session $session
    foreach($sys in $systems.Members.'@odata.id')
    {
        # check if logs are available or not
        $systemData = Get-HPERedfishDataRaw -odataid $sys -Session $session
        if($systemData.PSObject.properties.name -notcontains 'LogServices')
        {
            Write-Host 'Logs not available'
        }
        else
        {
            # extract odataid for IML
            $logServicesOdataId = $systemData.LogServices.'@odata.id'
            $logServicesData = Get-HPERedfishDataRaw -odataid $logServicesOdataId -Session $session
            $requiredImlOdataId = ''
            foreach($link in $logServicesData.Members.'@odata.id')
            {
                $spl = $link.split('`/')
                if($spl[$spl.length-2] -match 'IML')
                {
                    $requiredImlOdataId = $link
                    break
                }
            }
            
            # retrieve the target odataid where the POST request is to be sent
            $imlData = Get-HPERedfishDataRaw -odataid $requiredImlOdataId -Session $session
            $clearImlTarget = $imlData.Actions.'#LogService.ClearLog'.target

            #Since there is no property other than 'target' under the 'Action' property, -Data parameter is not required.
            # Send the POST request using Invoke-HPERedfishAction cmdlet
            $ret = Invoke-HPERedfishAction -odataid $clearImlTarget -Session $session

            # Process message(s) returned from Invoke-HPERedfishAction cmdlet
            if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
            {
                foreach($msgID in $ret.error.'@Message.ExtendedInfo')
                {
                    $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
<#
Clear-IMLExample19 -Address $Address -Credential $cred
Get-IMLExample17 -Address $Address -Credential $cred
#>

function Clear-iLOEventLogExample20
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 20: Clear iLO Event Log'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # Retrieve manager list
    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/managers/' -Session $session
    foreach($mgr in $managers.Members.'@odata.id')
    {
        $managerData = Get-HPERedfishDataRaw -odataid $mgr -Session $session
        # check if logs are available or not
        if($managerData.PSObject.properties.name -notcontains 'LogServices')
        {
            Write-Host 'Logs not available'
        }
        else
        {
            # get the odataid for iLO event logs
            $logServicesOdataId = $managerData.LogServices.'@odata.id'
            $logServicesData = Get-HPERedfishDataRaw -odataid $logServicesOdataId -Session $session
            $requiredIelOdataId = ''
            foreach($link in $logServicesData.Members.'@odata.id')
            {
                $spl = $link.split('`/')
                if($spl[$spl.length-2] -match 'IEL')
                {
                    $requiredIelOdataId = $link
                    break
                }
            }

            # retrieve the target odataid where the POST request is to be sent
            $ielData = Get-HPERedfishDataRaw -odataid $requiredIelOdataId -Session $session
            $clearIelTarget = $ielData.Actions.'#LogService.ClearLog'.target

            #Since there is no property other than 'target' under the 'Action' property, -Data parameter is not required
            # Send the POST request using Invoke-HPERedfishAction cmdlet
            $ret = Invoke-HPERedfishAction -odataid $clearIelTarget -Session $session

            # Process message(s) returned from Invoke-HPERedfishAction cmdlet
            if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
            {
                foreach($msgID in $ret.error.'@Message.ExtendedInfo')
                {
                    $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
<#
Clear-iLOEventLogExample20 -Address $Address -Credential $cred
Get-iLOEventLogExample18 -Address $Address -Credential $cred
#>

function Set-SNMPExample21
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $Mode, # Agentless or Passthru

        [System.Object]
        $AlertsEnabled = $null #use true or false only


    )
    Write-Host 'Example 21: Configure iLO SNMP settings.'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # retrieve list of managers
    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/Managers/' -Session $session
    foreach($mgr in $managers.Members.'@odata.id')
    {
        # retrieve settings of NetworkService data
        $mgrData = Get-HPERedfishDataRaw -odataid $mgr -Session $session
        $netSerOdataId = $mgrData.NetworkProtocol.'@odata.id'
        $netSerData = Get-HPERedfishDataRaw -odataid $netSerOdataId -Session $session
        
        if($netSerData.Oem.Hp.Links.PSObject.properties.name -notcontains 'SNMPService')
        {
            Write-Host 'SNMP services not available in Manager Network Service'
        }
        else
        {
            $snmpSerOdataId = $netSerData.Oem.Hp.Links.SNMPService.'@odata.id'
            
            $snmpSerData = Get-HPERedfishDataRaw -odataid $snmpSerOdataId -Session $session

            # create hashtable object according to the parameters provided by user
            $snmpSetting = @{}
            if($mode -ne '' -and $Mode -ne $null)
            {
                $snmpSetting.Add('Mode',$Mode)
            }
            if($AlertsEnabled -ne $null)
            {
                $snmpSetting.Add('AlertsEnabled',[System.Convert]::ToBoolean($AlertsEnabled))
            }

            # PATCh the settings using Set-HPERedfishData cmdlet
            $ret = Set-HPERedfishData -odataid $snmpSerOdataId -Setting $snmpSetting -Session $session

            # Process message(s) returned from Set-HPERedfishData cmdlet
            if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
            {
                foreach($msgID in $ret.error.'@Message.ExtendedInfo')
                {
                    $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }
    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
## This example is for iLO 4 only.
#Set-SNMPExample21 -Address $Address -Credential $cred -Mode Agentless -AlertsEnabled $false
 
function Get-SchemaExample22
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $odatatype,

        [ValidateSet('en','jp','zh')]
        [System.String]
        $Language = 'en'


    )

    Write-Host 'Example 22: Retrieve schema'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # Retrieve the schema with the odatatype provided by the user
    $sch = Get-HPERedfishSchema -odatatype $odatatype -Language $Language -Session $session
    $sch.properties
    
    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session

}
#Get-SchemaExample22 -Address $Address -Credential $cred -odatatype ComputerSystem

function Get-RegistryExample23
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $RegistryPrefix,

        [System.String]
        $Language = 'en'


    )

    Write-Host 'Example 23: Retrieve registry'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # retrieve list of registries
    $reg = Get-HPERedfishDataRaw -odataid '/redfish/v1/registries/' -Session $session

    # select the registry where the prefix is same as value provided by user in 'RegistryPrefix' parameter
    $reqRegMembers = $reg.Members.'@odata.id' #| ? {$_.Schema.ToString().IndexOf($RegistryPrefix) -eq 0}
    
    # retrieve and display the external reference for the required language
    foreach($reqRegOdataId in $reqRegMembers)
    {
        $reqReg = Get-HPERedfishDataRaw -odataid $reqRegOdataId -Session $session

        # for iLO 5
        $reqRegURI = ($reqReg.Location|?{$_.Language -eq $Language}).uri

        ## for iLO 4 
        #$reqRegURI = ($reqReg.Location|?{$_.Language -eq $Language}).uri.extref

        $reqRegData = Get-HPERedfishDataRaw -odataid $reqRegURI -Session $session
        $reqRegData
    }
    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session

}
#Get-RegistryExample23 -Address $Address -Credential $cred -RegistryPrefix $registryPrefix

function Set-TimeZoneExample24
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $TimeZone
    )

    #NOTE: This will work only if iLO is NOT configured to take time settings from DHCP v4 or v6. Otherwise, error 400 - bad request is thrown.
    Write-Host 'Example 24: Set timezone'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # retrieve manager list
    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/managers/' -Session $session
    foreach($mgr in $managers.Members.'@odata.id')
    {
        # Retrieve DateTimeService odataid and then retrieve the timezone name to display to user
        $mgrData = Get-HPERedfishDataRaw -odataid $mgr -Session $session
        $dtsOdataId = $mgrData.Oem.Hp.Links.DateTimeService.'@odata.id'
        $dtsData = Get-HPERedfishDataRaw -odataid $dtsOdataId -Session $session
        $currTimeZone = $dtsData.TimeZone.Name
        Write-Host "Current timezone $currTimeZone"

        # from list of all timezone, first check if the user entered value is present in this list.
        foreach($tz in $dtsData.TimeZoneList)
        {
            if($tz.Name -eq $TimeZone)
            {
                # User entered timezone value is present.
                # Create timezone hashtable object to PATCH
                $setting = @{'TimeZone'=@{'Name'=$tz.name}}
                
                # PATCH the new setting using Set-HPERedfishData cmdlet
                $ret = Set-HPERedfishData -odataid $dtsOdataId -Setting $setting -Session $session

                # Process message(s) returned from Set-HPERedfishData cmdlet
                if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
                {
                    foreach($msgID in $ret.error.'@Message.ExtendedInfo')
                    {
                        $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                        $status
                    }
                }
                break
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
## Patch using Timezone name is preferred over timezone index. If both are patched, Index field will be ignored
## DHCPv4 should be disabled in active NIC for setting the timezone
#Set-TimeZoneExample24 -Address $Address -Credential $cred -TimeZone 'America/Chicago' 

function Set-iLONTPServerExample25
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.Array]
        $StaticNTPServer
    )

    #NOTE: This will work only if iLO is NOT configured to take time settings from DHCP v4 or v6. Otherwise, error 400 - bad request is thrown. 
    Write-Host 'Example 25: Set NTP server'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # Retrieve manager list
    $managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/managers/' -Session $session
    foreach($mgr in $managers.Members.'@odata.id')
    {
        # retrieve date time details and display current values
        $mgrData = Get-HPERedfishDataRaw -odataid $mgr -Session $session
        $dtsOdataId = $mgrData.Oem.Hp.Links.DateTimeService.'@odata.id'
        $dtsData = Get-HPERedfishDataRaw -odataid $dtsOdataId -Session $session
        Write-Host Current iLO Date and Time setting - $dtsData.ConfigurationSettings
        Write-Host Current iLO NTP Servers - $dtsData.NTPServers

        # Create hashtable object with values for NTPServer
        $setting = @{'StaticNTPServers'=$StaticNTPServer}

        # PATCH new NTPServer data using Set-HPERedfishData
        $ret = Set-HPERedfishData -odataid $dtsOdataId -Setting $setting -Session $session

        # Process message(s) returned from Set-HPERedfishData cmdlet
        if($ret.error.'@Message.ExtendedInfo'.Count -gt 0)
        {
            foreach($msgID in $ret.error.'@Message.ExtendedInfo')
            {
                $status = Get-HPERedfishMessage -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
## DHCPv4 should be disabled in active NIC for setting the StaticNTPServer
#Set-iLONTPServerExample25 -Address $Address -Credential $cred -StaticNTPServer @('192.168.0.1','192.168.0.2')

function Get-PowerMetricExample26
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    #NOTE: This will work only if iLO is NOT configured to take time settings from DHCP v4 or v6
    Write-Host 'Example 26: Retrieve PowerMetrics average watts'

    # Create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential
    
    # retrieve chassis list
    $chassis = Get-HPERedfishDataRaw -odataid '/redfish/v1/chassis/' -Session $session
    foreach($cha in $chassis.Members.'@odata.id')
    {
        # get PowerMetrics odataid, retrieve the data and display
        $chaData = Get-HPERedfishDataRaw -odataid $cha -Session $session
        $powerOdataId = $chaData.Power.'@odata.id'
        $powerData = Get-HPERedfishDataRaw -odataid $powerOdataId -Session $session
        foreach($PowerControl in $powerData.PowerControl)
        {
            Write-Host "$($chaData.Model) AverageConsumedWatts = $($PowerControl.PowerMetrics.AverageConsumedWatts) watts over a $($PowerControl.PowerMetrics.IntervalInMin) minute moving average"
        }
    }

    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session
}
#Get-PowerMetricExample26 -Address $Address -Credential $cred


function Get-ThermalMetricsExample27
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    Write-Host 'Example 27: Get Temperature and Fan details from Thermal Metrics.'
    
    #create session
    $session = Connect-HPERedfish -Address $Address -Credential $Credential

    #retrieve Chassis list
    $chassisList = Get-HPERedfishDataRaw -odataid '/redfish/v1/chassis/' -Session $session
    foreach($chassisOdataId in $chassisList.Members.'@odata.id')
    {
        $chasisData = Get-HPERedfishDataRaw -odataid $ChassisOdataId -Session $session
        
        # get the thermal metrics of the chassis
        $thermalData = Get-HPERedfishDataRaw -odataid $chasisData.Thermal.'@odata.id' -Session $session
        
        # display temperature values
        Write-Host "Temperature: "
        $temps = $thermalData.Temperatures
        $temps
        
        # display fan values        
        Write-Host "Fans: "
        $fans = $thermalData.Fans
        $fans
    }
    Disconnect-HPERedfish -Session $session
}
#Get-ThermalMetricsExample27 -Address $Address -Credential $cred
Enable-HPERedfishCertificateAuthentication


# SIG # Begin signature block
# MIIjqAYJKoZIhvcNAQcCoIIjmTCCI5UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBzQFZ73XBfqenX
# fesN0iu6GBSmekfs+ohKaFhHtMF9kKCCHrMwggPuMIIDV6ADAgECAhB+k+v7fMZO
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
# AhEA3GTlJ1A9M/BwMzcyvM3YkDANBgkqhkiG9w0BAQsFADB9MQswCQYDVQQGEwJH
# QjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3Jk
# MRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDEjMCEGA1UEAxMaQ09NT0RPIFJT
# QSBDb2RlIFNpZ25pbmcgQ0EwHhcNMTcwODE0MDAwMDAwWhcNMTgwODE0MjM1OTU5
# WjCB0jELMAkGA1UEBhMCVVMxDjAMBgNVBBEMBTk0MzA0MQswCQYDVQQIDAJDQTES
# MBAGA1UEBwwJUGFsbyBBbHRvMRwwGgYDVQQJDBMzMDAwIEhhbm92ZXIgU3RyZWV0
# MSswKQYDVQQKDCJIZXdsZXR0IFBhY2thcmQgRW50ZXJwcmlzZSBDb21wYW55MRow
# GAYDVQQLDBFIUCBDeWJlciBTZWN1cml0eTErMCkGA1UEAwwiSGV3bGV0dCBQYWNr
# YXJkIEVudGVycHJpc2UgQ29tcGFueTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAMV6msMHbQ1HoKkqIAakZl0zTmJcEYdyWMz7vEGKHttpw9hDmejCpUeY
# W/9BaUu2mI1yW/XC3F2GeMb0ImUo1Yejb85tPbPVTc8j8nTGrlLQ+kHGjewhh14O
# StBDXFnoD0dO9VSYI0l0zNRJxBz7XBwvVhIqCwwuKHl7GqU833fGLKtCO/pmOd6D
# pqiBoSehq7Dpct1g70wSLkjNmzQJpaFBGdB8gpo8EPqLqnJ+LGvwM0x83O4o60f+
# uiRgPn//TgC4BQ1LqLWcyxwlzPSNx+mOn2TnDIXrIUdLnVSFFo3b2gWg37XWT2u+
# UaAIIeC1vNGio6GlggOAZtpB1Fw1ixUCAwEAAaOCAY0wggGJMB8GA1UdIwQYMBaA
# FCmRYP+KTfrr+aZquM/55ku9Sc4SMB0GA1UdDgQWBBRY98jf5AH19heGv91inQ4Q
# kGetXjAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggr
# BgEFBQcDAzARBglghkgBhvhCAQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIx
# AQIBAwIwKzApBggrBgEFBQcCARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9D
# UFMwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5jb20vQ09N
# T0RPUlNBQ29kZVNpZ25pbmdDQS5jcmwwdAYIKwYBBQUHAQEEaDBmMD4GCCsGAQUF
# BzAChjJodHRwOi8vY3J0LmNvbW9kb2NhLmNvbS9DT01PRE9SU0FDb2RlU2lnbmlu
# Z0NBLmNydDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuY29tb2RvY2EuY29tMA0G
# CSqGSIb3DQEBCwUAA4IBAQASJVM4nkMiKaayG12Zi0fsPjnnp7gmBMFQL1oknbS6
# TcGH9gwHWJQcYmwDHhUm0lU25Vts62PtSkawnSsLS1Lc2rvxBsv4vuqZA7+2NKUo
# EY4Ac4KzZ9hQEEftROmLpJgQwt5z4CMsDqd6X8fwGix20lsOXjVguLZCXP8IoKEO
# g/BnSflxJwsUqlMCWPG5h9uPK58sR8gWffwWN4zr9bb/AkaRS8u4L1Xsz9vGhXqm
# QAmBCehSQpOW5xJArnRUU0KgyZ0kT8RALxgcOs/ReiwxPnVxDLvERym9hy6Bmruu
# OmsfMHhArb6ID4XfRzo8qrpzhlDmvcyIwCIVRuPH3RTfMIIFdDCCBFygAwIBAgIQ
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
# U2lnbmluZyBDQQIRANxk5SdQPTPwcDM3MrzN2JAwDQYJYIZIAWUDBAIBBQCgfDAQ
# BgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgDSo1Nxu+
# ztZXPCC7vkXPcQEn3vJwot/nidbILc2GeA8wDQYJKoZIhvcNAQEBBQAEggEAjPQE
# HDlAR1Bec1dh35n8ZT6RrcpDxMPtvXsdQO0VlDXFz4rgCiUhPjQeAMywRmXThUaQ
# WIX5ry9dMUwNt3kMbz9NFj42mfLKkB/+9HaNdQFBn7SvCl+Z/CgMB8ent2DDF1ug
# LtryOSzNF3/9iD9N9rjT9V7JH748bsc1bjgigy4QE4d7ZK4oOnyVdB5SS1jYHsP3
# srcC6Kb6n4odzD1iyoao3puEchGDCMVUwOZ2O504jZG5VMFUEectx1DR6/uDM333
# svJRVlaTdeshWRbtQ8p+cGSfY6ALjVDC/wWaqEEGU1BjHFZJDmg5su3SSJC6dmXu
# R3JYHBG4S2xKm5bf86GCAgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4x
# CzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4G
# A1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAO
# z/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xODAyMDEyMTA2NTFaMCMGCSqGSIb3DQEJ
# BDEWBBTIxMfrumtmQULCbdmVg51Mc9JLyzANBgkqhkiG9w0BAQEFAASCAQAqxEJJ
# kZ9+rGHSFeD4+IfEtP9kOW7Q4ps9DcC4sQMODEBJovSuQt8XFw1NW5uiLULTa7VL
# 6e+w+exfoxnn3ZIMTU4CtuJAem0COT4+H7CcA+RQBuJV6+pFMbZO7cgWys4RGUqD
# 4zqZhoiyrQhwiP8uJcIyuvdv2x427c80RiArhzVnPjaUPl0/jXIvEfxt3e7KCuQ8
# 7fB9vSivTHevgx70gr7DQgCdAKPxkuPVO/O5FtRaph308tTX2lolYx8s9AKXGRZA
# 2pj4R5cqbJzL21JURvCElFNnlSJ0P3wyDmApCrA0BXCcX+q1UdikSpDnyLizICG6
# nzNiHDt5+KTaW9+V
# SIG # End signature block
