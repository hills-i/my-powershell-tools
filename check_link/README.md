# Check Link

A PowerShell script to check for broken links from a given list of URLs.

## Description

This script reads a list of URLs from a text file. For each URL, it sends a web request to check if it's reachable. If a link is broken (e.g., 404 Not Found, or a network error occurs), it prints the details of the broken link and the HTTP status code or error message to the console.

## Prerequisites

- PowerShell 5.1 or later.

## Usage

1.  Clone this repository or download the files.
2.  Create a `link.txt` file in the same directory (or use your own file path).
3.  Populate `link.txt` with the links you want to check. See `link.txt.example` for the format.
4.  Run the script from a PowerShell terminal:

```powershell
# Check links from the default link.txt file
.\check_link.ps1

# Check links from a custom file
.\check_link.ps1 -Path .\path\to\your\links.txt
```

### Input File Format

The input file (`link.txt` by default) should contain one entry per line. Each line should have the URL to check, followed by a comma and a description of where the link is from.

**Example:**
```
https://www.github.com/nonexistent,GitHub Homepage
# This is a comment and will be ignored
http://example.com/broken-page,Example Website
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
