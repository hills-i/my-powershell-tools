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

foreach($line in Get-Content -Path $Path) {
  if ($line -and $line -notmatch '^\s*#') {
    $arr = $line.split(",")
    $uri = $arr[0].Trim()
    
    try {
      $response = Invoke-WebRequest -Uri $uri -MaximumRedirection 1 -ErrorAction Stop
    } catch [System.Net.WebException] {
      Write-Host $line -ForegroundColor Yellow
      if ($_.Exception.Response) {
        # HTTP Status Code
        $statusCode = [int]$_.Exception.Response.StatusCode
        Write-Host "Status: $statusCode" -BackgroundColor Red
      } else {
        Write-Warning "A network error occurred: $($_.Exception.Message)"
      }
    } catch {
        Write-Host $line -ForegroundColor Yellow
        Write-Warning "An unexpected error occurred: $($_.Exception.Message)"
    }
  }
}

Write-Host "Completed!"