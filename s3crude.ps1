param(
    [Parameter(Mandatory = $true)]
    [string] $ecsHost,
    [Parameter(Mandatory = $true)]
    [string] $httpOrHttps,
    [Parameter(Mandatory = $true)]
    [string] $ecsPort,
    [Parameter(Mandatory = $true)]
    [string] $requestUri,
    [Parameter(Mandatory = $true)]
    [string] $requestType,
    [Parameter(Mandatory = $false)]
    [string] $contentType,
    [Parameter(Mandatory = $false)]
    [string] $downloadFile,
    [Parameter(Mandatory = $false)]
    [string] $uploadFile,
    [Parameter(Mandatory = $false)]
    [string] $xmlBody,
    [switch] $insecure = $false,
    [switch] $responseBody = $false,
    [switch] $checksum = $false
)

# Add ability to encode URI/URL.
Add-Type -AssemblyName System.Web

# Ignore certificate errors for HTTPS if specified (naughty)
if ($insecure) {
    if ("TrustAllCertsPolicy" -as [type]) {
    } else {
        Add-Type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
                public bool CheckValidationResult(
                    ServicePoint srvPoint, X509Certificate certificate,
                    WebRequest request, int certificateProblem) {
                    return true;
                }
            }
"@    
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12
    }
}

# Credit must go to here for this function used to Format XML - https://devblogs.microsoft.com/powershell/format-xml/
function Format-XML ([xml]$xml, $indent=2)
{
    $StringWriter = New-Object System.IO.StringWriter
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
    $xmlWriter.Formatting = "indented"
    $xmlWriter.Indentation = $Indent
    $xml.WriteContentTo($XmlWriter)
    $XmlWriter.Flush()
    $StringWriter.Flush()
    Write-Output $StringWriter.ToString()
}

# Function to calculate HMAC-SHA1 hash
function hmacSha1($message, $secret)
{
    $hmacsha = [System.Security.Cryptography.KeyedHashAlgorithm]::Create("HMACSHA1")
    $hmacsha.key = [System.Text.Encoding]::UTF8.GetBytes($password)
    $signature = [Convert]::ToBase64String($hmacsha.ComputeHash([System.Text.Encoding]::UTF8.Getbytes(${message})))
	
	return $signature
}

# Function to calculate MD5 digest
function md5Digest($message)
{
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    $hash = $md5.ComputeHash($utf8.GetBytes($message))
    $hashBase64 = [Convert]::ToBase64String(${hash})

    return $hashBase64
}

# Get some variables together for signature calculation
$baseurl = $httpOrHttps + "://" + $ecsHost + ":" + $ecsPort
$requestUrl = $baseurl + $requestUri
$now = [DateTime]::UtcNow
$dateFormatted = $now.ToString("ddd, dd MMM yyyy HH:mm:ss") + " GMT"
$contentType = "application/xml"
$requestType = $requestType.ToUpper()

# If checksum switch is set, calculate Content-MD5 and add it to request header.
# Intended for API methods where Content-MD5 is compulsory. For example, PUT operation on bucket lifecycle.
$headers = [ordered]@{}
if ($checksum) {
    $contentMd5 = md5Digest -message $xmlBody
    $headers = [ordered]@{ "Content-MD5"=("{0}" -f $contentMd5) }
}

$stringToSign = $requestType + "`n"
$stringToSign += $contentMd5 + "`n"
$stringToSign += $contentType + "`n"
$stringToSign += $dateFormatted + "`n"
$stringToSign += $requestUri

# Interactively get object user credentials
# $getCreds = Get-Credential
# $username = $getCreds.UserName
# $password = $getCreds.GetNetworkCredential().Password

# Or comment out interactive get credentials section and hard code them here. Perhaps handy for automation.
$username = "produser1"
$password = 'YkldwMuerHOGfuJPS+82MoC1Anu/P0pg1keNmSVd'

# Calculate the signature (v2)
$signature = hmacSha1 -message $stringToSign -secret $password

# Build request headers including signature
$headers.Add("Date", $dateFormatted)
$headers.Add("Authorization", "AWS $username`:$signature")

# Send API request to target ECS
$progressPreference = 'SilentlyContinue'
if ($downloadFile) {
    $response = Invoke-RestMethod -Uri $requestUrl -Method $requestType -Headers $headers -ContentType $contentType -OutFile $downloadFile
} elseif ($uploadFile) {
    $response = Invoke-RestMethod -Uri $requestUrl -Method $requestType -Headers $headers -ContentType $contentType -InFile $uploadFile
} elseif ($xmlBody) {
    $response = Invoke-RestMethod -Uri $requestUrl -Method $requestType -Headers $headers -ContentType $contentType -Body $xmlBody
}    
else {
    $response = Invoke-RestMethod -Uri $requestUrl -Method $requestType -Headers $headers -ContentType $contentType
}
$progressPreference = 'Continue'

# Exit if there is an error response in the API call. Otherwise continue.
if ($? -eq $false) {
    exit
}

# Return response object
$response

# Output HTTP response body if 'responseBody' switch is specified
if ($responseBody) {
    # Attempt to type cast response content into XML
    try { $responseXml = $([xml]$response.Content) } catch {}
    # If XML is found in response body (even if empty) then format the XML in our output
    if ($responseXml) {
        Format-Xml ($responseXml)
    }
}

Remove-Variable * -ErrorAction SilentlyContinue
exit

