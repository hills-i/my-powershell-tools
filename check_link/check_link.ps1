# 
# This script checks for broken links listed in a specified file.
#
# If a webpage from the first column of the file cannot be reached, 
# the script will display the broken link's destination and its source page on the first line,
# followed by the HTTP status code on the second line.

[CmdletBinding()]
param (
  [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Path to the file containing links to check.")]
  [string]$Path = ".\link.txt"
)

if (-not (Test-Path -Path $Path)) {
  Write-Error "File not found: $Path"
  exit 1
}

Add-Type -AssemblyName System.Net.Http

# Create HttpClient once for reuse across all requests
$script:httpHandler = [System.Net.Http.HttpClientHandler]::new()
$script:httpHandler.AllowAutoRedirect = $false
$script:httpClient = [System.Net.Http.HttpClient]::new($script:httpHandler)
$script:httpClient.Timeout = [TimeSpan]::FromMilliseconds(15000)

function Get-HttpStatus {
    param(
        [Parameter(Mandatory)]
        [string]$Uri
    )

    try {
        $resp = $script:httpClient.GetAsync($Uri).Result
        return [pscustomobject]@{
            Success    = $true
            StatusCode = [int]$resp.StatusCode
            Error      = $null
        }
    }
    catch {
        return [pscustomobject]@{
            Success    = $false
            StatusCode = $null
            Error      = $_.Exception.GetType().Name
        }
    }
}

try {

    foreach ($line in Get-Content $Path) {
        if ($line -and $line -notmatch '^\s*#') {
    
            $uri = $line.Split(',')[0].Trim()
            $result = Get-HttpStatus -Uri $uri
    
            if (-not $result.Success) {
                Write-Host $uri -ForegroundColor Yellow
                Write-Host "Error: $($result.Error)"
                continue
            }
    
            if ($result.StatusCode -ge 300) {
                Write-Host $uri -ForegroundColor Yellow
                Write-Host "Status: $($result.StatusCode)" -ForegroundColor Red
            }
        }
    }
    
} finally {
    # Cleanup HttpClient resources
    if ($script:httpClient) { $script:httpClient.Dispose() }
    if ($script:httpHandler) { $script:httpHandler.Dispose() }
}

Write-Host "Completed!"

