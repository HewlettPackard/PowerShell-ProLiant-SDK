<#
(c) Copyright 2015 Hewlett-Packard Development Company, L.P. All rights reserved.
Licensed under the Apache License, Version 2.0 (the "License");
You may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 




These examples use HP REST PowerShell cmdlets available at http://www.powershellgallery.com/packages/HPRESTCmdlets/.  
These scripts provide examples of using HP RESTful API on HP iLO for common use cases.

These examples use the following base set of cmdlets:

Connect-HPREST
Disconnect-HPREST
Edit-HPRESTData
Find-HPREST
Format-HPRESTDir
Get-HPRESTData
Get-HPRESTDataRaw
Get-HPRESTDir
Get-HPRESTError
Get-HPRESTHttpData
Get-HPRESTIndex
Get-HPRESTSchema
Get-HPRESTSchemaExtref
Get-HPRESTUriFromHref
Invoke-HPRESTAction
Remove-HPRESTData
Set-HPRESTData

#>


 
#iLO IP address and credentials to access the iLO
$Address = '192.184.217.212'
$cred = Get-Credential


function Set-BIOSExample1
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $BIOSProperty,

        [System.String]
        $Value
    )

    Write-Host 'Example 1: Change a BIOS Setting'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    #Get list of systems
    $systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($sys in $systems.links.member.href) # rest/v1/systems/1, rest/v1/system/2
    {
        #Get BIOS URI from system data
        $data = Get-HPRESTDataRaw -Href $sys -Session $session
        $biosURI = $data.Oem.Hp.links.BIOS.href
    
        #get BIOS Data
        $biosData = Get-HPRESTDataRaw -Href $biosURI -Session $session

        #if property to be modified is not present in the bios data, then print error message and return
        if(-not(($biosData|Get-Member).Name -contains $BIOSProperty))
        {
            Write-Host "Property $BIOSProperty is not supported on this system"
        }
        else
        {
            #Get setting href to update bios property. For bios, property can be updated in the settings href only. Other data may or may not have setting href

            #creating setting object
            $biosSetting = @{}
            $biosSetting.Add($BIOSProperty,$Value)
            
            #updating setting in system bios settings
            $ret = Set-HPRESTData -Href $biosURI -Setting $biosSetting -Session $session
        
            # processing message obtained by executing Set- cmdlet
            if($ret.Messages.Count -gt 0)
            {
                foreach($msgID in $ret.Messages)
                {
                    $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }

    # disconnecting the session after use
    Disconnect-HPREST -Session $session
}
#Set-BIOSExample1 -Address $Address -Credential $cred -BIOSProperty 'AdminName' -Value 'test admin'

function Reset-ServerExample2
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

    Write-Host 'Example 2: Reset the server.'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    # getting system list
    $systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($sys in $systems.links.member.href) # rest/v1/systems/1, rest/v1/system/2
    {
        # creating setting object to invoke reset action. 
        # Details of invoking reset (or other possible actions) is present in 'AvailableActions' of system data  
        $dataToPost = @{}
        $dataToPost.Add('Action',$Action)
        $dataToPost.Add($PropertyName,$PropertyValue)
        
        # Sending reset request to system using 'POST' in Invoke-HPRESTAction
        $ret = Invoke-HPRESTAction -Href $sys -Data $dataToPost -Session $session

        # processing message obtained by executing Set- cmdlet
        if($ret.Messages.Count -gt 0)
        {
            foreach($msgID in $ret.Messages)
            {
                $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }

    # disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Reset-ServerExample2 -Address $Address -Credential $cred -Action Reset -PropertyName ResetType -PropertyValue ForceRestart

function Set-SecureBootExample3
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

    Write-Host 'Example 3: Enable/Disable UEFI secure boot'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    $systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($sys in $systems.links.member.href) # rest/v1/systems/1, rest/v1/system/2
    {
        #Get secure boot URI
        $sysData = Get-HPRESTDataRaw -Href $sys -Session $session
        $secureBootURI = $sysData.Oem.Hp.links.SecureBoot.href
    
        #get secure boot data and display original value
        $secureBootData = Get-HPRESTDataRaw -Href $secureBootURI -Session $session
        $secureBootData

        #if property to be modified is not present in the secure boot data, then print error message and return
        if(-not(($secureBootData|Get-Member).Name -Contains $SecureBootProperty))
        {
            Write-Host "Property $SecureBootProperty is not supported on this system"
        }
        else
        {
            # use Set cmdlet at Secure Boot href to update secure boot property. Here only boolean values are allowed for Value parameter
            # creating hashtable object with property and value
            $secureBootSetting = @{$SecureBootProperty=$Value}
            
            # Execute Set- cmdlet to post enable/disable setting at href for secure boot
            $ret = Set-HPRESTData -Href $secureBootURI -Setting $SecureBootSetting -Session $session
            
            # processing message obtained by executing Set- cmdlet
            if($ret.Messages.Count -gt 0)
            {
                foreach($msgID in $ret.Messages)
                {
                    $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }

            # get and display updated value of the property
            $secureBootData = Get-HPRESTDataRaw -Href $secureBootURI -Session $session
            $secureBootData        
        }
    }

    # disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Set-SecureBootExample3 -Address $Address -Credential $cred -SecureBootProperty 'SecureBootEnable' -Value $true
  
function Set-BIOSDefaultExample4
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.Object]
        $InitializationSetting
    )

    Write-Host 'Example 4: Set default BIOS settings'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    $systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($sys in $systems.links.member.href) # rest/v1/systems/1, rest/v1/system/2
    {
        #Get BIOS URI
        $sysData = Get-HPRESTDataRaw -Href $sys -Session $session
        $biosURI = $sysData.Oem.Hp.links.BIOS.href
    
        #get BIOS Data and obtain the setting href from it
        $biosData = Get-HPRESTDataRaw -Href $biosURI -Session $session
        $biosSettingURI = $biosData.links.settings.href
        
        # use BIOS setting URI to obtain setting data
        $biosSettingData = Get-HPRESTDataRaw -Href $biosSettingURI -Session $session

        # create bios setting object
        $newBiosSetting=@{}
        $newBiosSetting.Add('BaseConfig','Default')

        # preserve the Type property from the existing BIOS settings to avoid error
        $newBiosSetting.Add('Type',$biosSettingData.Type)
        
        # add other optional initialization settings provided by the user
        if(-not ($InitializationSetting -eq '' -or $InitializationSetting -eq $null))
        {
            if($InitializationSetting.GetType().ToString() -eq 'System.Management.Automation.PSCustomObject')
            {
                foreach($prop in $InitializationSetting.PSObject.Properties)
                {
                    $newBiosSetting.Add($prop.Name,$prop.Value)
                }
            }
            elseif($InitializationSetting.GetType().ToString() -eq 'System.Collections.Hashtable')
            {
                foreach($ky in $InitializationSetting.Keys)
                {
                    $newBiosSetting.Add($ky,$InitializationSetting[$ky])
                }
            }
            else
            {
                Write-Host 'Invalid input type for InitializationSetting parameter. Use PSObject or PowerShell Hashtable' -ForegroundColor red
            }
        }

        # execure HTTP PUT command using Edit-HPRESTData cmdlet to set BIOS default settings
        $ret = Edit-HPRESTData -Href $biosSettingURI -Setting $newBiosSetting -Session $session
        
        # process returned message from Edit-HPRESTData cmdlet
        if($ret.Messages.Count -gt 0)
        {
            foreach($msgID in $ret.Messages)
            {
                $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }

    # disconnect the session after use
    Disconnect-HPREST -Session $session
}
<#
Set-BIOSDefaultExample4 -Address $Address -Credential $cred
## reset makes the BIOS property change effective
Reset-ServerExample2 -Address $Address -Credential $cred -Action Reset -PropertyName ResetType -PropertyValue ForceRestart
#>

function Set-BootOrderExample5
{
# Changes the boot order by swapping the first two boot options in the persistant boot order list
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    Write-Host 'Example 5: Set boot order (UEFI)'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    $systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($sys in $systems.links.member.href) # rest/v1/systems/1, rest/v1/system/2
    {
        #Get BIOS URI
        $sysData = Get-HPRESTDataRaw -Href $sys -Session $session
        $biosURI = $sysData.Oem.Hp.links.BIOS.href
    
        #get BIOS Data
        $biosData = Get-HPRESTDataRaw -Href $biosURI -Session $session
    
        $bootURI = $biosData.links.Boot.href
        $bootData = Get-HPRESTDataRaw -Href $bootURI -Session $session
        $bootData.PersistentBootConfigOrder

        #if property to be modified is not present in the bios data, then print error message and return
        if(-not(($bootData|Get-Member).Name.Contains('PersistentBootConfigOrder')))
        {
            Write-Host 'Property PersistentBootConfigOrder is not supported on this system'
        }
        else
        {
            # changing boot order by interchanging first and second items in the list. Other orders can also be used 
            $bootOrder = $bootData.PersistentBootConfigOrder # |ConvertFrom-Json
            $temp = $bootOrder[0]
            $bootorder[0] = $bootOrder[1]
            $bootOrder[1] = $temp

            # Getting the href location where the order change has to be 'PATCHed'
            $bootSettingURI = $bootData.links.settings.href
            
            # create object to PATCH
            $persistentBootConfig = @{'PersistentBootConfigOrder'=$bootOrder}

            # execute HTTP PATCH operation using Set-HPRESTData cmdlet
            $ret = Set-HPRESTData -Href $bootSettingURI -Setting $persistentBootConfig -Session $session
            
            # process returned message from Set-HPRESTData cmdlet
            if($ret.Messages.Count -gt 0)
            {
                foreach($msgID in $ret.Messages)
                {
                    $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }

    # disconnect the session after use
    Disconnect-HPREST -Session $session
}
<#
#---------------------------------------------------------------------------------------------#

## change boot order. Internally the example swaps first and second boot targets.
Set-BootOrderExample5 -Address $Address -Credential $cred
##reset maked the boot order effective
Reset-ServerExample2 -Address $Address -Credential $cred -Action Reset -PropertyName ResetType -PropertyValue ForceRestart

#### wait for server to reboot and POST. (Change sleep time as required)
Start-Sleep -Seconds 300

## change boot order to original by swapping back the first two boot targets
Set-BootOrderExample5 -Address $Address -Credential $cred
##reset makes the boot order effective
Reset-ServerExample2 -Address $Address -Credential $cred -Action Reset -PropertyName ResetType -PropertyValue ForceRestart
#---------------------------------------------------------------------------------------------#
#>

function Set-TempBootOrderExample6
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

    Write-Host 'Example 6: Set one-time(temporary)boot order'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    #Get system list
    $systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($sys in $systems.links.member.href) # rest/v1/systems/1, rest/v1/system/2
    {
        # get boot data for the system
        $data = Get-HPRESTDataRaw -Href $sys -Session $session
        $data.Boot

        # print available boot targets
        Write-Host 'Supported boot targets are' $data.boot.BootSourceOverrideSupported
        
        if(-not($data.Boot.BootSourceOverrideSupported  -Contains $BootTarget))
        {
            # if user provided not supported then print error
            Write-Host "$BootTarget not supported"
        }
        else
        {
            # create object to PATCH
            $tempBoot = @{'BootSourceOverrideTarget'=$BootTarget}
            $OneTimeBoot = @{'Boot'=$tempBoot}

            # PATCH the data using Set-HPRESTData cmdlet
            $ret = Set-HPRESTData -Href $sys -Setting $OneTimeBoot -Session $session
            
            #process message returned by Set-HPRESTData cmdlet
            if($ret.Messages.Count -gt 0)
            {
                foreach($msgID in $ret.Messages)
                {
                    $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }

            #get and print updated value
            $bootData = Get-HPRESTDataRaw -Href $sys -Session $session
            $bootData.Boot    
        }
    }

    # disconnect the session after use
    Disconnect-HPREST -Session $session
}
## NOTE: check the boot targets supported in BootSourceOverrideSupported $data.Boot.BootSourceOverrideSupported. The value is case sensitive. 
## E.g. Pxe will work, pxe will not
#Set-TempBootOrderExample6 -Address $Address -Credential $cred -BootTarget 'Hdd'

function Get-iLOMACAddressExample7
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    Write-Host "Example 7: Find iLO's MAC addresses"
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    $mgr = Get-HPRESTDataRaw -Href 'rest/v1/managers' -Session $session
    foreach($hrefVal in $mgr.links.member.href) # rest/v1/systems/1, rest/v1/system/2
    {
        #Get manager data
        $managerData = Get-HPRESTDataRaw -Href $hrefVal -Session $session
        
        # retrieve ethernet NIC details
        $nicURI = $managerData.links.EthernetNICs.href
        $nicData = Get-HPRESTDataRaw -Href $nicURI -Session $session

        foreach($nic in $nicData.items)
        {
            Write-Host $managerData.Model - $nic.Name - $nic.MacAddress 
        }
    }

    # disconnect session after use
    Disconnect-HPREST -Session $session
}
#Get-iLOMACAddressExample7 -Address $Address -Credential $cred

function Add-iLOUserAccountExample8
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

    Write-Host 'Example 8: Create an iLO user account.'

    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    # Get AccountService data to obtain Accounts href
    $accData = Get-HPRESTDataRaw -Href 'rest/v1/AccountService' -Session $session
    $accURI = $accData.links.Accounts.href

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

    # execute HTTP POST method using Invoke-HPRESTAction to add user data at Accounts href
    $ret = Invoke-HPRESTAction -Href $accURI -Data $user -Session $session
    
    # process messages returned by Invoke-HPRESTAction cmdlet
    if($ret.Messages.Count -gt 0)
    {
        foreach($msgID in $ret.Messages)
        {
            $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
            $status
        }
    }
    
    # Print the list of users. New user will be in this list
    $accData = Get-HPRESTDataRaw -Href $accData.links.Accounts.href -Session $session
    $accData.Items

    # disconnect session after use
    Disconnect-HPREST -Session $session
}
#Add-iLOUserAccountExample8 -Address $Address -Credential $cred -newiLOLoginName 'timh' -newiLOUserName 'TimHorton' -newiLOPassword 'timPassword123' -RemoteConsolePriv $true

function Set-iLOUserAccountExample9
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

    Write-Host 'Example 9: Modify an iLO user account.'

    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    # get the href of the iLO user accounts
    $accData = Get-HPRESTDataRaw -Href 'rest/v1/AccountService' -Session $session
    $accURI = $accData.links.Accounts.href

    $members = Get-HPRESTDataRaw -Href $accURI -Session $session
    $foundFlag = $false
    $memberURI = ''
    $user = $null

    foreach($member in $members.Items)
    {
        # check if user is present in the user list
        if($member.Username -eq $LoginNameToModify)
        {
            $foundFlag = $true
            $memberURI = $member.links.self.href
            
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
        # PATCH the data using Set-HPRESTData
        $ret = Set-HPRESTData -Href $memberURI -Setting $user -Session $session
        if($ret.Messages.Count -gt 0)
        {
            foreach($msgID in $ret.Messages)
            {
                $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
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
    Disconnect-HPREST -Session $session
}
#Set-iLOUserAccountExample9 -Address $Address -Credential $cred -LoginNameToModify 'TimHorton' -RemoteConsolePriv $false

function Remove-iLOUserAccountExample10
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

    Write-Host 'Example 10: Delete an iLO user account.'

    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    $accData = Get-HPRESTDataRaw -Href 'rest/v1/AccountService' -Session $session
    $accURI = $accData.links.Accounts.href

    $members = Get-HPRESTDataRaw -Href $accURI -Session $session
    $foundFlag = $false
    $memberURI = ''
    foreach($member in $members.Items)
    {
        # If user to delete is found in user list, note the href of that user in memberURI variable
        if($member.Username -eq $LoginNameToRemove)
        {
            $foundFlag = $true
            $memberURI = $member.links.self.href            
            break
        }
    }
    if($foundFlag -eq $true)
    {
        # If the user was found, executet the HTTP DELETE method on the href of the user to be deleted.
        $ret = Remove-HPRESTData -Href $memberURI -Session $session
        
        # process message(s) from Remove-HPRESTData cmdlet
        if($ret.Messages.Count -gt 0)
        {
            foreach($msgID in $ret.Messages)
            {
                $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }

        # print list of users. Deleted user will not be present in the list
        $accData = Get-HPRESTDataRaw -Href $accData.links.Accounts.href -Session $session
        $accData.Items
    }
    else
    {
        Write-Error "$LoginNameToRemove not present"
    }

    # Disconnect session after use
    Disconnect-HPREST -Session $session
}
#Remove-iLOUserAccountExample10 -Address $Address -Credential $cred -LoginNameToRemove TimHorton

function Get-ActiveiLONICExample11
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 11: Retrieve active iLO NIC information'

    # create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # retrieve manager list
    $managers = Get-HPRESTDataRaw -Href 'rest/v1/Managers' -Session $session
    foreach($manager in $managers.links.Member.href)
    {
        # retrieve manager details and the ethernetNIC href from that
        $managerData = Get-HPRESTDataRaw -Href $manager -Session $session
        $nicURI = $managerData.links.EthernetNICs.href

        # retrieve all NIC information
        $nics = Get-HPRESTDataRaw -Href $nicURI -Session $session

        # print NIC details for enabled i.e. active NIC
        foreach($nic in $nics.items)
        {
            if($nic.Status.State -eq 'Enabled')
            {
                $nic
            }
        }
    }

    # Disconnect session after use
    Disconnect-HPREST -Session $session
}
#Get-ActiveiLONICExample11 -Address $Address -Credential $cred

function Get-SessionExample12
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 12: Retrieve current session information'

    # connect session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    # retrieve all sessions
    $sessions = Get-HPRESTDataRaw -Href 'rest/v1/Sessions' -Session $session
    
    #get the details of current session
    foreach($ses in $sessions.Items)
    {
        if($ses.Oem.Hp.MySession -eq $true)
        {
            $ses
            $ses.oem.hp
        }
    }

    # disconnect session after use
    Disconnect-HPREST -Session $session
}
#Get-SessionExample12 -Address $Address -Credential $cred

function Set-UIDStateExample13
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [ValidateSet('Lit','Off')]
        [System.String]
        $UIDState # Use 'Lit' or 'Off'. Value identified by 'IndicatorLED' field in 'rest/v1/Systems/1'. The value 'Blinking' in mentioned in the schema is not settable by the user.
    )

    Write-Host 'Example 13: Change UID/IndicatorLED status'

    # connect session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # retrieve list of systems
    $systems = Get-HPRESTDataRaw -Href 'rest/v1/Systems' -Session $session
    foreach($sys in $systems.links.Member.href)
    {
        # get the href of the system to PATCH the Indicator LED value
        $sysData = Get-HPRESTDataRaw -Href $sys -Session $session
        $sysURI = $sysData.links.self.href

        # create hashtable object to PATCH
        $UIDSetting = @{'IndicatorLED'=$UIDState}

        # PATCH the data using Set-HPRESTData cmdlet
        $ret = Set-HPRESTData -Href $sysURI -Setting $UIDSetting -Session $session

        # process the message(s) from Set-HPRESTData
        if($ret.Messages.Count -gt 0)
        {
            foreach($msgID in $ret.Messages)
            {
                $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
## NOTE: UID State - Unknown, Lit, Blinking, Off. Unknown and Blinking cannot be set by user
#Set-UIDStateExample13 -Address $Address -Credential $cred -UIDState 'Off'

function Get-ComputerSystemExample14
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 14: Retrieve information of computer systems'

    # connect session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # retrieve list of computer systems
    $systems = Get-HPRESTDataRaw -Href 'rest/v1/Systems' -Session $session

    # print details of all computer systems
    foreach($sys in $systems.links.Member.href)
    {
        $sysData = Get-HPRESTDataRaw -Href $sys -Session $session
        $sysData
    }

    # Disconnect session after use
    Disconnect-HPREST -Session $session    
}
#Get-ComputerSystemExample14 -Address $Address -Credential $cred

function Set-VirutalMediaExample15
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
    Write-Host 'Example 15 : Mount/Unmount virtual media DVD using URL'

    # Connect session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    $managers = Get-HPRESTDataRaw -Href 'rest/v1/Managers' -Session $session
    foreach($mgr in $managers.links.Member.href)
    {
        
        $mgrData = Get-HPRESTDataRaw -Href $mgr -Session $session
        # Check if virtual media is supported
        if($mgrData.links.PSObject.Properties.name -Contains 'VirtualMedia' -eq $false)
        {
            # If virtual media is not present in links under manager details, print error
            Write-Host 'Virtual media not available in Manager links'
        }
        else
        {
            
            $vmhref = $mgrData.links.VirtualMedia.href
            $vmdata = Get-HPRESTDataRaw -Href $vmhref -Session $session
            foreach($vm in $vmdata.links.Member.href)
            {
                $data = Get-HPRESTDataRaw -Href $vm -Session $session
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
                    # PATCH the data to $vm href by using Set-HPRESTData
                    #Disconnect-HPREST -Session $session
                    $ret = Set-HPRESTData -Href $vm -Setting $mountSetting -Session $session
                    
                    # Process message(s) returned from Set-HPRESTData
                    if($ret.Messages.Count -gt 0)
                    {
                        foreach($msgID in $ret.Messages)
                        {
                            $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                            $status
                        }
                    }
                    Get-HPRESTDataRaw -Href $vm -Session $session
                }
            }        
        }
    }
    # Disconnect session after use
    Disconnect-HPREST -Session $session
}
<#
# will return '(400) Bad Request' error if the virtual media is already in this state.
# IsoUrl = $null will dismount the virtual media. IsoUrl = '' will give 400 Bad Request error.

#unmount
Set-VirutalMediaExample15 -Address $Address -Credential $cred -IsoUrl $null -BootOnNextReset $false

#Mount
Set-VirutalMediaExample15 -Address $Address -Credential $cred -IsoUrl 'http://192.184.217.158/iso/Windows/Win2012/en_windows_server_2012_vl_x64_dvd_917758.iso' -BootOnNextReset $true

#unmount
Set-VirutalMediaExample15 -Address $Address -Credential $cred
#>

function Set-AssetTagExample16
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
    Write-Host 'Example 16: Update AssetTag value.'

    # Connect sesion
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # Retrieve list of systems
    $systems = Get-HPRESTDataRaw -Href 'rest/v1/Systems' -Session $session
    foreach($sys in $systems.links.Member.href)
    {
        # Get each system href by first retrieving each system data and then extracting 'Self' href from it
        $sysData = Get-HPRESTDataRaw -Href $sys -Session $session
        $sysURI = $sysData.links.self.href

        # Create hashtable object to PATCH to system href
        $assetTagSetting = @{'AssetTag'='Test111'}
        # PATCH data using Set-HPRESTData cmdlet
        $ret = Set-HPRESTData -Href $sysURI -Setting $assetTagSetting -Session $session

        # Process message(s) from Set-HPRESTData
        if($ret.Messages.Count -gt 0)
        {
            foreach($msgID in $ret.Messages)
            {
                $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }
    # Disconnect session after use
    Disconnect-HPREST -Session $session
}
#Set-AssetTagExample16 -Address $Address -Credential $cred -AssetTag 'Test2'

function Reset-iLOExample17
{
param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    Write-Host 'Example 17: Reset the iLO.'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    # Get list of managers
    $managers = Get-HPRESTDataRaw -Href 'rest/v1/Managers' -Session $session
    foreach($mgr in $managers.links.member.href) # rest/v1/managers/1, rest/v1/managers/2
    {
        # for possible operations on the manager check 'AvailableActions' field in manager data
        # Create hashtable object according to 'AvailableActions' to send to manager href 
        $dataToPost = @{}
        $dataToPost.Add('Action','Reset')

        # Send POST request using Invoke-HPRESTAction
        Invoke-HPRESTAction -Href $mgr -Data $dataToPost -Session $session
        # resetting iLO will delete all active sessions.

    }
    #automatically closes all connections
    #Disconnect-HPREST -Session $session
}
#Reset-iLOExample17 -Address $Address -Credential $cred

function Get-iLONICExample18
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
    Write-Host 'Example 18: Retrieve iLO NIC information'

    # Create Session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # Retrieve list of managers
    $managers = Get-HPRESTDataRaw -Href 'rest/v1/Managers' -Session $session
    foreach($manager in $managers.links.Member.href)
    {
        # Retrieve manager data to extract Ethernet NIC href
        $managerData = Get-HPRESTDataRaw -Href $manager -Session $session
        $nicURI = $managerData.links.EthernetNICs.href

        # Retrieve ethernet NIC details
        $nics = Get-HPRESTDataRaw -Href $nicURI -Session $session

        # Display NIC accoring to the NICState parameter
        foreach($nic in $nics.items)
        {
            if($nic.Status.State -eq 'Enabled')
            {
                if($NICState -eq 'Active')
                {
                    $nic
                    break
                }
                if($NICState -eq 'All')
                {
                    $nic
                }
            }
            if($nic.Status.State -eq 'Disabled')
            {
                if($NICState -eq 'Inactive')
                {
                    $nic
                    break
                }
                if($NICState -eq 'All')
                {
                    $nic
                }
            }
        }
    }
    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Get-iLONICExample18 -Address $Address -Credential $cred -NICState Inactive

function Set-ActiveiLONICExample19
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
    Write-Host 'Example 19: Set the active iLO NIC'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # Retrieve list of managers
    $managers = Get-HPRESTDataRaw -Href 'rest/v1/Managers' -Session $session
    foreach($manager in $managers.links.Member.href)
    {
        
        $managerData = Get-HPRESTDataRaw -Href $manager -Session $session
        $nicHref = $managerData.links.EthernetNICs.href
        $nics = Get-HPRESTDataRaw -Href $nicHref -Session $session
        $selectedNICHref = ''
        foreach($nic in $nics.items)
        {
            if($SharedNIC -eq $true)
            {
                # if a shared NIC setting is required, then check for LOM or Flexible LOM select URI where LOM/FlexLOM is present
                if($nic.Oem.hp.SupportsFlexibleLOM -eq $null -and $nic.Oem.hp.SupportsLOM -eq $null)
                {
                    continue;
                }
                else
                {
                    if($nic.Oem.hp.SupportsFlexibleLOM -eq $true)
                    {
                        $selectedNICHref = $nic.links.self.href
                        break
                    }
                    elseif($nic.Oem.hp.SupportsLOM -eq $true)
                    {
                        $selectedNICHref = $nic.links.self.href
                        break
                    }
                    else
                    {
                        Write-Host 'Shared NIC not supported.'
                    }
                }
            }
            else #if sharedNic set to false, select the Href of NIC where LOM/FlexLOM are not present
            {
                if($nic.Oem.hp.SupportsFlexibleLOM -eq $null -and $nic.Oem.hp.SupportsLOM -eq $null)
                {
                    $selectedNICHref = $nic.links.self.href
                    break
                }
            }
        }

        if($selectedNICHref -ne '')
        {
            $req = @{'Oem'=@{'Hp'=@{'NICEnabled' = $true}}}
            $ret = Set-HPRESTData -Href $selectedNICHref -Setting $req -Session $session

            # Process message(s) returned from Set-HPRESTData cmdlet
            if($ret.Messages.Count -gt 0)
            {
                foreach($msgID in $ret.Messages)
                {
                    $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Set-ActiveiLONICExample19 -Address $Address -Credential $cred

function Get-IMLExample20
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 20: Retrieve Integrated Management Log (IML)'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # Retrieve systems list
    $systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($sys in $systems.links.Member.href)
    {
        # Check if logs are available
        $systemData = Get-HPRESTDataRaw -Href $sys -Session $session
        if($systemData.links.PSObject.properties.name -notcontains 'Logs')
        {
            Write-Host 'Logs not available'
        }
        else
        {
            # Retrieve the IML href
            $logURI = $systemData.links.Logs.href
            $logData = Get-HPRESTDataRaw -Href $logURI -Session $session
            $imlURI = ''
            foreach($link in $logData.links.Member.href)
            {
                $spl = $link.split('`/')
                if($spl[$spl.length-1] -match 'IML')
                {
                    $imlURI = $link
                    break
                }
            }

            # retrieve and display IML log entries
            $imlData = Get-HPRESTDataRaw -Href $imlURI -Session $session
            foreach($entryLink in $imlData.links.Entries)
            {
                $imlEntries = Get-HPRESTDataRaw -Href $entryLink.href -Session $session
                $imlEntries.Items
            }
        }
    }
    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Get-IMLExample20 -Address $Address -Credential $cred

function Get-iLOEventLogExample21
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 21: Retrieve iLO Event Log'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    $managers = Get-HPRESTDataRaw -Href 'rest/v1/managers' -Session $session
    foreach($mgr in $managers.links.Member.href)
    {
        $managerData = Get-HPRESTDataRaw -Href $mgr -Session $session
        if($managerData.links.PSObject.properties.name -notcontains 'Logs')
        {
            Write-Host 'Logs not available'
        }
        else
        {
            # get the href for iLO event logs
            $logURI = $managerData.links.Logs.href
            $logData = Get-HPRESTDataRaw -Href $logURI -Session $session
            $imlURI = ''
            foreach($link in $logData.links.Member.href)
            {
                $spl = $link.split('`/')
                if($spl[$spl.length-1] -match 'IEL')
                {
                    $ielURI = $link
                    break
                }
            }

            # Retrieve and display the log entries
            $ielData = Get-HPRESTDataRaw -Href $ielURI -Session $session
            foreach($entryLink in $ielData.links.Entries)
            {
                $ielEntries = Get-HPRESTDataRaw -Href $entryLink.href -Session $session
                $ielEntries.Items
            }
        }
    }
    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Get-iLOEventLogExample21 -Address $Address -Credential $cred

function Clear-IMLExample22
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 22: Clear Integrated Management Log'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    $systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($sys in $systems.links.Member.href)
    {
        # check if logs are available or not
        $systemData = Get-HPRESTDataRaw -Href $sys -Session $session
        if($systemData.links.PSObject.properties.name -notcontains 'Logs')
        {
            Write-Host 'Logs not available'
        }
        else
        {
            # extract href href for IML
            $logURI = $systemData.links.Logs.href
            $logData = Get-HPRESTDataRaw -Href $logURI -Session $session
            $imlURI = ''
            foreach($link in $logData.links.Member.href)
            {
                $spl = $link.split('`/')
                if($spl[$spl.length-1] -match 'IML')
                {
                    $imlURI = $link
                    break
                }
            }
            
            # Create hashtable object to invoke action to clear logs
            # Check 'AvailableActions' for values in this hashtable object
            $action = @{'Action'='ClearLog'}
            
            # POST the object using Invoke-HPRESTAction cmdlet
            $ret = Invoke-HPRESTAction -Href $imlURI -Data $action -Session $session

            # Process message(s) returned from Invoke-HPRESTAction cmdlet
            if($ret.Messages.Count -gt 0)
            {
                foreach($msgID in $ret.Messages)
                {
                    $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
<#
Clear-IMLExample22 -Address $Address -Credential $cred
Get-IMLExample20 -Address $Address -Credential $cred
#>

function Clear-iLOEventLogExample23
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )
    Write-Host 'Example 23: Clear iLO Event Log'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # Retrieve manager list
    $managers = Get-HPRESTDataRaw -Href 'rest/v1/managers' -Session $session
    foreach($mgr in $managers.links.Member.href)
    {
        $managerData = Get-HPRESTDataRaw -Href $mgr -Session $session
        # check if logs are available or not
        if($managerData.links.PSObject.properties.name -notcontains 'Logs')
        {
            Write-Host 'Logs not available'
        }
        else
        {
            # get the href for iLO event logs
            $logURI = $managerData.links.Logs.href
            $logData = Get-HPRESTDataRaw -Href $logURI -Session $session
            $ielURI = ''
            foreach($link in $logData.links.Member.href)
            {
                $spl = $link.split('`/')
                if($spl[$spl.length-1] -match 'IEL')
                {
                    $ielURI = $link
                    break
                }
            }

            # Create hashtable object to invoke action to clear logs
            # Check 'AvailableActions' for values in this hashtable object
            $action = @{'Action'='ClearLog'}

            # POST the object using Invoke-HPRESTAction cmdlet
            $ret = Invoke-HPRESTAction -Href $ielURI -Data $action -Session $session

            # Process message(s) returned from Invoke-HPRESTAction cmdlet
            if($ret.Messages.Count -gt 0)
            {
                foreach($msgID in $ret.Messages)
                {
                    $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
<#
Clear-iLOEventLogExample23 -Address $Address -Credential $cred
Get-iLOEventLogExample21 -Address $Address -Credential $cred
#>

function Set-SNMPExample24
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
    Write-Host 'Example 24: Configure iLO SNMP settings.'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # retrieve list of managers
    $managers = Get-HPRESTDataRaw -Href 'rest/v1/Managers' -Session $session
    foreach($mgr in $managers.links.Member.href)
    {
        # retrieve settings of NetworkService data
        $mgrData = Get-HPRESTDataRaw -Href $mgr -Session $session
        $netSerURI = $mgrData.links.NetworkService.href
        $netSerData = Get-HPRESTDataRaw -Href $netSerURI -Session $session
        if($netSerData.links.PSObject.properties.name -notcontains 'SNMPService')
        {
            Write-Host 'SNMP services not available in Manager Network Service'
        }
        else
        {
            # create hashtable object according to the parameters provided by user
            $snmpSerURI = $netSerData.links.SNMPService.href
            $snmpSetting = @{}
            if($mode -ne '' -and $Mode -ne $null)
            {
                $snmpSetting.Add('Mode',$Mode)
            }
            if($AlertsEnabled -ne $null)
            {
                $snmpSetting.Add('AlertsEnabled',[System.Convert]::ToBoolean($AlertsEnabled))
            }

            # PATCh the settings using Set-HPRESTData cmdlet
            $ret = Set-HPRESTData -Href $snmpSerURI -Setting $snmpSetting -Session $session

            # Process message(s) returned from Set-HPRESTData cmdlet
            if($ret.Messages.Count -gt 0)
            {
                foreach($msgID in $ret.Messages)
                {
                    $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }
    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Set-SNMPExample24 -Address $Address -Credential $cred -Mode Agentless -AlertsEnabled $true
 
function Get-SchemaExample25
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $Type,

        [ValidateSet('en','jp','zh')]
        [System.String]
        $Language = 'en'


    )

    Write-Host 'Example 25: Retrieve schema'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # Retrieve the schema with the Type provided by the user
    $sch = Get-HPRESTSchema -Type $Type -Language $Language -Session $session
    $sch.properties
    
    # Disconnect the session after use
    Disconnect-HPREST -Session $session

}
#Get-SchemaExample25 -Address $Address -Credential $cred -Type ComputerSystem

function Get-RegistryExample26
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

    Write-Host 'Example 26: Retrieve registry'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # retrieve list of registries
    $reg = Get-HPRESTDataRaw -href rest/v1/registries -Session $session

    # select the registry where the prefix is same as value provided by user in 'RegistryPrefix' parameter
    $reqRegList = $reg.Items | ? {$_.Schema.ToString().IndexOf($RegistryPrefix) -eq 0}
    
    # retrieve and display the external reference for the required language
    foreach($reqReg in $reqRegList)
    {
        $reqRegURI = ($reqReg.Location|?{$_.Language -eq $Language}).uri.extref
        $reqRegData = Get-HPRESTDataRaw -Href $reqRegURI -Session $session
        $reqRegData
    }
    # Disconnect the session after use
    Disconnect-HPREST -Session $session

}
#Get-RegistryExample26 -Address $Address -Credential $cred -RegistryPrefix HpBiosAttributeRegistryP89

function Set-TimeZoneExample27
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
    Write-Host 'Example 27: Set timezone'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # retrieve manager list
    $managers = Get-HPRESTDataRaw -href rest/v1/managers -Session $session
    foreach($mgr in $managers.links.Member.href)
    {
        # Retrieve DateTimeService href and timezone name to display to user
        $mgrData = Get-HPRESTDataRaw -href $mgr -Session $session
        $dtsURI = $mgrData.Oem.Hp.links.DateTimeService.href
        $dtsData = Get-HPRESTDataRaw -Href $dtsURI -Session $session
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
                
                # PATCH the new setting using Set-HPRESTData cmdlet
                $ret = Set-HPRESTData -Href $dtsURI -Setting $setting -Session $session

                # Process message(s) returned from Set-HPRESTData cmdlet
                if($ret.Messages.Count -gt 0)
                {
                    foreach($msgID in $ret.Messages)
                    {
                        $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                        $status
                    }
                }
                break
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
## Patch using Timezone name is preferred over timezone index. If both are patched, Index field will be ignored
## DHCPv4 should be disabled in active NIC for setting the timezone
#Set-TimeZoneExample27 -Address $Address -Credential $cred -TimeZone 'America/Chicago' 

function Set-iLONTPServerExample28
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
    Write-Host 'Example 28: Set NTP server'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # Retrieve manager list
    $managers = Get-HPRESTDataRaw -href rest/v1/managers -Session $session
    foreach($mgr in $managers.links.Member.href)
    {
        # retrieve date time details and display current values
        $mgrData = Get-HPRESTDataRaw -Href $mgr -Session $session
        $dtsURI = $mgrData.Oem.Hp.links.DateTimeService.href
        $dtsData = Get-HPRESTDataRaw -Href $dtsURI -Session $session
        Write-Host Current iLO Date and Time setting - $dtsData.ConfigurationSettings
        Write-Host Current iLO NTP Servers - $dtsData.NTPServers

        # Create hashtable object with values for NTPServer
        $setting = @{'StaticNTPServers'=$StaticNTPServer}

        # PATCH new NTPServer data using Set-HPRESTData
        $ret = Set-HPRESTData -Href $dtsURI -Setting $setting -Session $session

        # Process message(s) returned from Set-HPRESTData cmdlet
        if($ret.Messages.Count -gt 0)
        {
            foreach($msgID in $ret.Messages)
            {
                $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                $status
            }
        }
    }

    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
## DHCPv4 should be disabled in active NIC for setting the StaticNTPServer
#Set-iLONTPServerExample28 -Address $Address -Credential $cred -StaticNTPServer @('192.168.0.1','192.168.0.2')

function Get-PowerMetricExample29
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    #NOTE: This will work only if iLO is NOT configured to take time settings from DHCP v4 or v6
    Write-Host 'Example 29: Retrieve PowerMetrics average watts'

    # Create session
    $session = Connect-HPREST -Address $Address -Credential $Credential
    
    # retrieve chassis list
    $chassis = Get-HPRESTDataRaw -href rest/v1/chassis -Session $session
    foreach($cha in $chassis.links.member.href)
    {
        # get PowerMetrics href, retrieve the data and display
        $chaData = Get-HPRESTDataRaw -Href $cha -Session $session
        $pmURI = $chaData.links.PowerMetrics.href
        $pmData = Get-HPRESTDataRaw -Href $pmURI -Session $session
        $pm = $pmData.PowerMetrics
        Write-Host $chaData.Model AverageConsumedWatts = $pm.AverageConsumedWatts watts over a $pm.IntervalInMin minute moving average
    }

    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Get-PowerMetricExample29 -Address $Address -Credential $cred

function Get-BiosDependenciesExample30
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    Write-Host 'Example 30: Get BIOS dependencies.'

    $attRegFromBios = ''
    $attRegLoc = ''
    $registries = $null

    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    $sysList = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    $registries = Get-HPRESTDataRaw -Href $session.RootData.links.Registries.href -Session $session
    foreach($sys in $syslist.links.member.href)
    {
        # Get the Attribute registry version from BIOS settings
        $sysData = Get-HPRESTDataRaw -Href $sys -Session $session
        $biosURI = $sysData.Oem.Hp.links.BIOS.href
        
        # get BIOS data
        $biosData = Get-HPRESTDataRaw -Href $biosURI -Session $session
        $attRegFromBios = $biosData.AttributeRegistry

        # get the atttribute registry that matched the BIOS settings
        foreach($reg in $registries.items)
        {
            if($reg.Schema -eq $attRegFromBios)
            {
                $attRegLoc = $reg.Location|Where-Object{$_.Language -eq 'en'}|%{$_.uri.extref}

                # Display the dependencies from the registry entries
                $attReg = Get-HPRESTDataRaw -Href $attRegLoc -Session $session
                $attReg.RegistryEntries.Dependencies

                break
            }
        }
    }
    
    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Get-BiosDependenciesExample30 -Address $Address -Credential $cred

function Set-TPMExample31
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [System.String]
        $TPMProperty, # TpmType, TpmState, TPMOperation, TpmVisibility, Tpm2Operation -Tpm2Visibility, Tpm2Ppi, TpmBinding, TpmUefiOpromMeasuring.
        #These property names may be present or not based on the system configuration.

        [System.String]
        $Value
<#
## ValueName is the value to be used in REST interface
## ValueDisplayName is seen in RBSU menu options

TpmType - 
ValueName                                     ValueDisplayName                            
---------                                     ----------------                            
NoTpm                                         No TPM                                      
Tpm12                                         TPM 1.2                                     
Tpm20                                         TPM 2.0                                     
Tcm10                                         TCM 1.0                                     


TpmState
ValueName                                     ValueDisplayName                            
---------                                     ----------------                            
NotPresent                                    Not Present                                 
PresentDisabled                               Present and Disabled                        
PresentEnabled                                Present and Enabled       

TPMOperation
ValueName                                     ValueDisplayName                            
---------                                     ----------------                            
NoAction                                      No Action                                   
Enable                                        Enable                                      
Disable                                       Disable                                     
Clear                                         Clear   

TpmVisibility
ValueName                                     ValueDisplayName                            
---------                                     ----------------                            
Hidden                                        Hidden                                      
Visible                                       Visible                                     

Tpm2Operation
ValueName                                     ValueDisplayName                            
---------                                     ----------------                            
NoAction                                      No Action                                   
Clear                                         Clear                                       


Tpm2Visibility, 
ValueName                                     ValueDisplayName                            
---------                                     ----------------                            
Hidden                                        Hidden                                      
Visible                                       Visible                                     


Tpm2Ppi
ValueName                                     ValueDisplayName                            
---------                                     ----------------                            
Enabled                                       Enabled                                     
Disabled                                      Disabled                                    


TpmBinding 
ValueName                                     ValueDisplayName                            
---------                                     ----------------                            
Enabled                                       Enabled                                     
Disabled                                      Disabled                                    


TpmUefiOpromMeasuring
ValueName                                     ValueDisplayName                            
---------                                     ----------------                            
Enabled                                       Enabled                                     
Disabled                                      Disabled                                    


#>

    )

    Write-Host 'Example 31: Change TPM 2.0 Setting'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    #Get BIOS URI
    $sys = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($hrefVal in $sys.links.member.href) # rest/v1/systems/1, rest/v1/system/2
    {
        $data = Get-HPRESTDataRaw -Href $hrefVal -Session $session
        $biosURI = $data.Oem.Hp.links.BIOS.href
    
        #get AttributeRegistry value from BIOS Data
        $biosData = Get-HPRESTDataRaw -Href $biosURI -Session $session
        $biosData
        $ar = $biosData.AttributeRegistry

        # get attribute registries and select the one that matches BIOS data attribute registry
        $reg = Get-HPRESTDataRaw -Href 'rest/v1/registries' -Session $session
        
        #if property to be modified is not present in the bios data, then print error message and return
        if(-not(($biosData|Get-Member).Name -Contains $TPMProperty))
        {
            Write-Host "Property $TPMProperty is not supported on this system"
        }
        else
        {
            #Get setting href to update bios property. For bios, property can be updated in the settings href only. other data may not have setting href
            $biosSettingURI = $biosData.links.settings.href

            # Create hashtable object with TPM property and value to PATCH
            $tpmSetting = @{$TPMProperty=$Value}

            # PATCH TPM setting using Set-HPRESTData
            $ret = Set-HPRESTData -Href $biosSettingURI -Setting $tpmSetting -Session $session

            # Process message(s) returned from Set-HPRESTData cmdlet
            if($ret.Messages.Count -gt 0)
            {
                foreach($msgID in $ret.Messages)
                {
                    $status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $session
                    $status
                }
            }
        }
    }
       
    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
<#
Set-TPMExample31 -Address $Address -Credential $cred -TPMProperty TpmVisibility -Value Hidden
Reset-ServerExample2 -Address $Address -Credential $cred -Action Reset -PropertyName ResetType -PropertyValue ForceRestart
#>

function Get-TPMExample32
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential,

        [ValidateSet('All', 'TpmType', 'TpmState', 'TPMOperation', 'TpmVisibility', 'Tpm2Operation', 'Tpm2Visibility', 'Tpm2Ppi', 'TpmBinding', 'TpmUefiOpromMeasuring')]
        [System.String]
        $TPMProperty = 'All'
    )

    Write-Host 'Example 32: Get TPM Setting'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    #Get BIOS URI
    $sys = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $session
    foreach($hrefVal in $sys.links.member.href) # rest/v1/systems/1, rest/v1/system/2
    {
        $data = Get-HPRESTDataRaw -Href $hrefVal -Session $session
        $biosURI = $data.Oem.Hp.links.BIOS.href
    
        #get AttributeRegistry value from BIOS Data
        $biosData = Get-HPRESTDataRaw -Href $biosURI -Session $session
        $ar = $biosData.AttributeRegistry

        # get attribute registries and select the one that matches BIOS data attribute registry
        $reg = Get-HPRESTDataRaw -Href 'rest/v1/registries' -Session $session
        $selectedReg = $null
        foreach($x in $reg.Items)
        {
            if($x.Schema -eq $ar)
            {
                $selectedReg = $x
            }
        }
        if($selectedReg -eq $null)
        {
            Write-Host 'No valid registry available for BIOS/TPM settings'
        }
        else
        {
            # Display TMP registry entries
            $attReg = Get-HPRESTDataRaw -Href ($selectedReg.Location|?{$_.Language -eq 'en'}|%{$_.URI.extref}) -Session $session

            if($TPMProperty -eq 'All')
            {
                $tpmDetails = $attReg.RegistryEntries.Attributes | ?{$_.name -match 'TPM'}
                $tpmDetails
            }
            else
            {
                $tpmDetails = $attReg.RegistryEntries.Attributes | ?{$_.name -match $TPMProperty}
                if(-not(($biosData|Get-Member).Name -Contains $TPMProperty))
                {
                    Write-Host "Property $TPMProperty is not supported on this system"
                }
                else
                {
                    $tpmDetails
                }
            }
        }
    }
       
    # Disconnect the session after use
    Disconnect-HPREST -Session $session
}
#Get-TPMExample32 -Address $Address -Credential $cred -TPMProperty TpmBinding

function Get-ThermalMetricsExample33
{
    param
    (
        [System.String]
        $Address,

        [PSCredential]
        $Credential
    )

    Write-Host 'Example 33: Get Temperature and Fan details from Thermal Metrics.'
    
    #create session
    $session = Connect-HPREST -Address $Address -Credential $Credential

    #retrieve Chassis list
    $chassisList = Get-HPRESTDataRaw -Href rest/v1/chassis -Session $session
    foreach($mem in $chassisList.links.Member)
    {
        $chasis = Get-HPRESTDataRaw -Href $mem.href -Session $session
        
        # get the thermal metrics of the chassis
        $thermalMetrics = Get-HPRESTDataRaw -Href $chasis.links.ThermalMetrics.href -Session $session
        
        # display temperature values
        Write-Host "Temperature: "
        $temps = $thermalMetrics.Temperatures
        $temps
        
        # display fan values        
        Write-Host "Fans: "
        $fans = $thermalMetrics.Fans
        $fans
    }
    Disconnect-HPREST -Session $session
}
#Get-ThermalMetricsExample33 -Address $Address -Credential $cred