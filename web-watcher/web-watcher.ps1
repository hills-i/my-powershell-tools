# Web-Watcher Main Script
# This script will perform website monitoring, diff detection, and reporting.
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# --- Initial Setup ---
Add-Type -AssemblyName System.Web
$ErrorActionPreference = "Stop" # Exit script on terminating errors

# Set console encoding for proper Japanese display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- Functions ---

function Get-SiteContent($url, $directory) {
    try {
        Write-Host "Processing $url"
        $uri = [System.Uri]$url
        $hostname = $uri.Host
        $outputFilePath = Join-Path $directory "$hostname.html"

        $response = Invoke-WebRequest -Uri $url
        $filteredContent = $response.Content -replace 'password\s*[:=]\s*["''][^"''>]*["'']', 'password="***"' -replace 'api[_-]?key\s*[:=]\s*["''][^"''>]*["'']', 'api_key="***"' -replace 'token\s*[:=]\s*["''][^"''>]*["'']', 'token="***"'
        $filteredContent | Out-File -FilePath $outputFilePath -Encoding utf8

        Write-Host " - Saved to $outputFilePath"
        return @{
            Success       = $true
            FilePath      = $outputFilePath
            Hostname      = $hostname
            Content       = $filteredContent
        }
    } catch {
        Write-Warning "Failed to process '$url'. Error: $($_.Exception.Message)"
        return @{ Success = $false }
    }
}

function Compare-SiteContent($oldPath, $newPath) {
    if (Test-Path $oldPath) {
        Write-Host " - Comparing with $oldPath"
        return Compare-Object -ReferenceObject (Get-Content $oldPath) -DifferenceObject (Get-Content $newPath)
    }
    Write-Host " - Previous file not found, skipping comparison."
    return $null
}

function Summarize-Changes($siteChange, $apiKey) {
    try {
        Write-Host "Summarizing changes for $($siteChange.Url)"
        $formattedDiff = $siteChange.Diff | ForEach-Object {
            $indicator = switch ($_.SideIndicator) {
                '<=' { '-' }
                '=>' { '+' }
                default { '' }
            }
            "$indicator$($_.InputObject)"
        } | Out-String

        $prompt = @"
Summarize the user-visible changes based on the given diff and new page content in Japanese. Focus on new features, updated text, or removed sections. Ignore minor style changes. 

## Diff (`-` indicates removed, `+` indicates added)
```diff
$formattedDiff
```
Output the summary in Japanese.
"@
        $body = @{
            model = "gpt-4.1-nano"
            messages = @(
                @{ role = "system"; content = "You are a helpful assistant who summarizes website changes for a user." },
                @{ role = "user"; content = $prompt }
            )
            temperature = 0.5
        } | ConvertTo-Json -Depth 5

        # Call the API with UTF-8 encoding
        $webRequest = [System.Net.WebRequest]::Create("https://api.openai.com/v1/chat/completions")
        $webRequest.Method = "POST"
        $webRequest.ContentType = "application/json; charset=utf-8"
        $webRequest.Headers.Add("Authorization", "Bearer $apiKey")
        
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $webRequest.ContentLength = $bodyBytes.Length
        
        $requestStream = $webRequest.GetRequestStream()
        $requestStream.Write($bodyBytes, 0, $bodyBytes.Length)
        $requestStream.Close()
        
        $webResponse = $webRequest.GetResponse()
        $responseStream = $webResponse.GetResponseStream()
        $reader = [System.IO.StreamReader]::new($responseStream, [System.Text.Encoding]::UTF8)
        $responseText = $reader.ReadToEnd()
        $reader.Close()
        $webResponse.Close()
        $response = $responseText | ConvertFrom-Json
                
                # Validate API response structure
        if (-not $response -or -not $response.choices -or $response.choices.Count -eq 0 -or -not $response.choices[0].message) {
            throw "Invalid API response structure"
        }
        
        $summary = $response.choices[0].message.content.Trim()
        
        # Ensure UTF-8 string handling
        $summaryBytes = [System.Text.Encoding]::UTF8.GetBytes($summary)
        $summary = [System.Text.Encoding]::UTF8.GetString($summaryBytes)
        Write-Host " - Summary received.  $summary"
        Write-Host " - Summary received."
        return $summary
    } catch {
        Write-Warning "Failed to get summary for '$($siteChange.Url)'. Error: $($_.Exception.Message)"
        return "Failed to generate summary."
    }
}

function Generate-Report($changedSites, $reportPath) {
    Write-Host "`n--- Generating HTML report... ---"
    $timestamp = Get-Date -Format yyyy-MM-dd
    $css = @"
<style>
    body { font-family: sans-serif; line-height: 1.6; }
    h1, h2 { border-bottom: 2px solid #eee; padding-bottom: 5px; }
    .site-section { border: 1px solid #ccc; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
    .summary { background-color: #f8f9fa; border-left: 5px solid #007bff; padding: 10px; margin-top: 10px; }
    pre { background-color: #f1f1f1; padding: 10px; border-radius: 3px; white-space: pre-wrap; word-wrap: break-word; }
    .diff-add { color: #28a745; }
    .diff-del { color: #dc3545; text-decoration: line-through; }
    .toggle-details { cursor: pointer; }
    .details-content { display: none; }
</style>
"@
    $javascript = @"
<script>
    function toggleDetails(id) {
        var element = document.getElementById(id);
        if (element.style.display === 'none' || element.style.display === '') {
            element.style.display = 'block';
        } else {
            element.style.display = 'none';
        }
    }
</script>
"@
    $htmlBody = "<h1>Web-Watcher Report - $timestamp</h1>"
    $siteIndex = 0
    foreach ($site in $changedSites) {
        $htmlDiff = ($site.Diff | ForEach-Object {
            $line = [System.Web.HttpUtility]::HtmlEncode($_.InputObject)
            switch ($_.SideIndicator) {
                '<=' { "<span class='diff-del'>-$line</span>" }
                '=>' { "<span class='diff-add'>+$line</span>" }
                default { $line }
            }
        }) -join "`n"
        $encodedSummary = [System.Web.HttpUtility]::HtmlEncode($site.Summary) -replace "`n", "<br>"
        $detailsId = "details-$siteIndex"
        $htmlBody += @"
<div class='site-section'>
    <h2><a href='$($site.Url)' target='_blank'>$($site.Url)</a></h2>
    <h3>Summary of Changes</h3>
    <div class='summary'>
        <p>$encodedSummary</p>
    </div>
    <h3 class='toggle-details' onclick="toggleDetails('$detailsId')">Detail (click to toggle)</h3>
    <pre id='$detailsId' class='details-content'>$htmlDiff</pre>
</div>
"@
        $siteIndex++
    }

    $htmlContent = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8' />
    <title>Web-Watcher Report</title>
    $css
    $javascript
</head>
<body>
    $htmlBody
</body>
</html>
"@
    [System.IO.File]::WriteAllText($reportPath, $htmlContent, [System.Text.Encoding]::UTF8)
    Write-Host " - Report saved to $reportPath"
}

# --- Path and Config Setup ---
$baseDir = $PWD.Path
$websiteListPath = Join-Path $baseDir website.txt
$outputDir = Join-Path $baseDir output
$configPath = Join-Path $baseDir config.json

# --- Secure API Key Validation ---
if (-not (Test-Path $configPath)) {
    Write-Error Configuration file not found $configPath
    exit 1
}
$config = Get-Content -Path $configPath | ConvertFrom-Json
if (-not $config.OpenAI_API_Key -or [string]::IsNullOrWhiteSpace($config.OpenAI_API_Key) -or $config.OpenAI_API_Key -eq "YOUR_API_KEY_HERE") {
    Write-Error "OpenAI API key is not configured in config.json. Please add your key."
    exit 1
}
$apiKey = $config.OpenAI_API_Key
# Clear the config object from memory
$config = $null

# --- Directory Management ---
$timestamp = Get-Date -Format yyyy-MM-dd
$todayDir = Join-Path $outputDir $timestamp
if (-not (Test-Path $todayDir)) {
    New-Item -ItemType Directory -Path $todayDir | Out-Null
}

# Find the previous crawl directory for comparison
$previousDir = Get-ChildItem -Path $outputDir -Directory | Sort-Object Name | Select-Object -Last 1
if ($previousDir -and (Get-ChildItem -Path $outputDir -Directory).Count -gt 1) {
    $previousDir = (Get-ChildItem -Path $outputDir -Directory | Sort-Object Name)[-2].FullName
    Write-Host Previous crawl directory found $previousDir
} else {
    $previousDir = $null
    Write-Host No previous crawl directory found. Skipping diff check.
}

# --- Main Processing ---
$urls = Get-Content $websiteListPath
$changedSites = New-Object 'System.Collections.Generic.List[object]'

foreach ($url in $urls) {
    $crawlResult = Get-SiteContent -url $url -directory $todayDir
    if (-not $crawlResult.Success) {
        Start-Sleep -Seconds 3
        continue
    }

    if ($previousDir) {
        $previousFilePath = Join-Path $previousDir "$($crawlResult.Hostname).html"
        $diff = Compare-SiteContent -oldPath $previousFilePath -newPath $crawlResult.FilePath

        if ($diff -and $diff.Count -gt 0) {
            Write-Host " - Differences found!"
            $change = [PSCustomObject]@{
                Url        = $url
                Diff       = $diff
                NewContent = $crawlResult.Content
            }
            $changedSites.Add($change)
        }
    }
    Start-Sleep -Seconds 3
}

# --- Summarization and Reporting ---
if ($changedSites.Count -gt 0) {
    Write-Host "`n--- Found $($changedSites.Count) sites with changes. Summarizing with OpenAI... ---"

    foreach ($site in $changedSites) {
        $summary = Summarize-Changes -siteChange $site -apiKey $apiKey
        $site | Add-Member -MemberType NoteProperty -Name Summary -Value $summary
    }
    
    # Clear API key from memory after all API calls
    $apiKey = $null

    $reportPath = Join-Path $baseDir "report-$timestamp.html"
    Generate-Report -changedSites $changedSites -reportPath $reportPath

    if ($IsWindows) {
        Invoke-Item $reportPath
    } else {
        Write-Host "To view the report, open this file in your browser: $reportPath"
    }
}

Write-Host "Script finished."
