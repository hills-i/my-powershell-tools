# My PowerShell Tools

This repository contains a collection of PowerShell scripts for various tasks.

## Tools

### Check Link

This script checks for broken links listed in the `link.txt` file.

If a webpage from the first column of the file cannot be reached, the script will display the broken link's destination and its source page on the first line, followed by the HTTP status code on the second line.

### VPN Check

This script changes the desktop wallpaper based on whether a VPN connection is active. It checks for a specific network route that is present when connected to the VPN.

### Web Watcher

This script monitors a list of websites for changes. It fetches the content of each website, compares it to the previous version, and generates an HTML report summarizing the differences. It uses the OpenAI API to generate a summary of the changes in Japanese.

## License

MIT License
