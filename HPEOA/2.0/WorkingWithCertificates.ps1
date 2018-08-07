<#********************************************Description********************************************

This script is a sample on how to work with different type of certificates.
You need change your OA connection,Username and Password based on your environment.
The sample includes:
                     How to work with CA certification.
					           How to work with LDAP certificate.
                     How to work with HPSIM certificate.
                     How to work with Remote Support certificate.
                     How to work with OA certificate. 
                     How to work with user certificate.					 
***************************************************************************************************#>

Write-Host "`n======================================================
                `nSelect 1 to work with CA certificate
                `nSelect 2 to work with LDAP certificate
                `nSelect 3 to work with HPSIM certificate
                `nSelect 4 to to work with Remote Support certificate
                `nSelect 5 to to work with OA certificate
                `nSelect 6 to to work with user certificate
                `nSelect 0 to to exit
                `n======================================================" -ForegroundColor DarkYellow
    $choice = Read-Host "`nEnter your choice`t"
    if($choice -eq 0)
    {
     exit
    }

    $OAAddress= Read-Host "Enter OA IP`t"
    $username =  Read-Host "Enter username`t"
    $password = Read-host "Enter password`t"

    
        # Connect to the OA 
     $connection =Connect-HPEOA -OA $OAAddress -Username $username -Password $password 
     if($connection -ne $null)
     {
        Write-Host "Connection successfully established"
     }
     else{
        Write-Host "Connection could not be established" -ForegroundColor Red
        exit
     }


    

    switch($choice)
    {
      1{
        ##example 1: How to work with CA certification.
        #step 1:Check the CA certificate is installed or not.
           
        $rtn = Get-HPEOACACertificate $connection 
        $caFlag=$false
        $caPrintfinger = Read-host "Enter certificate thumbprint`t"  

        if($rtn.CaCertificate -eq $null)
        {
          Write-Host "No CA certifcate is installed." -ForegroundColor Yellow
        }else{
                foreach($CA in $rtn.CaCertificate)
                {
                  if($CA.Sha1Fingerprint -eq $caPrintfinger)   
                    { 
                      Write-Host "The CA certificate is installed. " -ForegroundColor Green
                      $caFlag=$true
                    }
                }
                if(!$caFlag)
                {
                  Write-Host "The CA certificate is not installed." -ForegroundColor Red
                }
        }

        #Step 2:Install CA certificate by uploading certificate content. 
        $cetificatePath = Read-Host "Enter the certificate path`t"
        $cerCA= Get-Content $cetificatePath -Raw    
        $rc=Add-HPEOACertificate $connection -Type CA -Certificate $cerCA
        if($rc -eq $null)
        {
          Write-Host "Upload CA certificate success !" -ForegroundColor Green
          $CACertResult = $connection | Get-HPEOACertificate -Type CA
          $CACertResult.CaCertificate
        }
        else{
          $rcStatus=$rc.StatusType
          $rcMessage=$rc.StatusMessage
          Write-Host "Upload CA certificate fail ! Status Type:$rcStatus; Status Message:$rcMessage" -ForegroundColor Red
          exit
        }

        #Step 3:Confirm the CA has been installed.Repeat step 1.

        #Step 4:Remove installed CA certificate.
        $confirmMsg = Read-Host "Do you want to remove the Certificate (Type Yes or No)`t"
        if($confirmMsg.Trim().ToLower() -ne "yes")
        {
          exit
        }
       
        $rc=Remove-HPEOACertificate $connection -Type CA -Certificate $($CACertResult.CaCertificate[0].Sha1Fingerprint) 
        if($rc -eq $null)
        {
          Write-Host "Remove CA certificate success !" -ForegroundColor Green
        }else{
          $rcStatus=$rc.StatusType
          $rcMessage=$rc.StatusMessage
          Write-Host "Remove CA certificate fail ! Status Type:$rcStatus; Status Message:$rcMessage" -ForegroundColor Red
        }

        #Step 5:Confirm the CA has been Removed.Repeat step 1.
        break
      }

      2{
          ##example 2: How to work with LDAP certificate.
          #step 1:Check the LDAP certificate exists or not.
          $rtn= $connection |Get-HPEOACertificate -Type LDAP
          $rc=$rtn.LDAPCertificate
          $ldapFlag=$false
          $ldapMD5= Read-host "Enter LDAP MD5 thumbprint`t"   

          if($rc -eq $null)
          {
              Write-Host "No LDAP Certificate is installed." -ForegroundColor Yellow
          }else{
                foreach($ldapCer in $rc)
                {
                  if($ldapCer.MD5Fingerprint  -eq $ldapMD5 )   
                  { 
                        Write-Host "The LDAP certificate is installed. " -ForegroundColor Green
                        $ldapFlag=$true
                  }
                }
                if(!$ldapFlag)
                {
                  Write-Host "The LDAP certificate is not installed." -ForegroundColor Red
                }
            }

          #step 2:Import LDAP certificate by uploading certificate content.
          $cetificatePath = Read-Host "Enter the certificate path`t"
          $cerLDAP= Get-Content $cetificatePath -Raw 
          $rc=Add-HPEOACertificate $connection -Type LDAP -Certificate $cerLDAP

          if($rc -eq $null)
          {
            Write-Host "Success to install  LDAP certificate !" -ForegroundColor Green  
          }else{
                  $rcStatus=$rc.StatusType
                  $rcMessage=$rc.StatusMessage
                  Write-Host " Fail to install LDAP certificate . Status type: $rcStatus; Status message:$rcMessage" -ForegroundColor Red
          }

          #step 3:Check installed LDAP certificate.
          $rc = Get-HPEOALDAPCertificate $connection
          $ldapFlag=$false

          if($rc -eq $null)
          {
              Write-Host "No LDAP Certificate is installed." -ForegroundColor Yellow
          }
          else{
                foreach($i in $rc.LDAPCertificate)
                {
                  if($i.MD5Fingerprint  -eq $ldapMD5 )   
                  { 
                        Write-Host "The LDAP certificate is installed. " -ForegroundColor Green
                        $ldapFlag=$true
                  }
                }
                if(!$ldapFlag)
                {
                  Write-Host "The LDAP certificate is not installed." -ForegroundColor Red
                }
            }


          #step 4:Remove installed LDAP certificate.
          $confirmMsg = Read-Host "Do you want to remove the Certificate (Type Yes or No)`t"
          if($confirmMsg.Trim().ToLower() -ne "yes")
          {
            exit
          }
          $ldapCertFingerPrint = Read-host "Enter LDAP certificate finger print`t"
          $rc=Remove-HPEOACertificate $connection -Type LDAP $ldapCertFingerPrint
          if($rc -eq $null)
          {
            Write-Host "Remove LDAP certificate success !" -ForegroundColor Green
          }else{
                $rcStatus=$rc.StatusType
                $rcMessage=$rc.StatusMessage
                Write-Host "Remove LDAP certificate fail ! Status Type:$rcStatus; Status Message:$rcMessage" -ForegroundColor Red
          }

          #step 5:Check LDAP certificate removed success.Repeat step 1.

        break
      }

      3{

        ##example 3:How to work with HPSIM certificate
            #step 1: Check HPSIM certificate
            $rtn=$connection | Get-HPEOAHPSIMInfo 
            $wantedHPSIMCer = Read-Host "Enter HPSIM certificate thumb print`t"
            $hpsimFlag=$false
            if($rtn.TrustedServerCertificate -eq $null)
            {
              Write-Host "No HPSIM certificate be installed." -ForegroundColor Yellow
            }else{
                  foreach($i in $rtn.TrustedServerCertificate)
                  {
                      if($wantedHPSIMCer -contains $i.CommonName)
                        {
                          $cerName=$i.CommonName
                          Write-Host "The wanted HPSIM certificate `"$cerName`" has been installed" -ForegroundColor Green
                        }          
                  }
            }

            #step 2:Import hpsim certificate by hpsim certificate content.
            $simCertificatePath = Read-Host "Enter HPSIM certificate Path`t"
            $hpsimCer= Get-Content $simCertificatePath -Raw
            $rc=Add-HPEOACertificate $connection -Type HPSIM -Certificate $hpsimCer
            if($rc -eq $null)
            {
              Write-Host "HPSIM certificate is installed success !" -ForegroundColor Green 
            }
            else{
                    $rcStatus=$rc.StatusType
                    $rcMessage=$rc.StatusMessage
                    Write-Host " Fail to install HPSIM certificate. Status type: $rcStatus; Status message:$rcMessage"   -ForegroundColor Red
            }


            #*Step 2:Import hpsim certificate using URL use below code snippet.

            <#
            $hpSIMCertPath = Read-Host "Enter HPSIM certificate URL`t"
            $rc=Start-HPEOACertificateDownload $connection -Type HPSIM -URL $hpSIMCertPath   
            if($rc -eq $null)
            {
              Write-Host "Success to Download HPSIM certificate !" -ForegroundColor Green 
            }
            else{
                    $rcStatus=$rc.StatusType
                    $rcMessage=$rc.StatusMessage
                    Write-Host " Fail to download HPSIM certificate. Status type: $rcStatus; Status message:$rcMessage"   -ForegroundColor Red
            }#>

            #Step 3:Check wanted HPSIM certificate has been installed. Repeat Step 1.

            #Step 4:Remove installed HPSIM certificate.
            $confirmMsg = Read-Host "Do you want to remove the Certificate (Type Yes or No)`t"
            if($confirmMsg.Trim().ToLower() -ne "yes")
            {
              break
            }
            $SIMthumbPrint = Read-Host "Enter HPSIM certificate thumbprint to remove `t"
            $cerObj= New-Object -TypeName PSobject -Property @{"Connection"=$connection;"Type"="HPSIM";"Certificate"=$SIMthumbPrint}  # "Certificate" is HPSIM certificate CommonName value.
            $rc=$cerObj | Remove-HPEOACertificate
            if($rc -eq $null)
            {
              Write-Host "Success to remove HPSIM certificate !" -ForegroundColor Green 
            }
            else{
                    $rcStatus=$rc.StatusType
                    $rcMessage=$rc.StatusMessage
                    Write-Host " Fail to remove HPSIM certificate. Status type: $rcStatus; Status message:$rcMessage"   -ForegroundColor Red
            }

        break
      }

      4{

        ##example 4:How to work with Remote Support certificate
          #step 1: Check Remote Support certificate
          $rtn=$connection | Get-HPEOACertificate  -Type RemoteSupport 
          $wantedRemoteCer= Read-Host "Enter Remote support certificate foot print`t"  #"Certificate" value is certificate's SubjectCommonName
          $remoteFlag=$false
          if($rtn.RemoteSupportCertificate -eq $null)   
          {
            Write-Host "No HP Remote support certificate be installed." -ForegroundColor Yellow
          }else{
                foreach($i in $rtn.RemoteSupportCertificate)
                {
                    if($wantedRemoteCer -contains $i.SubjectCommonName)
                      {
                        $cerName=$i.SubjectCommonName 
                        Write-Host "The  Remote support certificate `"$cerName`" has been installed" -ForegroundColor Green
                        $remoteFlag=$true
                      }          
                }
                else(!$remoteFlag)
                {
                  Write-Host "The  Remote support certificate is not installed." -ForegroundColor Red
                }
          }


          #step 2:Import Remote support server certificate by upload certificate content.
          $remoteCertPath = Read-Host "Enter Remote certificate path`t"
          $cer = Get-Content $remoteCertPath -Raw 
          $cerObj= New-Object -TypeName PSobject -Property @{"Connection"=$connection;"Type"="RemoteSupport";"Certificate"="$cer"}
          $rc=$cerObj | Add-HPEOACertificate 
          if($rc -eq $null)
          {
            Write-Host "Success to add Remote support certificate !" -ForegroundColor Green 
          }
          else{
                  $rcStatus=$rc.StatusType
                  $rcMessage=$rc.StatusMessage
                  Write-Host " Fail to add Remote support certificate. Status type: $rcStatus; Status message:$rcMessage"   -ForegroundColor Red
          }

          #*step 2:Import Remote support server certificate by downloading certificate.
          <#
          $certURL = Read-Host "Enter remote support certificate URL`t"
          $rc=Start-HPEOACertificateDownload $connection -Type RemoteSupport -URL $ certURL
          if($rc -eq $null)
          {
            Write-Host "Success to add Remote support certificate !" -ForegroundColor Green 
          }
          else{
                  $rcStatus=$rc.StatusType
                  $rcMessage=$rc.StatusMessage
                  Write-Host " Fail to add Remote support certificate. Status type: $rcStatus; Status message:$rcMessage"   -ForegroundColor Red
          }
          #>

          #step 3:Check installed remote support server certificate. Repeat step 1.

          #step 4:Remove remote support server certificate.
          $confirmMsg = Read-Host "Do you want to remove the Certificate (Type Yes or No)`t"
          if($confirmMsg.Trim().ToLower() -ne "yes")
          {
            break
          }
          $remoteCertThumbprint = Read-Host "Enter thumb remote support print"`t
          $rc=Remove-HPEOACertificate $connection -Type RemoteSupport -Certificate $remoteCertThumbprint  #Certificate value is Certificate's SHA1 . 
          if($rc -eq $null)
          {
            Write-Host "Success to Remove Remote support certificate !" -ForegroundColor Green 
          }
          else{
                  $rcStatus=$rc.StatusType
                  $rcMessage=$rc.StatusMessage
                  Write-Host " Fail to Remove Remote support certificate. Status type: $rcStatus; Status message:$rcMessage"   -ForegroundColor Red
          }

        break
      }

      5{

        ###example 5:How to work with OA certificate
          ##Scenario 1:Selfsigned

          <#
          #Step 1:Start OA selfsigned certificate generation.
          $cerProperties= New-Object -TypeName PSobject -Property @{"connection"=$conns;"Hostname"="PowershellOA";"Organization"="HP";"State"="CQ";"Country"="CN";"City"="CQ"}  
          $cers= $cerProperties | Start-HPEOACertificateGeneration -Type SELFSIGNED

          foreach($i in $cers)
          {
            $okMessage= $i.StatusMessage.Split(".")
            $oaIP=$i.IP
            if($okMessage -contains "Successfully installed new self signed certificate")
                {
                  Write-Host " OA:$oaIP success to installed Selfsigned Certificate" -ForegroundColor Green
                }
            else{
                  $statusMessage=$i.StatusMessage
                  Write-Host " OA:$oaIP  fail to install selfsigned Certificate. Error message :$statusMessage"
                }
          }

          #Step 3:Check installed OA selfsigned certificate.
          $rc = Get-HPEOACertificate $connection -Type OA 
          $oaflag=$false
          foreach($i in $rc)
          {
              $oaIP=$i.IP
              $scer=$i.OnboardAdministrator
              foreach($s in $scer)
              {
                  if($s.CommonName -eq "PowershellOA")
                    {
                      Write-Host "OA:$oaIP selfsigned certificate has been installed." -ForegroundColor Green 
                      $oaflag=$true
                    }
              }
              if(!$oaflag)
              {
                Write-Host "OA:$oaIP selfsigned certificate not be found." -ForegroundColor Red
              }
          }
          #>

          ##Scenario 2:REQUEST.
          #Step 1:Start OA request certificate generation.
          $hostname = Read-Host "Enter hots name`t"
          $organization = Read-Host "Enter organization name `t"
          $city = Read-host "Enter City`t"
          $state = Read-host "Enter state`t"
          $country = Read-host "Enter country`t"
          $rc=Start-HPEOACertificateGeneration $connection -Type REQUEST -Hostname $hostname -Organization $organization -City $city -State $state -Country $country
          $cerContent=$rc.RequestedCertificate
          if($cerContent -eq $null)
          {
            Write-Host "Fail to generate OA Request certificate !" -ForegroundColor Red
          }
          else{
            Write-Host "Success to generate OA certificate. Status type: $cerContent"   -ForegroundColor Green
            Write-Host "Log on to OA web and download the CSR, submit the CSR to CA ang get the OA certificate" -ForegroundColor Green
          }

          #step 2:Use request certificate content generated in step 1 to be signed by 3rd CA server, getting signed certificate.

          #step 3:Import signed certificate by uploading certificate content.
          #$signedCer=get-content "C:\Users\Administrator\Desktop\CA\WestNorthRequest.cer" -Raw
          #Because OA not supports upload signed certificate content by command way, you need to do this on OA web page. 

          #*step 3:Import signed certificate by downloading certificate.
          $OAcertUrl = Read-Host "Enter OA certificate URL`t"
          $rc= Start-HPEOACertificateDownload $connection -Type OA -URL $OAcertUrl
          $rcMessage=$rc.StatusMessage
          $okMessage=$rcMessage.Split(".")
          if($okMessage -contains "Security Certificate accepted and applied")
            {
              Write-Host "Success to installed requested Certificate" -ForegroundColor Green
            }
          else{
              Write-Host "Fail to install requested Certificate. Error message :$rcMessage" -ForegroundColor Red
            }

          #Use this example scenario 1, step 3 to check installed requested OA certificate.


        break
      }

      6{

        ##Example 6:How to work with user certificate.
          ##Root CA and Level-1 CA must be installed then install user CA, making Two-Factor Authentication works.
                  
          #step 1:Install user CA by uploading certificate.
          $CAcertUrl = Read-host "Enter user certificate path`t"
          $userCA= Get-Content $CAcertUrl -Raw
          $username= Read-Host   "Enter the username, where the use certificate needs to be added`t"
          $rc=Add-HPEOACertificate $connection -Type User -Username $username -Certificate $userCA
          if($rc -eq $null)
          {
            Write-Host "Success to upload user certificate !" -ForegroundColor Green 
          }
          else{
                  $rcStatus=$rc.StatusType
                  $rcMessage=$rc.StatusMessage
                  Write-Host " Fail to upload user certificate. Status type: $rcStatus; Status message:$rcMessage"   -ForegroundColor Red
          }

          #step 4:Check user certificate.
          $userCertThumbPrint = Read-host "Enter user certificate thumbprint`t"
          $rtn = Get-HPEOAUser $connection -Username $username
          $oaIP=$rtn.IP
          $CAflag=$false

          if($rtn.Fingerprint -eq $null) 
          {
            Write-Host "OA:$oaIP, No user certificate be installed." -ForegroundColor Yellow
          }
          elseif($rtn.Fingerprint -eq $userCertThumbPrint)
                {
                    Write-Host "Wanted User certificate is installed." -ForegroundColor Green
                }
          else{
                Write-Host "Wanted user certificate is not installed." -ForegroundColor Red
              }

          #step 5:Remove user certificate
          $confirmMsg = Read-Host "Do you want to remove the Certificate (Type Yes or No)`t"
          if($confirmMsg.Trim().ToLower() -ne "yes")
          {
            break
          }
          $username = Read-Host "Enter username who's certificate needs to be removed"`t
          $rc= Remove-HPEOAUserCertificate $connection -Username $username  
          if($rc -eq $null)
          {
            Write-Host "Success to remove user certificate !" -ForegroundColor Green 
          }
          else{
                  $rcStatus=$rc.StatusType
                  $rcMessage=$rc.StatusMessage
                  Write-Host " Fail to remove user certificate. `nStatus type: $rcStatus; `nStatus message:$rcMessage"   -ForegroundColor Red
          }

          #step 6:Repeat step 4 to check the certificate has been removed successfully.

        break
      }

      default
      {
        Write-host "Invalid choice ..."
        exit
      }

    }

#Disconnect the connections.
Disconnect-HPEOA -Connection $connection

















# SIG # Begin signature block
# MIIjpgYJKoZIhvcNAQcCoIIjlzCCI5MCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCx//OnRIXlFUht
# rqqRiGAU10r/SV1N1W8VP1xhx0CZ5aCCHrIwggPuMIIDV6ADAgECAhB+k+v7fMZO
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
# lEM/RlUm1sT6iJXikZqjLQuF3qyM4PlncJ9xeQIx92GiKcQwggVpMIIEUaADAgEC
# AhAnlft9qr383J/sD2dic7k4MA0GCSqGSIb3DQEBCwUAMH0xCzAJBgNVBAYTAkdC
# MRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQx
# GjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSMwIQYDVQQDExpDT01PRE8gUlNB
# IENvZGUgU2lnbmluZyBDQTAeFw0xODAzMjEwMDAwMDBaFw0xOTAzMjEyMzU5NTla
# MIHSMQswCQYDVQQGEwJVUzEOMAwGA1UEEQwFOTQzMDQxCzAJBgNVBAgMAkNBMRIw
# EAYDVQQHDAlQYWxvIEFsdG8xHDAaBgNVBAkMEzMwMDAgSGFub3ZlciBTdHJlZXQx
# KzApBgNVBAoMIkhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBhbnkxGjAY
# BgNVBAsMEUhQIEN5YmVyIFNlY3VyaXR5MSswKQYDVQQDDCJIZXdsZXR0IFBhY2th
# cmQgRW50ZXJwcmlzZSBDb21wYW55MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAzqI1vNsHY9aqhM+vzhUIkq4Boums7iJ1wInnLei2Lbpmn75pQultxKMS
# bmQTkP0JKYTTQK9dTnq1CkyheRsOHoxf3Tuzhpi6ovmbOzDm9y55AZQkHDQK0Pcg
# 0MUQoHKtEJUifQYj8eASdA7qSqc3NROJljCLI4kP+MK/NDqrVsCy6M/KHMaj+4Tp
# pwV7egZ0tMkWIkWwhIelSIpaCElAy+/H1azQWpwZMmR5fX8yJqL0dRLwl/EF+zT7
# 8iwL1M5++NHoRhGSOehH97sX1L3FIdG2hRfs8JnVBop8pOFIFqtXojDkCdtdFNMe
# YY8PTVECNJiVBcvBoB/9v0X/HKKCMQIDAQABo4IBjTCCAYkwHwYDVR0jBBgwFoAU
# KZFg/4pN+uv5pmq4z/nmS71JzhIwHQYDVR0OBBYEFNGeIRuysIgJ0V7e2q8QhJ/p
# YhFCMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBGBgNVHSAEPzA9MDsGDCsGAQQBsjEB
# AgEDAjArMCkGCCsGAQUFBwIBFh1odHRwczovL3NlY3VyZS5jb21vZG8ubmV0L0NQ
# UzBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLmNvbW9kb2NhLmNvbS9DT01P
# RE9SU0FDb2RlU2lnbmluZ0NBLmNybDB0BggrBgEFBQcBAQRoMGYwPgYIKwYBBQUH
# MAKGMmh0dHA6Ly9jcnQuY29tb2RvY2EuY29tL0NPTU9ET1JTQUNvZGVTaWduaW5n
# Q0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJ
# KoZIhvcNAQELBQADggEBAJdXHI0K/7cogXHydvYmVcuNVOsMO4L0PL0EMtKYS1yP
# v/xtc2xtCoOJeYxwhE328UyEfNotQmqD5z4b6SlwnKRtw4Tu267aJkImnDRQu0u+
# eI3j2PORVJrrBlyRnPVS3/8uDIRcvmdqgvw4tWlFRfIYpFNvyv7ev6+tzjWjUT/z
# qVSsvImWN95ZILcaSfAAZaNX4LpkF8J5twCg40rvT22jRnWrsdv4h1ZtwHq2UsRf
# 1iE6i+2JKRqpwLw1gpTGxeMZSCJ/75g4q/6nwryHCnmBWhgBfR+u/f6fPrNRJZ1E
# uWcU/wlQb1vqs+qfH6sJseRE6+6aavDcNE+R+S1EJRcwggV0MIIEXKADAgECAhAn
# Zu5W60nzjqvXcKL8hN4iMA0GCSqGSIb3DQEBDAUAMG8xCzAJBgNVBAYTAlNFMRQw
# EgYDVQQKEwtBZGRUcnVzdCBBQjEmMCQGA1UECxMdQWRkVHJ1c3QgRXh0ZXJuYWwg
# VFRQIE5ldHdvcmsxIjAgBgNVBAMTGUFkZFRydXN0IEV4dGVybmFsIENBIFJvb3Qw
# HhcNMDAwNTMwMTA0ODM4WhcNMjAwNTMwMTA0ODM4WjCBhTELMAkGA1UEBhMCR0Ix
# GzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEa
# MBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKzApBgNVBAMTIkNPTU9ETyBSU0Eg
# Q2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQCR6FSS0gpWsawNJN3Fz0RndJkrN6N9I3AAcbxT38T6KhKPS38QVr2f
# cHK3YX/JSw8Xpz3jsARh7v8Rl8f0hj4K+j5c+ZPmNHrZFGvnnLOFoIJ6dq9xkNfs
# /Q36nGz637CC9BR++b7Epi9Pf5l/tfxnQ3K9DADWietrLNPtj5gcFKt+5eNu/Nio
# 5JIk2kNrYrhV/erBvGy2i/MOjZrkm2xpmfh4SDBF1a3hDTxFYPwyllEnvGfDyi62
# a+pGx8cgoLEfZd5ICLqkTqnyg0Y3hOvozIFIQ2dOciqbXL1MGyiKXCJ7tKuY2e7g
# UYPDCUZObT6Z+pUX2nwzV0E8jVHtC7ZcryxjGt9XyD+86V3Em69FmeKjWiS0uqlW
# Pc9vqv9JWL7wqP/0uK3pN/u6uPQLOvnoQ0IeidiEyxPx2bvhiWC4jChWrBQdnArn
# cevPDt09qZahSL0896+1DSJMwBGB7FY79tOi4lu3sgQiUpWAk2nojkxl8ZEDLXB0
# AuqLZxUpaVICu9ffUGpVRr+goyhhf3DQw6KqLCGqR84onAZFdr+CGCe01a60y1Dm
# a/RMhnEw6abfFobg2P9A3fvQQoh/ozM6LlweQRGBY84YcWsr7KaKtzFcOmpH4MN5
# WdYgGq/yapiqcrxXStJLnbsQ/LBMQeXtHT1eKJ2czL+zUdqnR+WEUwIDAQABo4H0
# MIHxMB8GA1UdIwQYMBaAFK29mHo0tCb3+sQmVO8DveAky1QaMB0GA1UdDgQWBBS7
# r34CPfqm8TyEjq3uOJjs2TIy1DAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUw
# AwEB/zARBgNVHSAECjAIMAYGBFUdIAAwRAYDVR0fBD0wOzA5oDegNYYzaHR0cDov
# L2NybC51c2VydHJ1c3QuY29tL0FkZFRydXN0RXh0ZXJuYWxDQVJvb3QuY3JsMDUG
# CCsGAQUFBwEBBCkwJzAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AudXNlcnRydXN0
# LmNvbTANBgkqhkiG9w0BAQwFAAOCAQEAZL+D8V+ahdDNuKEpVw3oWvfR6T7ydgRu
# 8VJwux48/00NdGrMgYIl08OgKl1M9bqLoW3EVAl1x+MnDl2EeTdAE3f1tKwc0Dur
# FxLW7zQYfivpedOrV0UMryj60NvlUJWIu9+FV2l9kthSynOBvxzz5rhuZhEFsx6U
# LX+RlZJZ8UzOo5FxTHxHDDsLGfahsWyGPlyqxC6Cy/kHlrpITZDylMipc6LrBnsj
# nd6i801Vn3phRZgYaMdeQGsj9Xl674y1a4u3b0b0e/E9SwTYk4BZWuBBJB2yjxVg
# WEfb725G/RX12V+as9vYuORAs82XOa6Fux2OvNyHm9Gm7/E7bxA4bzCCBeAwggPI
# oAMCAQICEC58h8wOk0pS/pT9HLfNNK8wDQYJKoZIhvcNAQEMBQAwgYUxCzAJBgNV
# BAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1Nh
# bGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSswKQYDVQQDEyJDT01P
# RE8gUlNBIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTEzMDUwOTAwMDAwMFoX
# DTI4MDUwODIzNTk1OVowfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIg
# TWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENB
# IExpbWl0ZWQxIzAhBgNVBAMTGkNPTU9ETyBSU0EgQ29kZSBTaWduaW5nIENBMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAppiQY3eRNH+K0d3pZzER68we
# /TEds7liVz+TvFvjnx4kMhEna7xRkafPnp4ls1+BqBgPHR4gMA77YXuGCbPj/aJo
# nRwsnb9y4+R1oOU1I47Jiu4aDGTH2EKhe7VSA0s6sI4jS0tj4CKUN3vVeZAKFBhR
# LOb+wRLwHD9hYQqMotz2wzCqzSgYdUjBeVoIzbuMVYz31HaQOjNGUHOYXPSFSmsP
# gN1e1r39qS/AJfX5eNeNXxDCRFU8kDwxRstwrgepCuOvwQFvkBoj4l8428YIXUez
# g0HwLgA3FLkSqnmSUs2HD3vYYimkfjC9G7WMcrRI8uPoIfleTGJ5iwIGn3/VCwID
# AQABo4IBUTCCAU0wHwYDVR0jBBgwFoAUu69+Aj36pvE8hI6t7jiY7NkyMtQwHQYD
# VR0OBBYEFCmRYP+KTfrr+aZquM/55ku9Sc4SMA4GA1UdDwEB/wQEAwIBhjASBgNV
# HRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEGA1UdIAQKMAgw
# BgYEVR0gADBMBgNVHR8ERTBDMEGgP6A9hjtodHRwOi8vY3JsLmNvbW9kb2NhLmNv
# bS9DT01PRE9SU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDBxBggrBgEFBQcB
# AQRlMGMwOwYIKwYBBQUHMAKGL2h0dHA6Ly9jcnQuY29tb2RvY2EuY29tL0NPTU9E
# T1JTQUFkZFRydXN0Q0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21v
# ZG9jYS5jb20wDQYJKoZIhvcNAQEMBQADggIBAAI/AjnD7vjKO4neDG1NsfFOkk+v
# wjgsBMzFYxGrCWOvq6LXAj/MbxnDPdYaCJT/JdipiKcrEBrgm7EHIhpRHDrU4ekJ
# v+YkdK8eexYxbiPvVFEtUgLidQgFTPG3UeFRAMaH9mzuEER2V2rx31hrIapJ1Hw3
# Tr3/tnVUQBg2V2cRzU8C5P7z2vx1F9vst/dlCSNJH0NXg+p+IHdhyE3yu2VNqPeF
# RQevemknZZApQIvfezpROYyoH3B5rW1CIKLPDGwDjEzNcweU51qOOgS6oqF8H8tj
# OhWn1BUbp1JHMqn0v2RH0aofU04yMHPCb7d4gp1c/0a7ayIdiAv4G6o0pvyM9d1/
# ZYyMMVcx0DbsR6HPy4uo7xwYWMUGd8pLm1GvTAhKeo/io1Lijo7MJuSy2OU4wqjt
# xoGcNWupWGFKCpe0S0K2VZ2+medwbVn4bSoMfxlgXwyaiGwwrFIJkBYb/yud29Ag
# yonqKH4yjhnfe0gzHtdl+K7J+IMUk3Z9ZNCOzr41ff9yMU2fnr0ebC+ojwwGUPuM
# J7N2yfTm18M04oyHIYZh/r9VdOEhdwMKaGy75Mmp5s9ZJet87EUOeWZo6CLNuO+Y
# hU2WETwJitB/vCgoE/tqylSNklzNwmWYBp7OSFvUtTeTRkF8B93P+kPvumdh/31J
# 4LswfVyA4+YWOUunMYIESjCCBEYCAQEwgZEwfTELMAkGA1UEBhMCR0IxGzAZBgNV
# BAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UE
# ChMRQ09NT0RPIENBIExpbWl0ZWQxIzAhBgNVBAMTGkNPTU9ETyBSU0EgQ29kZSBT
# aWduaW5nIENBAhAnlft9qr383J/sD2dic7k4MA0GCWCGSAFlAwQCAQUAoHwwEAYK
# KwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYB
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINkefLaZxrFr
# 4+ofm8K9xy7LcFdTfCjFnLnvUw0nsqdUMA0GCSqGSIb3DQEBAQUABIIBAKduWlAx
# NuUWZToyqtaH1s4pTRi/z/V5ujTB1/MMzmaeq/7Q+bk0j3jcQGs4FwhTSpXyomI3
# UrTQH794ip/myoi+SRFu8IjRm2Ln6SGKdfPfbJNUnA5jOVkSgGzHwxCJgY4aaS5Q
# HnmzOh3b5uGK13EeOTcGvcAHEAwfolCoTet9CMEW9wEiBh88Kd58NiKxQZcTEIZl
# 9DRj/KLBdE7CZq2CTJUfTPayiprXS/tawYlvZm7RYEv9IlgQQEP1kHbUOqw+zSLL
# NF1fm/yeQb9fxwBmEwp3+QJCs5TTALHahlQ5GwKJKbZLuXnpqAFpdA9Js8Z5tbBV
# RbmrsevRtleQUR2hggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQsw
# CQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNV
# BAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0
# OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3
# DQEHATAcBgkqhkiG9w0BCQUxDxcNMTgwODAyMDUyMDUxWjAjBgkqhkiG9w0BCQQx
# FgQUCH356CinQ57sA6zTbwoicIkI+bAwDQYJKoZIhvcNAQEBBQAEggEAkI4+Xy9w
# A7ZYfYapwq8dLQzXyWpkoSz5ikXXv5Lk/t97W9dNsbHeilrsbLA0dnGFhKxIvENv
# 8XqOFkt3Yiq2xXj6a1XCacmdDWupGIaP9AIARWLRDo7KFU8mgB1w6n9C+VaXFOpD
# bwNKBesy0HIoHHac18Yy5AHZ8MDp5IHd0S73XC1iHKL0GfyyuxjyhjSLPpglMiQa
# zU/GYAGgisveOf0pIHRwjIfOt4h+fmTLArKnOADn19KpBclFRC/YjebOm5BGvcH8
# haq2qzIJQHRMmDDX2rneWyr8b+GLHsbQc8ao8CENk41ti5ihqzPKjpq2xqEzsACu
# zp+omaxE+WxX3Q==
# SIG # End signature block
