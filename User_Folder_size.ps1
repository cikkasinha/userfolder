<#Title: User Folder Report Generation Script
Author: Chandrakant Sinha

Synopsis:
"User Folder Report Generation Script" by Chandrakant Sinha is a PowerShell utility designed to automate the creation of user folder size reports on designated servers. The script captures server information from a provided text file and compiles a detailed HTML report with folder names and sizes. The report's visual appeal is enhanced through CSS styling, and conditional formatting draws attention to folders exceeding predefined size thresholds. This efficient script empowers IT administrators to monitor disk space utilization across servers systematically, ensuring proactive management and resource optimization.
#>


# Get the current date and time in "DD\MM\YYYY HH:MM" format
$currentDateTime = Get-Date -Format "dd\\MM\\yyyy HH:mm"
# Get the current date and time in "DD_MM_YY_HH_MM" format
$outputFileName = "User_Folder_Report_$(Get-Date -Format 'dd_MM_yy_HH_mm').html"

# Get the list of server names from a text file
$servers = Get-Content "C:\servers.txt"

# Initialize an array to store the server information
$serverInfo = @()

# Loop through each server
foreach ($server in $servers) {
    $userFolders = Get-ChildItem -Path "\\$server\c$\users" | Where-Object { $_.PSIsContainer }

    $userInfo = foreach ($folder in $userFolders) {
        $folderSizeMB = (Get-ChildItem -Recurse -Force -ErrorAction SilentlyContinue -Path $folder.FullName | Measure-Object -Property Length -Sum).Sum / 1MB

        [PSCustomObject]@{
            ServerName = $server
            FolderName = $folder.Name
            Size       = $folderSizeMB
        }
    }

    $serverInfo += $userInfo
}

# Generate the HTML report
$htmlReport = @"
<html>
<head>
<style>
    table {
        border-collapse: collapse;
    }
    th, td {
        border: 1px solid black;
        padding: 8px;
        text-align: center;
    }
    th {
        background-color: lightgray;
    }
    .yellow {
        background-color: yellow;
    }
    .red {
        background-color: red;
    }
    .report-header {
        font-size: 18px;
        font-weight: bold;
        text-align: center;
        margin-bottom: 20px;
    }
</style>
</head>
<body>
<div class="report-header">User Folder Report - $currentDateTime</div>
<table>
<tr>
    <th>Server Name</th>
    <th>User Folder</th>
    <th>Size (MB)</th>
</tr>
"@

foreach ($user in $serverInfo) {
    $sizeClass = if ($user.Size -gt 10000) { "red" } elseif ($user.Size -gt 1000) { "yellow" } else { "" }
    $sizeFormatted = "{0:N2}" -f $user.Size

    $htmlReport += @"
<tr>
    <td>$($user.ServerName)</td>
    <td>$($user.FolderName)</td>
    <td class="$sizeClass">$sizeFormatted MB</td>
</tr>
"@
}

$htmlReport += @"
</table>
</body>
</html>
"@

# Save the HTML report to a file
$htmlReport | Out-File "C:\output user folder\$outputFileName"
