<#
(c) Copyright 2016 Hewlett Packard Enterprise Development LP

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
        $secureBootOdataId = $sysData.Oem.Hp.Links.SecureBoot.'@odata.id'
    
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
## NOTE: check the boot targets supported in BootSourceOverrideSupported $data.Boot.BootSourceOverrideSupported. The value is case sensitive. 
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
    $oem.Add('Hp',$hp)

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
            if($hp.Count -gt 0){$oem.Add('Hp',$hp)}

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
        $mySesOdataId = $sesData.Oem.Hp.Links.MySession.'@odata.id'
        foreach($mySes in $mySesOdataId)
        {
            $mySesData = Get-HPERedfishDataRaw $mySes -Session $session
            if($mySesData.Oem.Hp.MySession -eq $true)
            {
                $mySesData
                $mySesData.oem.hp
            }
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
                        $oem = @{'Hp'=@{'BootOnNextServerReset'=[System.Convert]::ToBoolean($BootOnNextReset)}}
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
        }

        if($selectedNICOdataId -ne '')
        {
            $req = @{'Oem'=@{'Hp'=@{'NICEnabled' = $true}}}
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
        $reqRegURI = ($reqReg.Location|?{$_.Language -eq $Language}).uri.extref
        $reqRegData = Get-HPERedfishDataRaw -odataid $reqRegURI -Session $session
        $reqRegData
    }
    # Disconnect the session after use
    Disconnect-HPERedfish -Session $session

}
#Get-RegistryExample23 -Address $Address -Credential $cred -RegistryPrefix HpBiosAttributeRegistryP89

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
# MIIkXwYJKoZIhvcNAQcCoIIkUDCCJEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAN93n8DmRo9tGM
# +srjKTZT36MzFnisNXcqv2I1ZF0in6CCHtQwggQUMIIC/KADAgECAgsEAAAAAAEv
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
# ktSzREZkjIdPFmMHMUtjsN/zMIIEnzCCA4egAwIBAgISESEGoIHTP9h65YJMwWtS
# CU4DMA0GCSqGSIb3DQEBBQUAMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFtcGluZyBD
# QSAtIEcyMB4XDTE1MDIwMzAwMDAwMFoXDTI2MDMwMzAwMDAwMFowYDELMAkGA1UE
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
# /9zjvv+D5vSFm7DdatYUqcEwDQYJKoZIhvcNAQEFBQADggEBAIAy3AeNHKCcnTwq
# 6D0hi1mhTX7MRM4Dvn6qvMTme3O7S/GI2pBOdTcoOGO51ysPVKlWznc5lzBzzZvZ
# 2QVFHI2kuANdT9kcLpjg6Yjm7NcFflYqe/cWW6Otj5clEoQbslxjSgrS7xBUR4KE
# NWkonAzkHxQWJPp13HRybk7K42pDr899NkjRvekGkSwvpshx/c+92J0hmPyv294i
# jK+n83fvndyjcEtEGvB4hR7ypYw5tdyIHDftrRT1Bwsmvb5tAl6xuLBYbIU6Dfb/
# WicMxd5T51Q8VkzJTkww9vJc+xqMwoK+rVmR9htNVXvPWwHc/XrTbyNcMkebAfPB
# URRGipswggVMMIIDNKADAgECAhMzAAAANdjVWVsGcUErAAAAAAA1MA0GCSqGSIb3
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
# oy0Lhd6sjOD5Z3CfcXkCMfdhoinEMIIFaTCCBFGgAwIBAgIQK1xBJ0ChlqTlel5/
# XafHajANBgkqhkiG9w0BAQsFADB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3Jl
# YXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01P
# RE8gQ0EgTGltaXRlZDEjMCEGA1UEAxMaQ09NT0RPIFJTQSBDb2RlIFNpZ25pbmcg
# Q0EwHhcNMTUxMjE3MDAwMDAwWhcNMTYxMjE2MjM1OTU5WjCB0jELMAkGA1UEBhMC
# VVMxDjAMBgNVBBEMBTk0MzA0MQswCQYDVQQIDAJDQTESMBAGA1UEBwwJUGFsbyBB
# bHRvMRwwGgYDVQQJDBMzMDAwIEhhbm92ZXIgU3RyZWV0MSswKQYDVQQKDCJIZXds
# ZXR0IFBhY2thcmQgRW50ZXJwcmlzZSBDb21wYW55MRowGAYDVQQLDBFIUCBDeWJl
# ciBTZWN1cml0eTErMCkGA1UEAwwiSGV3bGV0dCBQYWNrYXJkIEVudGVycHJpc2Ug
# Q29tcGFueTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMuRzybUEbn9
# Y5tKWlD7eAAWRzoVt4RAGpBHY863qtquCVG0Wtq80GDIIL0WVgnxB+kgLBzeXwU3
# s9YXI37QaBYJt5NDuGEdQ2qpNT64V9ZuKZrhTg64sNx6ONmquRYkXdHp6mVZ3Rvr
# 9OqEg3plx+VMGow5Vfa0zfobabpR3MUgQsQSmB5MP/cmNVVrkzdQmgeYxgXpGxKi
# yYDkTMlLVKaX0NoGnx3HQj+Yw7oILbV9veff4rfjz7BRDEsXa/pjwtOlTgCO6sv8
# J7HMdM7v2+qRNA944cBnxAAR2VlrG50/vkUgwMsPv4H/16pwbkzxvap5OspNhs6o
# 7G/5MF/7DI8CAwEAAaOCAY0wggGJMB8GA1UdIwQYMBaAFCmRYP+KTfrr+aZquM/5
# 5ku9Sc4SMB0GA1UdDgQWBBQ7WJcg/m9cEGQtGzvFwl5wvY5r4zAOBgNVHQ8BAf8E
# BAMCB4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgB
# hvhCAQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIxAQIBAwIwKzApBggrBgEF
# BQcCARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9DUFMwQwYDVR0fBDwwOjA4
# oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5jb20vQ09NT0RPUlNBQ29kZVNpZ25p
# bmdDQS5jcmwwdAYIKwYBBQUHAQEEaDBmMD4GCCsGAQUFBzAChjJodHRwOi8vY3J0
# LmNvbW9kb2NhLmNvbS9DT01PRE9SU0FDb2RlU2lnbmluZ0NBLmNydDAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBCwUAA4IB
# AQCJSO8rO8/OixqDrdSrsj+AO1UH4zLhQzv/K8OPWSw2+PkyEfvPoe4J6JJ5mNVQ
# 9fWNvFatUv6XcZJ5bv6SmQ0vWbXHNrMvrBtq9hGvJJKFqRhEfz0YM9yTHJUIFMUg
# aAVLRt6/b9k8lJkVPy5IghVGZ5G0AlDpovzZKBxYfJlEEJc6hkjjGBMjkj3ABd21
# jiuAITinnnBsUfUFehZPQSEHI8mlPyB6QboZk7Lz4Yy7emfcfFZB2s7qaWRhZrzK
# kFnzUUZuYr+sEcMPUvORC+qPXSLI9xGH1Y6v88g7DL19bVtODXg3k6BcmxLfPuX+
# CkksoTIYIPX772dsbTfGU+wBMIIFdDCCBFygAwIBAgIQJ2buVutJ846r13Ci/ITe
# IjANBgkqhkiG9w0BAQwFADBvMQswCQYDVQQGEwJTRTEUMBIGA1UEChMLQWRkVHJ1
# c3QgQUIxJjAkBgNVBAsTHUFkZFRydXN0IEV4dGVybmFsIFRUUCBOZXR3b3JrMSIw
# IAYDVQQDExlBZGRUcnVzdCBFeHRlcm5hbCBDQSBSb290MB4XDTAwMDUzMDEwNDgz
# OFoXDTIwMDUzMDEwNDgzOFowgYUxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVh
# dGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGjAYBgNVBAoTEUNPTU9E
# TyBDQSBMaW1pdGVkMSswKQYDVQQDEyJDT01PRE8gUlNBIENlcnRpZmljYXRpb24g
# QXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAkehUktIK
# VrGsDSTdxc9EZ3SZKzejfSNwAHG8U9/E+ioSj0t/EFa9n3Byt2F/yUsPF6c947AE
# Ye7/EZfH9IY+Cvo+XPmT5jR62RRr55yzhaCCenavcZDX7P0N+pxs+t+wgvQUfvm+
# xKYvT3+Zf7X8Z0NyvQwA1onrayzT7Y+YHBSrfuXjbvzYqOSSJNpDa2K4Vf3qwbxs
# tovzDo2a5JtsaZn4eEgwRdWt4Q08RWD8MpZRJ7xnw8outmvqRsfHIKCxH2XeSAi6
# pE6p8oNGN4Tr6MyBSENnTnIqm1y9TBsoilwie7SrmNnu4FGDwwlGTm0+mfqVF9p8
# M1dBPI1R7Qu2XK8sYxrfV8g/vOldxJuvRZnio1oktLqpVj3Pb6r/SVi+8Kj/9Lit
# 6Tf7urj0Czr56ENCHonYhMsT8dm74YlguIwoVqwUHZwK53Hrzw7dPamWoUi9PPev
# tQ0iTMARgexWO/bTouJbt7IEIlKVgJNp6I5MZfGRAy1wdALqi2cVKWlSArvX31Bq
# VUa/oKMoYX9w0MOiqiwhqkfOKJwGRXa/ghgntNWutMtQ5mv0TIZxMOmm3xaG4Nj/
# QN370EKIf6MzOi5cHkERgWPOGHFrK+ymircxXDpqR+DDeVnWIBqv8mqYqnK8V0rS
# S527EPywTEHl7R09XiidnMy/s1Hap0flhFMCAwEAAaOB9DCB8TAfBgNVHSMEGDAW
# gBStvZh6NLQm9/rEJlTvA73gJMtUGjAdBgNVHQ4EFgQUu69+Aj36pvE8hI6t7jiY
# 7NkyMtQwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wEQYDVR0gBAow
# CDAGBgRVHSAAMEQGA1UdHwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwudXNlcnRydXN0
# LmNvbS9BZGRUcnVzdEV4dGVybmFsQ0FSb290LmNybDA1BggrBgEFBQcBAQQpMCcw
# JQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcN
# AQEMBQADggEBAGS/g/FfmoXQzbihKVcN6Fr30ek+8nYEbvFScLsePP9NDXRqzIGC
# JdPDoCpdTPW6i6FtxFQJdcfjJw5dhHk3QBN39bSsHNA7qxcS1u80GH4r6XnTq1dF
# DK8o+tDb5VCViLvfhVdpfZLYUspzgb8c8+a4bmYRBbMelC1/kZWSWfFMzqORcUx8
# Rww7Cxn2obFshj5cqsQugsv5B5a6SE2Q8pTIqXOi6wZ7I53eovNNVZ96YUWYGGjH
# XkBrI/V5eu+MtWuLt29G9HvxPUsE2JOAWVrgQSQdso8VYFhH2+9uRv0V9dlfmrPb
# 2LjkQLPNlzmuhbsdjrzch5vRpu/xO28QOG8wggXgMIIDyKADAgECAhAufIfMDpNK
# Uv6U/Ry3zTSvMA0GCSqGSIb3DQEBDAUAMIGFMQswCQYDVQQGEwJHQjEbMBkGA1UE
# CBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQK
# ExFDT01PRE8gQ0EgTGltaXRlZDErMCkGA1UEAxMiQ09NT0RPIFJTQSBDZXJ0aWZp
# Y2F0aW9uIEF1dGhvcml0eTAeFw0xMzA1MDkwMDAwMDBaFw0yODA1MDgyMzU5NTla
# MH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAO
# BgNVBAcTB1NhbGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSMwIQYD
# VQQDExpDT01PRE8gUlNBIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAKaYkGN3kTR/itHd6WcxEevMHv0xHbO5Ylc/k7xb458e
# JDIRJ2u8UZGnz56eJbNfgagYDx0eIDAO+2F7hgmz4/2iaJ0cLJ2/cuPkdaDlNSOO
# yYruGgxkx9hCoXu1UgNLOrCOI0tLY+AilDd71XmQChQYUSzm/sES8Bw/YWEKjKLc
# 9sMwqs0oGHVIwXlaCM27jFWM99R2kDozRlBzmFz0hUprD4DdXta9/akvwCX1+XjX
# jV8QwkRVPJA8MUbLcK4HqQrjr8EBb5AaI+JfONvGCF1Hs4NB8C4ANxS5Eqp5klLN
# hw972GIppH4wvRu1jHK0SPLj6CH5XkxieYsCBp9/1QsCAwEAAaOCAVEwggFNMB8G
# A1UdIwQYMBaAFLuvfgI9+qbxPISOre44mOzZMjLUMB0GA1UdDgQWBBQpkWD/ik36
# 6/mmarjP+eZLvUnOEjAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIB
# ADATBgNVHSUEDDAKBggrBgEFBQcDAzARBgNVHSAECjAIMAYGBFUdIAAwTAYDVR0f
# BEUwQzBBoD+gPYY7aHR0cDovL2NybC5jb21vZG9jYS5jb20vQ09NT0RPUlNBQ2Vy
# dGlmaWNhdGlvbkF1dGhvcml0eS5jcmwwcQYIKwYBBQUHAQEEZTBjMDsGCCsGAQUF
# BzAChi9odHRwOi8vY3J0LmNvbW9kb2NhLmNvbS9DT01PRE9SU0FBZGRUcnVzdENB
# LmNydDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuY29tb2RvY2EuY29tMA0GCSqG
# SIb3DQEBDAUAA4ICAQACPwI5w+74yjuJ3gxtTbHxTpJPr8I4LATMxWMRqwljr6ui
# 1wI/zG8Zwz3WGgiU/yXYqYinKxAa4JuxByIaURw61OHpCb/mJHSvHnsWMW4j71RR
# LVIC4nUIBUzxt1HhUQDGh/Zs7hBEdldq8d9YayGqSdR8N069/7Z1VEAYNldnEc1P
# AuT+89r8dRfb7Lf3ZQkjSR9DV4PqfiB3YchN8rtlTaj3hUUHr3ppJ2WQKUCL33s6
# UTmMqB9wea1tQiCizwxsA4xMzXMHlOdajjoEuqKhfB/LYzoVp9QVG6dSRzKp9L9k
# R9GqH1NOMjBzwm+3eIKdXP9Gu2siHYgL+BuqNKb8jPXdf2WMjDFXMdA27Eehz8uL
# qO8cGFjFBnfKS5tRr0wISnqP4qNS4o6OzCbkstjlOMKo7caBnDVrqVhhSgqXtEtC
# tlWdvpnncG1Z+G0qDH8ZYF8MmohsMKxSCZAWG/8rndvQIMqJ6ih+Mo4Z33tIMx7X
# ZfiuyfiDFJN2fWTQjs6+NX3/cjFNn569HmwvqI8MBlD7jCezdsn05tfDNOKMhyGG
# Yf6/VXThIXcDCmhsu+TJqebPWSXrfOxFDnlmaOgizbjvmIVNlhE8CYrQf7woKBP7
# aspUjZJczcJlmAaezkhb1LU3k0ZBfAfdz/pD77pnYf99SeC7MH1cgOPmFjlLpzGC
# BOEwggTdAgEBMIGRMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1h
# bmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBDQSBM
# aW1pdGVkMSMwIQYDVQQDExpDT01PRE8gUlNBIENvZGUgU2lnbmluZyBDQQIQK1xB
# J0ChlqTlel5/XafHajANBglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAA
# MBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
# BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDcldrYQF5jnjbVz+Sz3xh9iJY3Rts5
# fv1mJfZ2QTag5DANBgkqhkiG9w0BAQEFAASCAQBu3XAz2epVV/Z6tPR1ODlJBp0a
# 61Il1VoEF3hPfSyOItuE+15PHyw3doESCRBM5hx3NwiKN7SrRaOp0+8RxOBNHRdk
# 3tXkH8y03v8lVzBXOcL2P+Xu+fYYxXje5PAGNVO+1t0SI/DUKI6yW8ZH3oAiRK1B
# HnNC59C7DvMinb1eTtPVvJtn4gapJan2qVfbDT8nZAGFbGOQbpZBmBbNwsA99dUp
# HVPxP4x8W/QuPLS5UgexOg1ZZQ4g2QA/nTSaOQfs9NxyS3qRRXt/j1Lz9i/9FbO0
# fjJQGfnFT5egoXG4D2KU81BcJmxVSIzIZgcKSy5/Eap8JCcwOGDOsImTINCSoYIC
# ojCCAp4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAX
# BgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGlt
# ZXN0YW1waW5nIENBIC0gRzICEhEhBqCB0z/YeuWCTMFrUglOAzAJBgUrDgMCGgUA
# oIH9MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE2
# MDUyMzE4MjQ1M1owIwYJKoZIhvcNAQkEMRYEFNrmrw3D//Xd3mNMNkI9zROTo24h
# MIGdBgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUs2MItNTN7U/PvWa5Vfrjv7Es
# KeYwbDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYt
# c2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh
# BqCB0z/YeuWCTMFrUglOAzANBgkqhkiG9w0BAQEFAASCAQBrJDoyioJtatNztzNE
# mDKMGBQZCnAacL7WHYXujwVe7WFKY+29WEYokHNwh2saMw7olt34ijrPKUOXU25Q
# tWRD6q3V82SFN7pRT0r51/bOe3hj0UmsZysOikM7ju47KP1PeZ0jYlw6a+roXuTh
# EPDEP+9dNLIYUlR9giQKtyUvmpINJoxfFYl9QmNQRHMVxlFM/tzOUc+FC1nHt3fg
# 5CzLfRM+i9Hc81QGjAfSCqyCp8f6c7FVnwzUu7SqJwInUNKIyx8iRsPKlTd5aj/w
# WhR2+idnwKggGyD+TPuOkGyUAnyZqZ0/pYdcjKt7yaXxg/HRHOxBL7eHoOzN6T1D
# +tvi
# SIG # End signature block
