####################################################################
#Firmare inventory information
####################################################################

<#
.Synopsis
    This Script gets the Inventory Informations.

.DESCRIPTION
    This Script gets Firmware, Software, Device and PCIDevice Inventory information for iLO5.
	
	The cmdlets used from HPEiLOCmdlets module in the script are as stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Get-HPEiLOFirmwareInventory, Get-HPEiLOServerSoftwareInventory, Get-HPEiLODeviceInventory, Get-HPEiLOPCIDeviceInventory, Disconnect-HPEiLO, Disable-HPEiLOLog

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\InventoryInformation.ps1
	
	This script does not take any parameter.
	
.INPUTS
	iLOInput.csv file in the script folder location having iLO IPv4 address, iLO Username and iLO Password.

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 01/15/2020 

.LINK
    http://www.hpe.com/servers/powershell
#>

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

Write-Host "This script gets the inventory information such as Firmware inventory, Device Inventory and PCI device Inventory.`n"

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

    $connection = Connect-HPEiLO -IP $inputcsv.IP -Username $inputcsv.Username -Password $inputcsv.Password -DisableCertificateAuthentication
	
	$Error.Clear()
	
	if($Connection -eq $null)
    {
        Write-Host "`nConnection could not be established to any target iLO.`n" -ForegroundColor Red
        $inputcsv.IP | fl
        exit;
    }

	#List of IP's that could not be connected
	if($Connection.count -ne $inputcsv.IP.count)
    {
        Write-Host "`nConnection failed for below set of targets" -ForegroundColor Red
        foreach($item in $inputcsv.IP)
        {
            if($Connection.IP -notcontains $item)
            {
                $item | fl
            }
        }
    }
	
    if($connection -ne $null)
    {

        Write-Host "`nConnection established to the server." -ForegroundColor Green

        Write-Host "`nGetting Firmware Inventory information." -ForegroundColor Green

        $result1 = Get-HPEiLOFirmwareInventory -Connection $connection 
       
        foreach($output in $result1)
        {

            if($output.Status -eq "OK")
            {
                Write-Host "`Firmware Inventory information for $($output.IP)." -ForegroundColor Green

                $fwInventory = @()
                foreach($item in $output.FirmwareInformation)
                {
                    $fwInfo = New-Object PSObject 
                    if($item.Status.Health -ne $null){ $status = $item.Status.Health } else { $status = $item.Status.State }                                      
                                        
                    $fwInfo | Add-Member Noteproperty "Index" $item.Index
                    $fwInfo | Add-Member Noteproperty "FirmwareName" $item.FirmwareName
                    $fwInfo | Add-Member Noteproperty "FirmwareVersion" $item.FirmwareVersion
                    $fwInfo | Add-Member Noteproperty "Location" $item.Location
                    $fwInfo | Add-Member Noteproperty "Status" $item.status

                    $fwInventory += $fwInfo
                 }
                 $fwInventory
           
            }
            
            else
            {
                if($output.StatusInfo -ne $null)
                {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to get Firmware Inventory information: "$message -ForegroundColor Red }
            }

        }
        
        Start-Sleep -Seconds 6

        Write-Host "`nGetting Server Software Inventory information." -ForegroundColor Green

        $result2 = Get-HPEiLOServerSoftwareInventory -Connection $connection 

        foreach($output in $result2)
        {
            
            if($output.Status -eq "OK")
            {
                
                Write-Host "`nServer Software Inventory information for $($output.IP)." -ForegroundColor Green

                if($output.Status -eq "OK")
            {
                Write-Host "`Firmware Inventory information for $($output.IP)." -ForegroundColor Green

                $SWInventory = @()
                foreach($item in $output.ServerSoftwareInfo)
                {
                    $SWInfo = New-Object PSObject 
                    if($item.Status.Health -ne $null){ $status = $item.Status.Health } else { $status = $item.Status.State }                                      
                                        
                    $SWInfo | Add-Member Noteproperty "Index" $item.Index
                    $SWInfo | Add-Member Noteproperty "Name" $item.Name
                    $SWInfo | Add-Member Noteproperty "Version" $item.Version
                    $SWInfo | Add-Member Noteproperty "DeviceClass" $item.DeviceClass
                    $SWInfo | Add-Member Noteproperty "Description" $item.Description

                    $SWInventory += $SWInfo
                 }
                 $SWInventory
           
            }
           
            }
   
            else
            {
                if($output.StatusInfo -ne $null)
                {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to get Server Software Inventory information for $($output.IP): "$message -ForegroundColor Red }
            }

        }
        

        Start-Sleep -Seconds 6

        Write-Host "`nGetting Device Inventory information." -ForegroundColor Green

        $result3 = Get-HPEiLODeviceInventory -Connection $connection 

        
       foreach($output in $result3)
        {
            
            if($output.Status -eq "OK")
            {
                
                Write-Host "`nDevice Inventory information for $($output.IP)." -ForegroundColor Green

                $DVInventory = @()
                foreach($item in $output.Devices)
                {
                    $DVInfo = New-Object PSObject 
                    if($item.Status.Health -ne $null){ $status = $item.Status.Health } else { $status = $item.Status.State }                                      
                                        
                    $DVInfo | Add-Member Noteproperty "DeviceType" $item.DeviceType
                    $DVInfo | Add-Member Noteproperty "FirmwareVersion" $item.FirmwareVersion
                    $DVInfo | Add-Member Noteproperty "Location" $item.Location
                    $DVInfo | Add-Member Noteproperty "Name" $item.Name
                    $DVInfo | Add-Member Noteproperty "Status" $item.Status
                    $DVInfo | Add-Member Noteproperty "MCTPProtocolDisabled" $item.MCTPProtocolDisabled

                    $DVInventory += $DVInfo
                 }
                 $DVInventory
           
            }
   
            else
            {
                if($output.StatusInfo -ne $null)
                {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to get Device Inventory information for $($output.IP): "$message -ForegroundColor Red }
            }

        }

        Start-Sleep -Seconds 6

        Write-Host "`nGetting PCI Device Inventory information." -ForegroundColor Green

        $result4 = Get-HPEiLOPCIDeviceInventory -Connection $connection 

        
        foreach($output in $result4)
        {
            
            if($output.Status -eq "OK")
            {
                
                Write-Host "`nPCIDevice Inventory information for $($output.IP)." -ForegroundColor Green

                $pciInventory = @()
                foreach($item in $output.PCIDevice)
                {
                    $pciInfo = New-Object PSObject 
                    if($item.Status.Health -ne $null){ $status = $item.Status.Health } else { $status = $item.Status.State }                                      
                                        
                    $pciInfo | Add-Member Noteproperty "BayNumber" $item.BayNumber
                    $pciInfo | Add-Member Noteproperty "Bifurcated" $item.Bifurcated
                    $pciInfo | Add-Member Noteproperty "BusNumber" $item.BusNumber
                    $pciInfo | Add-Member Noteproperty "ClassCode" $item.ClassCode
                    $pciInfo | Add-Member Noteproperty "DeviceID" $item.DeviceID
                    $pciInfo | Add-Member Noteproperty "DeviceLocation" $item.DeviceLocation
                    $pciInfo | Add-Member Noteproperty "DeviceType" $item.DeviceType
                    $pciInfo | Add-Member Noteproperty "StructuredName" $item.StructuredName
                    $pciInfo | Add-Member Noteproperty "SubsystemDeviceID" $item.SubsystemDeviceID
                    $pciInfo | Add-Member Noteproperty "LocationString" $item.LocationString
                    $pciInfo | Add-Member Noteproperty "Name" $item.Name
                    $pciInfo | Add-Member Noteproperty "StructuredName" $item.StructuredName
                    $pciInfo | Add-Member Noteproperty "SubsystemVendorID" $item.SubsystemVendorID
                    $pciInfo | Add-Member Noteproperty "UEFIDevicePath" $item.UEFIDevicePath
                    $pciInfo | Add-Member Noteproperty "DeviceInstance" $item.DeviceInstance
                    $pciInfo | Add-Member Noteproperty "VendorID" $item.VendorID

                    $pciInventory += $pciInfo
                 }
                 $pciInventory
           
            }
   
            else
            {
                if($output.StatusInfo -ne $null)
                {   $message = $output.StatusInfo.Message; Write-Host "`nFailed to get PCIDevice Inventory information for $($output.IP): "$message -ForegroundColor Red }
            }

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
# SIG # Begin signature block
# MIInYgYJKoZIhvcNAQcCoIInUzCCJ08CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCivjHfT+6T61bS
# qc/EPuN+VewqF9qaiM0jG7B1snZPg6CCFjwwggVMMIIDNKADAgECAhMzAAAANdjV
# WVsGcUErAAAAAAA1MA0GCSqGSIb3DQEBBQUAMH8xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAMTIE1pY3Jvc29mdCBDb2RlIFZlcmlm
# aWNhdGlvbiBSb290MB4XDTEzMDgxNTIwMjYzMFoXDTIzMDgxNTIwMzYzMFowbzEL
# MAkGA1UEBhMCU0UxFDASBgNVBAoTC0FkZFRydXN0IEFCMSYwJAYDVQQLEx1BZGRU
# cnVzdCBFeHRlcm5hbCBUVFAgTmV0d29yazEiMCAGA1UEAxMZQWRkVHJ1c3QgRXh0
# ZXJuYWwgQ0EgUm9vdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALf3
# GjPm8gAELTngTlvtH7xsD821+iO2zt6bETOXpClMfZOfvUq8k+0DGuOPz+VtUFrW
# lymUWoCwSXrbLpX9uMq/NzgtHj6RQa1wVsfwTz/oMp50ysiQVOnGXw94nZpAPA6s
# YapeFI+eh6FqUNzXmk6vBbOmcZSccbNQYArHE504B4YCqOmoaSYYkKtMsE8jqzpP
# hNjfzp/haW+710LXa0Tkx63ubUFfclpxCDezeWWkWaCUN/cALw3CknLa0Dhy2xSo
# RcRdKn23tNbE7qzNE0S3ySvdQwAl+mG5aWpYIxG3pzOPVnVZ9c0p10a3CitlttNC
# bxWyuHv77+ldU9U0WicCAwEAAaOB0DCBzTATBgNVHSUEDDAKBggrBgEFBQcDAzAS
# BgNVHRMBAf8ECDAGAQH/AgECMB0GA1UdDgQWBBStvZh6NLQm9/rEJlTvA73gJMtU
# GjALBgNVHQ8EBAMCAYYwHwYDVR0jBBgwFoAUYvsKIVt/Q24R2glUUGv10pZx8Z4w
# VQYDVR0fBE4wTDBKoEigRoZEaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9j
# cmwvcHJvZHVjdHMvTWljcm9zb2Z0Q29kZVZlcmlmUm9vdC5jcmwwDQYJKoZIhvcN
# AQEFBQADggIBADYrovLhMx/kk/fyaYXGZA7Jm2Mv5HA3mP2U7HvP+KFCRvntak6N
# NGk2BVV6HrutjJlClgbpJagmhL7BvxapfKpbBLf90cD0Ar4o7fV3x5v+OvbowXvT
# gqv6FE7PK8/l1bVIQLGjj4OLrSslU6umNM7yQ/dPLOndHk5atrroOxCZJAC8UP14
# 9uUjqImUk/e3QTA3Sle35kTZyd+ZBapE/HSvgmTMB8sBtgnDLuPoMqe0n0F4x6GE
# NlRi8uwVCsjq0IT48eBr9FYSX5Xg/N23dpP+KUol6QQA8bQRDsmEntsXffUepY42
# KRk6bWxGS9ercCQojQWj2dUk8vig0TyCOdSogg5pOoEJ/Abwx1kzhDaTBkGRIywi
# pacBK1C0KK7bRrBZG4azm4foSU45C20U30wDMB4fX3Su9VtZA1PsmBbg0GI1dRtI
# uH0T5XpIuHdSpAeYJTsGm3pOam9Ehk8UTyd5Jz1Qc0FMnEE+3SkMc7HH+x92DBdl
# BOvSUBCSQUns5AZ9NhVEb4m/aX35TUDBOpi2oH4x0rWuyvtT1T9Qhs1ekzttXXya
# Pz/3qSVYhN0RSQCix8ieN913jm1xi+BbgTRdVLrM9ZNHiG3n71viKOSAG0DkDyrR
# fyMVZVqsmZRDP0ZVJtbE+oiV4pGaoy0Lhd6sjOD5Z3CfcXkCMfdhoinEMIIFdDCC
# BFygAwIBAgIRAIfXKeuQ9ypCYMOcCvqoIOwwDQYJKoZIhvcNAQELBQAwfDELMAkG
# A1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMH
# U2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSQwIgYDVQQDExtTZWN0
# aWdvIFJTQSBDb2RlIFNpZ25pbmcgQ0EwHhcNMjAxMDIxMDAwMDAwWhcNMjExMDIx
# MjM1OTU5WjCB2jELMAkGA1UEBhMCVVMxDjAMBgNVBBEMBTk0MzA0MRMwEQYDVQQI
# DApDYWxpZm9ybmlhMRIwEAYDVQQHDAlQYWxvIEFsdG8xHDAaBgNVBAkMEzMwMDAg
# SGFub3ZlciBTdHJlZXQxKzApBgNVBAoMIkhld2xldHQgUGFja2FyZCBFbnRlcnBy
# aXNlIENvbXBhbnkxGjAYBgNVBAsMEUhQIEN5YmVyIFNlY3VyaXR5MSswKQYDVQQD
# DCJIZXdsZXR0IFBhY2thcmQgRW50ZXJwcmlzZSBDb21wYW55MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwxteZQfuXv+1Z8x3SD7od4yB2d1pX8uCkeRj
# D+8wrGJFeIEv1qbmiHIgfx1Eq7NeM8WWyMdagFViBTmCPa+kZSYMfIrw5FAA72C8
# hCTOXDakq5TepAviT8+TyJEDvCUYsaPpxGhLWWasZR2ZCYL9EWiEte12VcxtqOt0
# EyroKsvdc/oVFcCCq4KGkk8PDSYLuZS3e+m28wxqIta4RWgJAw6R5D4zlBcYtluZ
# ubjPRV0ROrrD+J3cu6zk3GWek/JTTNViAHbXm8TQHYm+pZQCgAIT+hq53o2Zubih
# BJgv82OwedB7IM4/juPgVs89aHtdgFsSGhbreLknFI69a7R2NQIDAQABo4IBkDCC
# AYwwHwYDVR0jBBgwFoAUDuE6qFM6MdWKvsG7rWcaA4WtNA4wHQYDVR0OBBYEFMMi
# Fppu3tKM2eFlxSCPfzOVpr9oMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAA
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBKBgNVHSAE
# QzBBMDUGDCsGAQQBsjEBAgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3Rp
# Z28uY29tL0NQUzAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2Ny
# bC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNBQ29kZVNpZ25pbmdDQS5jcmwwcwYIKwYB
# BQUHAQEEZzBlMD4GCCsGAQUFBzAChjJodHRwOi8vY3J0LnNlY3RpZ28uY29tL1Nl
# Y3RpZ29SU0FDb2RlU2lnbmluZ0NBLmNydDAjBggrBgEFBQcwAYYXaHR0cDovL29j
# c3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQELBQADggEBAGif701b0sq1xhIiX7cx
# waHteqIhMhGQwLRtO4DF93ApmEla29EtfEDASgnmeZATJ5zxDY3vSeCspKWEr9pR
# AM91eemJjjYHqWKJsp2XBoSiuLpJpyhvKbPq2P9EVQH7LKpqv9EH9KlMOEtvK1+/
# qCnc/jVwsF03FO1Tg8SiEYxWnMNjUjOdzEBOFLmlRMs7He5pDXVyi85JMM7Ino98
# zwt3UWttL4NFldAjU4LbDJ3hUC38Bv28vaT+EizbZJA2t+PM1EKmYamtvzT2weYZ
# D4goOpfkjHf27Xi8XUwMWe+GXYYkmtI9oLvX2GGTI40rFiQXI8lVKYGG2r0+2x8z
# XM8wggV3MIIEX6ADAgECAhAT6ihwW/Ts7Qw2YwmAYUM2MA0GCSqGSIb3DQEBDAUA
# MG8xCzAJBgNVBAYTAlNFMRQwEgYDVQQKEwtBZGRUcnVzdCBBQjEmMCQGA1UECxMd
# QWRkVHJ1c3QgRXh0ZXJuYWwgVFRQIE5ldHdvcmsxIjAgBgNVBAMTGUFkZFRydXN0
# IEV4dGVybmFsIENBIFJvb3QwHhcNMDAwNTMwMTA0ODM4WhcNMjAwNTMwMTA0ODM4
# WjCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcT
# C0plcnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAs
# BgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCAEmUXNg7D2wiz0KxXDXbtzSfT
# TK1Qg2HiqiBNCS1kCdzOiZ/MPans9s/B3PHTsdZ7NygRK0faOca8Ohm0X6a9fZ2j
# Y0K2dvKpOyuR+OJv0OwWIJAJPuLodMkYtJHUYmTbf6MG8YgYapAiPLz+E/CHFHv2
# 5B+O1ORRxhFnRghRy4YUVD+8M/5+bJz/Fp0YvVGONaanZshyZ9shZrHUm3gDwFA6
# 6Mzw3LyeTP6vBZY1H1dat//O+T23LLb2VN3I5xI6Ta5MirdcmrS3ID3KfyI0rn47
# aGYBROcBTkZTmzNg95S+UzeQc0PzMsNT79uq/nROacdrjGCT3sTHDN/hMq7MkztR
# eJVni+49Vv4M0GkPGw/zJSZrM233bkf6c0Plfg6lZrEpfDKEY1WJxA3Bk1QwGROs
# 0303p+tdOmw1XNtB1xLaqUkL39iAigmTYo61Zs8liM2EuLE/pDkP2QKe6xJMlXzz
# awWpXhaDzLhn4ugTncxbgtNMs+1b/97lc6wjOy0AvzVVdAlJ2ElYGn+SNuZRkg7z
# Jn0cTRe8yexDJtC/QV9AqURE9JnnV4eeUB9XVKg+/XRjL7FQZQnmWEIuQxpMtPAl
# R1n6BB6T1CZGSlCBst6+eLf8ZxXhyVeEHg9j1uliutZfVS7qXMYoCAQlObgOK6ny
# TJccBz8NUvXt7y+CDwIDAQABo4H0MIHxMB8GA1UdIwQYMBaAFK29mHo0tCb3+sQm
# VO8DveAky1QaMB0GA1UdDgQWBBRTeb9aqitKz1SA4dibwJ3ysgNmyzAOBgNVHQ8B
# Af8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zARBgNVHSAECjAIMAYGBFUdIAAwRAYD
# VR0fBD0wOzA5oDegNYYzaHR0cDovL2NybC51c2VydHJ1c3QuY29tL0FkZFRydXN0
# RXh0ZXJuYWxDQVJvb3QuY3JsMDUGCCsGAQUFBwEBBCkwJzAlBggrBgEFBQcwAYYZ
# aHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAQEAk2X2
# N4OVD17Dghwf1nfnPIrAqgnw6Qsm8eDCanWhx3nJuVJgyCkSDvCtA9YJxHbf5aaB
# ladG2oJXqZWSxbaPAyJsM3fBezIXbgfOWhRBOgUkG/YUBjuoJSQOu8wqdd25cEE/
# fNBjNiEHH0b/YKSR4We83h9+GRTJY2eR6mcHa7SPi8BuQ33DoYBssh68U4V93JCh
# pLwt70ZyVzUFv7tGu25tN5m2/yOSkcZuQPiPKVbqX9VfFFOs8E9h6vcizKdWC+K4
# NB8m2XsZBWg/ujzUOAai0+aPDuO0cW1AQsWEtECVK/RloEh59h2BY5adT3Xg+Hzk
# jqnR8q2Ks4zHIc3C7zCCBfUwggPdoAMCAQICEB2iSDBvmyYY0ILgln0z02owDQYJ
# KoZIhvcNAQEMBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5
# MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBO
# ZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNBIENlcnRpZmljYXRpb24gQXV0
# aG9yaXR5MB4XDTE4MTEwMjAwMDAwMFoXDTMwMTIzMTIzNTk1OVowfDELMAkGA1UE
# BhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2Fs
# Zm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdv
# IFJTQSBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCGIo0yhXoYn0nwli9jCB4t3HyfFM/jJrYlZilAhlRGdDFixRDtsocnppnL
# lTDAVvWkdcapDlBipVGREGrgS2Ku/fD4GKyn/+4uMyD6DBmJqGx7rQDDYaHcaWVt
# H24nlteXUYam9CflfGqLlR5bYNV+1xaSnAAvaPeX7Wpyvjg7Y96Pv25MQV0SIAhZ
# 6DnNj9LWzwa0VwW2TqE+V2sfmLzEYtYbC43HZhtKn52BxHJAteJf7wtF/6POF6Yt
# VbC3sLxUap28jVZTxvC6eVBJLPcDuf4vZTXyIuosB69G2flGHNyMfHEo8/6nxhTd
# VZFuihEN3wYklX0Pp6F8OtqGNWHTAgMBAAGjggFkMIIBYDAfBgNVHSMEGDAWgBRT
# eb9aqitKz1SA4dibwJ3ysgNmyzAdBgNVHQ4EFgQUDuE6qFM6MdWKvsG7rWcaA4Wt
# NA4wDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0lBBYw
# FAYIKwYBBQUHAwMGCCsGAQUFBwMIMBEGA1UdIAQKMAgwBgYEVR0gADBQBgNVHR8E
# STBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNB
# Q2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmwwdgYIKwYBBQUHAQEEajBoMD8GCCsG
# AQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNBQWRk
# VHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5j
# b20wDQYJKoZIhvcNAQEMBQADggIBAE1jUO1HNEphpNveaiqMm/EAAB4dYns61zLC
# 9rPgY7P7YQCImhttEAcET7646ol4IusPRuzzRl5ARokS9At3WpwqQTr81vTr5/cV
# lTPDoYMot94v5JT3hTODLUpASL+awk9KsY8k9LOBN9O3ZLCmI2pZaFJCX/8E6+F0
# ZXkI9amT3mtxQJmWunjxucjiwwgWsatjWsgVgG10Xkp1fqW4w2y1z99KeYdcx0BN
# YzX2MNPPtQoOCwR/oEuuu6Ol0IQAkz5TXTSlADVpbL6fICUQDRn7UJBhvjmPeo5N
# 9p8OHv4HURJmgyYZSJXOSsnBf/M6BZv5b9+If8AjntIeQ3pFMcGcTanwWbJZGehq
# jSkEAnd8S0vNcL46slVaeD68u28DECV3FTSK+TbMQ5Lkuk/xYpMoJVcp+1EZx6El
# QGqEV8aynbG8HArafGd+fS7pKEwYfsR7MUFxmksp7As9V1DSyt39ngVR5UR43QHe
# sXWYDVQk/fBO4+L4g71yuss9Ou7wXheSaG3IYfmm8SoKC6W59J7umDIFhZ7r+YMp
# 08Ysfb06dy6LN0KgaoLtO0qqlBCk4Q34F8W2WnkzGJLjtXX4oemOCiUe5B7xn1qH
# I/+fpFGe+zmAEc3btcSnqIBv5VPU4OOiwtJbGvoyJi1qV3AcPKRYLqPzW0sH3DJZ
# 84enGm1YMYIQfDCCEHgCAQEwgZEwfDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdy
# ZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2Vj
# dGlnbyBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdvIFJTQSBDb2RlIFNpZ25pbmcg
# Q0ECEQCH1ynrkPcqQmDDnAr6qCDsMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGC
# NwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKULq3Qwp7pgz668iN43
# Na5fFYzZx7578cAX4jFnmZ3jMA0GCSqGSIb3DQEBAQUABIIBAE24DTk8YgKcUjqY
# 2fK+GOnqb3i7xOtPW1tb1NWgbpM9GLMC49LJgX6pIryE/TKCRLM1FCnqVf6orFpO
# c7E8Dd7A+tyqnjiz0ocxYxMHJGdjuAYBPx7dILoqV6TQ+MX9OTkI0Y37LatVrWi5
# zfriJBXl9dHBJMywrMH8ZXucvP8bpro3nC9cf8c9zlMbITQlmiMHe+MZVBED/G+0
# xTfN5/XCMuAFmUivzpPIeDdF7tjh+LFrMPj1xUNax3LFr0uu46PCb5M5fQ7EKlqP
# S/Dbf2EClSOX+YYA3sQ/tu0tLD+1dkbc4ItWR5Wq+vKDGcrIbevgP9VeO0nbgJP8
# l6ZVlCChgg49MIIOOQYKKwYBBAGCNwMDATGCDikwgg4lBgkqhkiG9w0BBwKggg4W
# MIIOEgIBAzENMAsGCWCGSAFlAwQCATCCAQ8GCyqGSIb3DQEJEAEEoIH/BIH8MIH5
# AgEBBgtghkgBhvhFAQcXAzAxMA0GCWCGSAFlAwQCAQUABCBRWaJtfvXK+oLuOdlw
# 8LroqgAZaMWbuR0OTqFzySOQMgIVALSlYfhzLWxFwjAYFdUJOUWtNUprGA8yMDIx
# MDQyNDA3MTI1MVowAwIBHqCBhqSBgzCBgDELMAkGA1UEBhMCVVMxHTAbBgNVBAoT
# FFN5bWFudGVjIENvcnBvcmF0aW9uMR8wHQYDVQQLExZTeW1hbnRlYyBUcnVzdCBO
# ZXR3b3JrMTEwLwYDVQQDEyhTeW1hbnRlYyBTSEEyNTYgVGltZVN0YW1waW5nIFNp
# Z25lciAtIEczoIIKizCCBTgwggQgoAMCAQICEHsFsdRJaFFE98mJ0pwZnRIwDQYJ
# KoZIhvcNAQELBQAwgb0xCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwg
# SW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE6MDgGA1UECxMx
# KGMpIDIwMDggVmVyaVNpZ24sIEluYy4gLSBGb3IgYXV0aG9yaXplZCB1c2Ugb25s
# eTE4MDYGA1UEAxMvVmVyaVNpZ24gVW5pdmVyc2FsIFJvb3QgQ2VydGlmaWNhdGlv
# biBBdXRob3JpdHkwHhcNMTYwMTEyMDAwMDAwWhcNMzEwMTExMjM1OTU5WjB3MQsw
# CQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNV
# BAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxKDAmBgNVBAMTH1N5bWFudGVjIFNI
# QTI1NiBUaW1lU3RhbXBpbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQC7WZ1ZVU+djHJdGoGi61XzsAGtPHGsMo8Fa4aaJwAyl2pNyWQUSym7wtkp
# uS7sY7Phzz8LVpD4Yht+66YH4t5/Xm1AONSRBudBfHkcy8utG7/YlZHz8O5s+K2W
# OS5/wSe4eDnFhKXt7a+Hjs6Nx23q0pi1Oh8eOZ3D9Jqo9IThxNF8ccYGKbQ/5IMN
# JsN7CD5N+Qq3M0n/yjvU9bKbS+GImRr1wOkzFNbfx4Dbke7+vJJXcnf0zajM/gn1
# kze+lYhqxdz0sUvUzugJkV+1hHk1inisGTKPI8EyQRtZDqk+scz51ivvt9jk1R1t
# ETqS9pPJnONI7rtTDtQ2l4Z4xaE3AgMBAAGjggF3MIIBczAOBgNVHQ8BAf8EBAMC
# AQYwEgYDVR0TAQH/BAgwBgEB/wIBADBmBgNVHSAEXzBdMFsGC2CGSAGG+EUBBxcD
# MEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3BzMCUGCCsGAQUF
# BwICMBkaF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMC4GCCsGAQUFBwEBBCIwIDAe
# BggrBgEFBQcwAYYSaHR0cDovL3Muc3ltY2QuY29tMDYGA1UdHwQvMC0wK6ApoCeG
# JWh0dHA6Ly9zLnN5bWNiLmNvbS91bml2ZXJzYWwtcm9vdC5jcmwwEwYDVR0lBAww
# CgYIKwYBBQUHAwgwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTMwHQYDVR0OBBYEFK9j1sqjToVy4Ke8QfMpojh/gHViMB8GA1UdIwQYMBaA
# FLZ3+mlIR59TEtXC6gcydgfRlwcZMA0GCSqGSIb3DQEBCwUAA4IBAQB16rAt1TQZ
# XDJF/g7h1E+meMFv1+rd3E/zociBiPenjxXmQCmt5l30otlWZIRxMCrdHmEXZiBW
# BpgZjV1x8viXvAn9HJFHyeLojQP7zJAv1gpsTjPs1rSTyEyQY0g5QCHE3dZuiZg8
# tZiX6KkGtwnJj1NXQZAv4R5NTtzKEHhsQm7wtsX4YVxS9U72a433Snq+8839A9fZ
# 9gOoD+NT9wp17MZ1LqpmhQSZt/gGV+HGDvbor9rsmxgfqrnjOgC/zoqUywHbnsc4
# uw9Sq9HjlANgCk2g/idtFDL8P5dA4b+ZidvkORS92uTTw+orWrOVWFUEfcea7CMD
# jYUq0v+uqWGBMIIFSzCCBDOgAwIBAgIQe9Tlr7rMBz+hASMEIkFNEjANBgkqhkiG
# 9w0BAQsFADB3MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9y
# YXRpb24xHzAdBgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxKDAmBgNVBAMT
# H1N5bWFudGVjIFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMTcxMjIzMDAwMDAw
# WhcNMjkwMzIyMjM1OTU5WjCBgDELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFu
# dGVjIENvcnBvcmF0aW9uMR8wHQYDVQQLExZTeW1hbnRlYyBUcnVzdCBOZXR3b3Jr
# MTEwLwYDVQQDEyhTeW1hbnRlYyBTSEEyNTYgVGltZVN0YW1waW5nIFNpZ25lciAt
# IEczMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArw6Kqvjcv2l7VBdx
# Rwm9jTyB+HQVd2eQnP3eTgKeS3b25TY+ZdUkIG0w+d0dg+k/J0ozTm0WiuSNQI0i
# qr6nCxvSB7Y8tRokKPgbclE9yAmIJgg6+fpDI3VHcAyzX1uPCB1ySFdlTa8CPED3
# 9N0yOJM/5Sym81kjy4DeE035EMmqChhsVWFX0fECLMS1q/JsI9KfDQ8ZbK2FYmn9
# ToXBilIxq1vYyXRS41dsIr9Vf2/KBqs/SrcidmXs7DbylpWBJiz9u5iqATjTryVA
# mwlT8ClXhVhe6oVIQSGH5d600yaye0BTWHmOUjEGTZQDRcTOPAPstwDyOiLFtG/l
# 77CKmwIDAQABo4IBxzCCAcMwDAYDVR0TAQH/BAIwADBmBgNVHSAEXzBdMFsGC2CG
# SAGG+EUBBxcDMEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3Bz
# MCUGCCsGAQUFBwICMBkaF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMEAGA1UdHwQ5
# MDcwNaAzoDGGL2h0dHA6Ly90cy1jcmwud3Muc3ltYW50ZWMuY29tL3NoYTI1Ni10
# c3MtY2EuY3JsMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIH
# gDB3BggrBgEFBQcBAQRrMGkwKgYIKwYBBQUHMAGGHmh0dHA6Ly90cy1vY3NwLndz
# LnN5bWFudGVjLmNvbTA7BggrBgEFBQcwAoYvaHR0cDovL3RzLWFpYS53cy5zeW1h
# bnRlYy5jb20vc2hhMjU2LXRzcy1jYS5jZXIwKAYDVR0RBCEwH6QdMBsxGTAXBgNV
# BAMTEFRpbWVTdGFtcC0yMDQ4LTYwHQYDVR0OBBYEFKUTAamfhcwbbhYeXzsxqnk2
# AHsdMB8GA1UdIwQYMBaAFK9j1sqjToVy4Ke8QfMpojh/gHViMA0GCSqGSIb3DQEB
# CwUAA4IBAQBGnq/wuKJfoplIz6gnSyHNsrmmcnBjL+NVKXs5Rk7nfmUGWIu8V4qS
# DQjYELo2JPoKe/s702K/SpQV5oLbilRt/yj+Z89xP+YzCdmiWRD0Hkr+Zcze1Gvj
# Uil1AEorpczLm+ipTfe0F1mSQcO3P4bm9sB/RDxGXBda46Q71Wkm1SF94YBnfmKs
# t04uFZrlnCOvWxHqcalB+Q15OKmhDc+0sdo+mnrHIsV0zd9HCYbE/JElshuW6YUI
# 6N3qdGBuYKVWeg3IRFjc5vlIFJ7lv94AvXexmBRyFCTfxxEsHwA/w0sUxmcczB4G
# o5BfXFSLPuMzW4IPxbeGAk5xn+lmRT92MYICWjCCAlYCAQEwgYswdzELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMR8wHQYDVQQLExZT
# eW1hbnRlYyBUcnVzdCBOZXR3b3JrMSgwJgYDVQQDEx9TeW1hbnRlYyBTSEEyNTYg
# VGltZVN0YW1waW5nIENBAhB71OWvuswHP6EBIwQiQU0SMAsGCWCGSAFlAwQCAaCB
# pDAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTIx
# MDQyNDA3MTI1MVowLwYJKoZIhvcNAQkEMSIEIHr39ARD45WjfF7PUkblu7uXYwpE
# hxgWBQkrXcMXhBKvMDcGCyqGSIb3DQEJEAIvMSgwJjAkMCIEIMR0znYAfQI5Tg2l
# 5N58FMaA+eKCATz+9lPvXbcf32H4MAsGCSqGSIb3DQEBAQSCAQB9MMnwlaN1/DqY
# +niy/fNxYl0WAeai+nDmI/LjvTBAHiZ9Cj2FNQ7PTqkhhPvdlNv2eukYJHxC0m1H
# gW+ev/4v2VnB+VGmmLizfLv7W2YlbAgp7SbGtmCjUu900fZ0vIkNdU4kZSIf7BW9
# KDxMF8sFcx2Cj7rkrVtozavtm7AuOvUXv6DgYtBOydKKUvDjmqjy8s+EnbekDlOn
# IyctnxqSrklyJb9ZtRYrqxBSwiMFXWlcMWf16FVztWNzY6ktD8yUufXyaSsoBGYl
# gxQBm1WtOcttqK8S27OIv89CYqwAjE0MUNCs9nRZK1yYsNOmlNoI6HGivhmiLbHx
# 9LoAuLJ8
# SIG # End signature block
