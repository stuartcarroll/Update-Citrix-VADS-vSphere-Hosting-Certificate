<#
Fix XenDesktop Hosting Connection trusted cert 
Author: Stuart Carroll, Coffee Cup Solutions (@stuart_carroll)
WWW: https://www.coffeecupsolutions.com/

v1.0 -12/2017 
v1.1 - 09/2020 - Implemented workaround for TLS protocol issue
v1.2 - 29/6/2021 - Fixed remote cert extraction issue 

#>

if ( (Get-PSSnapin -Name citrix* -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin citrix*
}

$HostConPSDrive = "XDHyp:\Connections"
$XDHosts = get-childitem $HostConPSDrive | Where-Object {$_.ConnectionType -eq "VCenter"} 

$CertDir = $PSScriptRoot+"\vcenter-certs\"

    If(!(test-path $CertDir))
        {
              New-Item -ItemType Directory -Force -Path $CertDir
        } else {
              Remove-Item $CertDir -Force -Recurse
              New-Item -ItemType Directory -Force -Path $CertDir
              }

foreach ($xdh in $XDHosts ){

    $xdname = $xdh.HypervisorConnectionName
    $uid = $xdh.HypervisorConnectionUid
    $uri = $xdh.hypervisoraddress | out-string
    $url = $uri -Replace "/sdk",""
    $thumb = $xdh.SslThumbprints
    $literalpath = $HostConPSDrive+"\"+$xdname
    $outfilename = $CertDir+$uid+".cer"

    
    write-host "<----------------------------->"
    write-host "Hosting connection name: "$xdname -ForegroundColor Yellow
    write-host "Hosting connection UID: "$uid
    write-host "Hosting connection URL: "$url
    write-host "Current SSL Thumbprint: "$thumb -ForegroundColor Yellow
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

    [System.Uri] $u = New-Object System.Uri($url)
    $webRequest = [Net.WebRequest]::Create($u)


    try { $webRequest.GetResponse() } catch {}
    $cert = $webRequest.ServicePoint.Certificate
    $bytes = $cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    set-content -value $bytes -encoding byte -path $outfilename

    $ExpandCert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $outfilename

    Import-Certificate -FilePath $outfilename -CertStoreLocation Cert:\LocalMachine\TrustedPeople

    $thumbprint = $ExpandCert.Thumbprint | out-string

    write-host "New SSL Thumbprint: "$thumbprint

    if ($xdh.SslThumbprints -eq $ExpandCert.Thumbprint){
        write-host "The current root certificate extracted from VCenter is already trusted by XenDesktop. No Action needed." -ForegroundColor Green
        } 
        else
        {
        write-host "The current root certificate extracted from VCenter is NOT trusted by XenDesktop." -ForegroundColor Red

        write-host "Setting new SSL thumbnail" -ForegroundColor Cyan

        $cred = Get-Credential 

        write-host "Running: set-item -LiteralPath "$literalpath" -username <Username> -Securepassword <Password> -sslthumbprint "$thumbprint" -hypervisorAddress "$url -ForegroundColor Cyan

        Set-Item -LiteralPath $literalpath -username $cred.username -Securepassword $cred.password -sslthumbprint $ExpandCert.Thumbprint -hypervisorAddress $url


        }

    }
