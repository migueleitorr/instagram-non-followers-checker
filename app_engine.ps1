# Instagram Non-Followers & Live Verifier - Native Windows Engine v3 (Zero Python Needed)
$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::DefaultConnectionLimit = 32

$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$IndexFile = Join-Path $BaseDir "index.html"

if (-not (Test-Path $IndexFile)) {
    Write-Host ""
    Write-Host " [ERROR] Could not find index.html in: $BaseDir" -ForegroundColor Red
    Write-Host " Please make sure you EXTRACTED the .zip file to a folder before opening start_app.bat!" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press ENTER to close"
    exit 1
}

# Find an open port starting at 8765
$Port = 8765
$Listener = $null
for ($p = 8765; $p -le 8785; $p++) {
    try {
        $Listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $p)
        $Listener.Start()
        $Port = $p
        break
    } catch {
        $Listener = $null
    }
}

if ($null -eq $Listener) {
    Write-Host " [ERROR] Could not bind local port 8765-8785." -ForegroundColor Red
    Read-Host "Press ENTER to close"
    exit 1
}

$AppUrl = "http://127.0.0.1:$Port/index.html"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Instagram Non-Followers & Live Verifier App (v3)" -ForegroundColor White
Write-Host " Status : Running locally at $AppUrl" -ForegroundColor Green
Write-Host " Engine : Windows Native Crawler Verifier (No Login)" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " -> Opening app window now..." -ForegroundColor Yellow
Write-Host " -> Keep this window open in the background while using the app." -ForegroundColor Gray
Write-Host ""

# Create a RunspacePool for parallel Instagram HTTP checks (5 concurrent threads to avoid rate-limiting)
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
$RunspacePool.Open()

$VerifyScriptBlock = {
    param([string]$Username)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    $Url = "https://www.instagram.com/$Username/"
    $UserLower = $Username.ToLowerInvariant()

    # Step 1: Use Windows native curl.exe with Meta's official link-preview crawler User-Agent
    # Instagram serves server-rendered OpenGraph metadata (og:title, og:description) to facebookexternalhit/1.1
    # for all active accounts (public or private), and omits og:title for dead/404/deactivated accounts.
    $CurlExe = "$env:SystemRoot\System32\curl.exe"
    if (Test-Path $CurlExe) {
        try {
            $Html = & $CurlExe -s -L --max-time 8 --compressed `
                -A "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)" `
                -H "Accept-Language: en-US,en;q=0.9" `
                $Url 2>$null

            if ($null -ne $Html) {
                $Raw = ($Html -join "`n").ToLowerInvariant()
                if ($Raw.Length -gt 200) {
                    if ($Raw.Contains('property="og:title"') -or $Raw.Contains('property="og:description"') -or $Raw.Contains("(@$UserLower)")) {
                        return @{ u = $Username; active = $true }
                    }
                    # If Instagram returned a normal page shell without og:title (and not a login redirect), double-check with TelegramBot
                    $Html2 = & $CurlExe -s -L --max-time 8 --compressed `
                        -A "TelegramBot (like TwitterBot)" `
                        $Url 2>$null
                    $Raw2 = ($Html2 -join "`n").ToLowerInvariant()
                    if ($Raw2.Contains('property="og:title"') -or $Raw2.Contains('property="og:description"') -or $Raw2.Contains("(@$UserLower)")) {
                        return @{ u = $Username; active = $true }
                    }
                    if ($Raw.Contains("<title>instagram</title>") -or $Raw.Contains("page isn't available") -or $Raw.Contains("page not found")) {
                        return @{ u = $Username; active = $false }
                    }
                }
            }
        } catch {}
    }

    # Step 2: Fallback to .NET HttpWebRequest with GZip decompression and facebookexternalhit User-Agent
    try {
        $Req = [System.Net.HttpWebRequest]::Create($Url)
        $Req.Method = "GET"
        $Req.Timeout = 8000
        $Req.ReadWriteTimeout = 8000
        $Req.AllowAutoRedirect = $true
        $Req.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
        $Req.UserAgent = "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)"
        $Req.Headers.Add("Accept-Language", "en-US,en;q=0.9")

        $Resp = [System.Net.HttpWebResponse]$Req.GetResponse()
        if ([int]$Resp.StatusCode -eq 404) {
            $Resp.Close()
            return @{ u = $Username; active = $false }
        }

        $Stream = $Resp.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($Stream, [System.Text.Encoding]::UTF8)
        $Body = $Reader.ReadToEnd().ToLowerInvariant()
        $Reader.Close()
        $Resp.Close()

        if ($Body.Contains('property="og:title"') -or $Body.Contains('property="og:description"') -or $Body.Contains("(@$UserLower)")) {
            return @{ u = $Username; active = $true }
        }
        if ($Body.Contains("<title>instagram</title>") -or $Body.Contains("sorry, this page isn't available")) {
            return @{ u = $Username; active = $false }
        }
        return @{ u = $Username; active = $true }
    } catch [System.Net.WebException] {
        $WebResp = $_.Exception.Response
        if ($null -ne $WebResp -and [int]$WebResp.StatusCode -eq 404) {
            return @{ u = $Username; active = $false }
        }
        return @{ u = $Username; active = $true }
    } catch {
        return @{ u = $Username; active = $true }
    }
}

# Launch App Window (Edge or Chrome frameless app mode, fallback to default browser)
function Open-AppWindow([string]$Url) {
    $Browsers = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "$env:LocalAppData\Google\Chrome\Application\chrome.exe"
    )
    foreach ($Exe in $Browsers) {
        if (Test-Path $Exe) {
            try {
                Start-Process -FilePath $Exe -ArgumentList "--app=$Url", "--window-size=920,840"
                return
            } catch {}
        }
    }
    Start-Process $Url
}

Open-AppWindow $AppUrl

function Send-HttpResponse($Stream, [int]$StatusCode, [string]$StatusText, [string]$ContentType, [byte[]]$BodyBytes) {
    $Header = "HTTP/1.1 $StatusCode $StatusText`r`n" +
              "Content-Type: $ContentType`r`n" +
              "Content-Length: $($BodyBytes.Length)`r`n" +
              "Cache-Control: no-store, no-cache, must-revalidate`r`n" +
              "Access-Control-Allow-Origin: *`r`n" +
              "Connection: close`r`n`r`n"
    $HeaderBytes = [System.Text.Encoding]::ASCII.GetBytes($Header)
    $Stream.Write($HeaderBytes, 0, $HeaderBytes.Length)
    if ($BodyBytes.Length -gt 0) {
        $Stream.Write($BodyBytes, 0, $BodyBytes.Length)
    }
    $Stream.Flush()
}

# Main HTTP Server Loop
try {
    while ($true) {
        $Client = $Listener.AcceptTcpClient()
        try {
            $Client.ReceiveTimeout = 15000
            $Client.SendTimeout = 15000
            $Stream = $Client.GetStream()

            $HeaderMem = New-Object System.IO.MemoryStream
            $State = 0
            while ($true) {
                $b = $Stream.ReadByte()
                if ($b -eq -1) { break }
                $HeaderMem.WriteByte([byte]$b)
                if (($State -eq 0 -or $State -eq 2) -and $b -eq 13) { $State++ }
                elseif (($State -eq 1 -or $State -eq 3) -and $b -eq 10) { $State++ }
                else { $State = 0 }
                if ($State -eq 4 -or $HeaderMem.Length -gt 16384) { break }
            }

            $HeaderStr = [System.Text.Encoding]::ASCII.GetString($HeaderMem.ToArray())
            if ([string]::IsNullOrWhiteSpace($HeaderStr)) {
                $Client.Close()
                continue
            }

            $Lines = $HeaderStr -split "`r`n"
            $ReqParts = $Lines[0] -split " "
            $Method = $ReqParts[0]
            $Path = if ($ReqParts.Length -ge 2) { ($ReqParts[1] -split "\?")[0] } else { "/" }

            $ContentLength = 0
            foreach ($Line in $Lines) {
                if ($Line -match "^Content-Length:\s*(\d+)") {
                    $ContentLength = [int]$Matches[1]
                    break
                }
            }

            $BodyStr = ""
            if ($ContentLength -gt 0) {
                $BodyBytes = New-Object byte[] $ContentLength
                $ReadTotal = 0
                while ($ReadTotal -lt $ContentLength) {
                    $r = $Stream.Read($BodyBytes, $ReadTotal, ($ContentLength - $ReadTotal))
                    if ($r -le 0) { break }
                    $ReadTotal += $r
                }
                $BodyStr = [System.Text.Encoding]::UTF8.GetString($BodyBytes, 0, $ReadTotal)
            }

            if ($Method -eq "GET" -and $Path -eq "/api/ping") {
                $OutBytes = [System.Text.Encoding]::UTF8.GetBytes('{"status":"ok","version":"v3"}')
                Send-HttpResponse $Stream 200 "OK" "application/json; charset=utf-8" $OutBytes
            }
            elseif ($Method -eq "POST" -and $Path -eq "/api/verify") {
                $Payload = $BodyStr | ConvertFrom-Json
                $Usernames = @($Payload.usernames)

                $Jobs = @()
                foreach ($u in $Usernames) {
                    if ([string]::IsNullOrWhiteSpace($u)) { continue }
                    $PSInstance = [powershell]::Create().AddScript($VerifyScriptBlock).AddArgument([string]$u)
                    $PSInstance.RunspacePool = $RunspacePool
                    $Jobs += @{
                        PS = $PSInstance
                        Handle = $PSInstance.BeginInvoke()
                    }
                }

                $ActiveList = @()
                $DeadList = @()
                foreach ($Job in $Jobs) {
                    try {
                        $Res = $Job.PS.EndInvoke($Job.Handle)
                        if ($Res -and $Res[0].active -eq $false) {
                            $DeadList += $Res[0].u
                        } elseif ($Res) {
                            $ActiveList += $Res[0].u
                        }
                    } catch {} finally {
                        $Job.PS.Dispose()
                    }
                }

                Write-Host (" [Verified Batch] Active: {0} | Dead/404: {1}" -f $ActiveList.Count, $DeadList.Count) -ForegroundColor Gray

                $ActiveJson = ($ActiveList | ForEach-Object { '"' + $_ + '"' }) -join ","
                $DeadJson = ($DeadList | ForEach-Object { '"' + $_ + '"' }) -join ","
                $JsonStr = "{`"active`":[$ActiveJson],`"dead`":[$DeadJson]}"
                $OutBytes = [System.Text.Encoding]::UTF8.GetBytes($JsonStr)
                Send-HttpResponse $Stream 200 "OK" "application/json; charset=utf-8" $OutBytes
            }
            elseif ($Method -eq "GET" -and ($Path -eq "/" -or $Path -eq "/index.html")) {
                $HtmlBytes = [System.IO.File]::ReadAllBytes($IndexFile)
                Send-HttpResponse $Stream 200 "OK" "text/html; charset=utf-8" $HtmlBytes
            }
            else {
                $NotFound = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
                Send-HttpResponse $Stream 404 "Not Found" "text/plain; charset=utf-8" $NotFound
            }
        } catch {
        } finally {
            $Client.Close()
        }
    }
} finally {
    $Listener.Stop()
    $RunspacePool.Close()
}
