# Instagram Non-Followers & Live Verifier - Native Windows Engine v9 (Follower Count Ranking + 404 Pruning)
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
Write-Host " Instagram Non-Followers & Live Verifier App (v9)" -ForegroundColor White
Write-Host " Status : Running locally at $AppUrl" -ForegroundColor Green
Write-Host " Engine : Live 404 Verifier + Follower Count Extractor" -ForegroundColor Green
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

    function Parse-FollowerCount([string]$HtmlText) {
        if ([string]::IsNullOrWhiteSpace($HtmlText)) { return -1 }

        # 1. Check exact JSON count if embedded
        $JsonMatch = [regex]::Match($HtmlText, '"(?:edge_followed_by"\s*:\s*\{\s*"count|follower_count)"\s*:\s*(\d+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($JsonMatch.Success) {
            return [int64]$JsonMatch.Groups[1].Value
        }

        # 2. Check OpenGraph / meta description text (supports English & Spanish formats)
        # Examples: "63K Followers", "1,234 Followers", "1.5M Followers", "63,4 mil seguidores", "1.234 seguidores"
        $Decoded = [System.Net.WebUtility]::HtmlDecode($HtmlText)
        $DescMatch = [regex]::Match(
            $Decoded,
            '(?:content=["''][^"'']*?|\b)([0-9][0-9.,\s]*?)\s*(k|m|b|mil|millones|de\s+millones)?\s*(?:de\s+)?(?:followers|follower|seguidores|seguidor)\b',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
        if ($DescMatch.Success) {
            $NumRaw = ($DescMatch.Groups[1].Value -replace '\s+', '').Trim()
            $Suffix = $DescMatch.Groups[2].Value.Trim().ToLowerInvariant()

            $Mult = 1.0
            if ($Suffix -eq 'k' -or $Suffix -eq 'mil') { $Mult = 1000.0 }
            elseif ($Suffix -eq 'm' -or $Suffix -eq 'millones' -or $Suffix -eq 'de millones') { $Mult = 1000000.0 }
            elseif ($Suffix -eq 'b') { $Mult = 1000000000.0 }

            if ($Mult -gt 1.0) {
                $Norm = $NumRaw.Replace(',', '.')
                $Val = 0.0
                if ([double]::TryParse($Norm, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$Val)) {
                    return [int64][Math]::Round($Val * $Mult)
                }
            } else {
                $DigitsOnly = $NumRaw -replace '[^\d]', ''
                if ($DigitsOnly.Length -gt 0) {
                    return [int64]$DigitsOnly
                }
            }
        }
        return -1
    }

    $CurlExe = "$env:SystemRoot\System32\curl.exe"
    if (Test-Path $CurlExe) {
        try {
            $Html = & $CurlExe -s -L --max-time 8 --compressed `
                -A "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)" `
                -H "Accept-Language: en-US,en;q=0.9" `
                $Url 2>$null

            if ($null -ne $Html) {
                $RawText = ($Html -join "`n")
                $Raw = $RawText.ToLowerInvariant()
                if ($Raw.Length -gt 200) {
                    if ($Raw.Contains('property="og:title"') -or $Raw.Contains('property="og:description"') -or $Raw.Contains("(@$UserLower)")) {
                        $FCount = Parse-FollowerCount $RawText
                        return @{ u = $Username; active = $true; followers = $FCount }
                    }
                    # Secondary check with TelegramBot
                    $Html2 = & $CurlExe -s -L --max-time 8 --compressed `
                        -A "TelegramBot (like TwitterBot)" `
                        -H "Accept-Language: en-US,en;q=0.9" `
                        $Url 2>$null
                    $RawText2 = ($Html2 -join "`n")
                    $Raw2 = $RawText2.ToLowerInvariant()
                    if ($Raw2.Contains('property="og:title"') -or $Raw2.Contains('property="og:description"') -or $Raw2.Contains("(@$UserLower)")) {
                        $FCount2 = Parse-FollowerCount $RawText2
                        return @{ u = $Username; active = $true; followers = $FCount2 }
                    }
                    if ($Raw.Contains("<title>instagram</title>") -or $Raw.Contains("page isn't available") -or $Raw.Contains("page not found")) {
                        return @{ u = $Username; active = $false; followers = -1 }
                    }
                }
            }
        } catch {}
    }

    # Step 2: Fallback to .NET HttpWebRequest
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
            return @{ u = $Username; active = $false; followers = -1 }
        }

        $Stream = $Resp.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($Stream, [System.Text.Encoding]::UTF8)
        $BodyText = $Reader.ReadToEnd()
        $Body = $BodyText.ToLowerInvariant()
        $Reader.Close()
        $Resp.Close()

        if ($Body.Contains('property="og:title"') -or $Body.Contains('property="og:description"') -or $Body.Contains("(@$UserLower)")) {
            $FCount = Parse-FollowerCount $BodyText
            return @{ u = $Username; active = $true; followers = $FCount }
        }
        if ($Body.Contains("<title>instagram</title>") -or $Body.Contains("sorry, this page isn't available")) {
            return @{ u = $Username; active = $false; followers = -1 }
        }
        return @{ u = $Username; active = $true; followers = -1 }
    } catch [System.Net.WebException] {
        $WebResp = $_.Exception.Response
        if ($null -ne $WebResp -and [int]$WebResp.StatusCode -eq 404) {
            return @{ u = $Username; active = $false; followers = -1 }
        }
        return @{ u = $Username; active = $true; followers = -1 }
    } catch {
        return @{ u = $Username; active = $true; followers = -1 }
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
                Start-Process -FilePath $Exe -ArgumentList "--app=$Url", "--window-size=940,860"
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
                $OutBytes = [System.Text.Encoding]::UTF8.GetBytes('{"status":"ok","version":"v6"}')
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
                $CountsPairs = @()
                foreach ($Job in $Jobs) {
                    try {
                        $Res = $Job.PS.EndInvoke($Job.Handle)
                        if ($Res -and $Res[0].active -eq $false) {
                            $DeadList += $Res[0].u
                        } elseif ($Res) {
                            $ActiveList += $Res[0].u
                            if ($null -ne $Res[0].followers -and [int64]$Res[0].followers -ge 0) {
                                $CountsPairs += ('"' + $Res[0].u + '":' + [int64]$Res[0].followers)
                            }
                        }
                    } catch {} finally {
                        $Job.PS.Dispose()
                    }
                }

                Write-Host (" [Verified Batch] Active: {0} | Dead/404: {1} | Follower Counts Parsed: {2}" -f $ActiveList.Count, $DeadList.Count, $CountsPairs.Count) -ForegroundColor Gray

                $ActiveJson = ($ActiveList | ForEach-Object { '"' + $_ + '"' }) -join ","
                $DeadJson = ($DeadList | ForEach-Object { '"' + $_ + '"' }) -join ","
                $CountsJson = $CountsPairs -join ","
                $JsonStr = "{`"active`":[$ActiveJson],`"dead`":[$DeadJson],`"counts`":{$CountsJson}}"
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
