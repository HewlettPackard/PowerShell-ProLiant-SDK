<#********************************************Description********************************************

This script is an example of how to input named or pipeline parameter values for a cmdlet.

***************************************************************************************************#>


###---------------------------------------------Examples of Using Named Parameters---------------------------------------------###
#Example 1: single iLO
Get-HPiLOStorageController -Server 192.168.1.1 -Username user1 -Password pwd1

#Example 2: multiple iLO with same username and password / Credential
$server1 = "192.168.1.1"
$server2 = "192.168.1.3"
$username = "user"
$password = "pwd"
$credential = Get-Credential -Message "Please enter the username and password"
Get-HPiLOStorageController -Server @($server1, $server2) -Username $username -Password $password -DisableCertificateAuthentication
Get-HPiLOStorageController -Server @($server1, $server2) -Credential $credential -DisableCertificateAuthentication

#Example 3: multiple iLO with different username and password / Credential
$server1 = "192.168.1.1"
$server2 = "192.168.1.3"
$user1 = "user1"
$user2 = "user2"
$pwd1 = "pwd1"
$pwd2 = "pwd2"
$credential1 = Get-Credential -Message "Please enter the username and password for $server1"
$credential2 = Get-Credential -Message "Please enter the username and password for $server2"
Get-HPiLOStorageController -Server @($server1, $server2) -Username @($user1,$user2) -Password @($pwd1,$pwd2) -DisableCertificateAuthentication
Get-HPiLOStorageController -Server @($server1, $server2) -Credential @($credential1,$credential2) -DisableCertificateAuthentication


###---------------------------------------------Examples of Using Piped Parameters---------------------------------------------###
#Example 1: Pipe only server parameter.  Username and Password parameters are provided using the commandline
"192.168.1.1" |  Get-HPiLOStorageController -Username user -Password pwd -DisableCertificateAuthentication
@("192.168.1.1", "192.168.1.3") | Get-HPiLOStorageController -Username @("user1","user2") -Password @("pwd1","pwd2") -DisableCertificateAuthentication

#Example 2: Pipe a PSObject with multiple servers. All the servers have the same username and password
$p = New-Object -TypeName PSObject -Property @{ "Server"= @("192.168.1.1","192.168.1.3");"Username"="user"; "Password"="pwd" }
$p | Get-HPiLOStorageController -DisableCertificateAuthentication 

#Example 3: Pipe a PSObject with multiple servers. All the servers have different username and password
$p = New-Object -TypeName PSObject -Property @{ "Server"= @("192.168.1.1","192.168.1.3");"Username"=@("user1","user2"); "Password"=@("pwd1","pwd2") }
$p | Get-HPiLOStorageController -DisableCertificateAuthentication

#Example 4: Pipe multiple PSObject with multiple servers with different parameters
$p1 = New-Object -TypeName PSObject -Property @{
    Server = "192.168.1.1"
    username = "user1"
    password = "pwd1"
}
$p2 = New-Object -TypeName PSObject -Property @{
    IP = "192.168.1.3"
    Credential = Get-Credential -Message "Please enter the password" -UserName "user2"
}
$list = @($p1,$p2)
$list | Get-HPiLOStorageController -DisableCertificateAuthentication 


###---------------------------------------------Examples of Interactive Input for Mandatory Parameters---------------------------------------------###
#Example1: Pipe multiple servers but the username and password is provided for only one server
# You will be asked to input values for mandatory parameters which do not have default values. For example, username and password for servers 192.168.1.2 and 192.168.1.3
# You will NOT be asked to input values for mandatoty parameters with default values, such as "Category"
$p0 = New-Object -TypeName PSObject -Property @{
    Server = "192.168.1.1"
    username = "user1"
    password = "pwd1"
    Category = "MemoryInfo"
}
$p1 = New-Object -TypeName PSObject -Property @{
    Server = "192.168.1.2"
}
$p2 = New-Object -TypeName PSObject -Property @{
    Server = "192.168.1.3"
}
$list = @($p0,$p1,$p2)
$list | get-hpiloserverinfo  -DisableCertificateAuthentication
