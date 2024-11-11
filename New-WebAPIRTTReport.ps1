# define variables for file system paths
$ReportName = "Web-API-RTT"
$CustomerName = "HCI"

$DateString = ((get-date).tostring("yyyy-MM-dd"))
$DesktopPath = [Environment]::GetFolderPath("Desktop")
# $CustomerPath = "$DesktopPath\$ReportName\$DateString"
# $ReportPath = "$CustomerPath\Reports"
$ReportPath = "C:\Nexigen\Reports"
if (!(Test-Path $ReportPath)) { New-Item -ItemType Directory -Path $ReportPath -Force }

$CSVreport = "$ReportPath\$CustomerName-$ReportName-report-$DateString.csv"
# $PSNewLine = [System.Environment]::Newline

# define polling parameters
$PollIntervalSeconds = 5
$PollDurationMinutes = 5
$PollCount = ($PollDurationMinutes * 60) / $PollIntervalSeconds

# define variables for Web API
$phoneNumber = "9999999999"
$WebAPIUsername = "five9"
$WebAPIPassword = 'o4HBt#4^Zzvu$Ld#gJvK7Krk'
$auth = $WebAPIUsername + ':' + $WebAPIPassword
$Encoded = [System.Text.Encoding]::UTF8.GetBytes($auth)
$authorizationInfo = "Basic $([System.Convert]::ToBase64String($Encoded))"
 
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("X-UAPI-HOMECITYICE", "81n0778X214eI1vlZab1fb5y1GMvjwxMkn2r9q5V")
$headers.Add("Authorization", $authorizationInfo)


function pollAPI() {
    $responseTime = (Measure-Command -Expression { $response = Invoke-RestMethod "https://uapi.homecityice.com/upgw/calls/routing?customerphoneNumber=$phoneNumber" -Method 'GET' -Headers $headers }).Milliseconds
    $responseStatus = $response.status
    
    # build result object
    [PSCustomObject]@{
        'Request Time'       = [datetime]::Now.ToString("yyyyMMddHHmmss")
        'Response Code'      = $responseStatus
        'Response Time (ms)' = $responseTime
    }
}

# start polling
$Count = 0
$Report = While ($Count -lt $PollCount) { pollAPI; Start-Sleep $PollIntervalSeconds; $Count++ }

# output report to CSV
$Report | Export-Csv -NTI -Path $CSVreport -Append

# store metrics as variables for RMM reporting
$Results = $Report | Measure-Object -Property "Response Time (ms)" -Minimum -Maximum -Average 
$Best = $Results.Minimum 
$Worst = $Results.Maximum
$Average = $([math]::Round($Results.Average))
# Write-Output "Best:    " $Best
# Write-Output "Worst:   " $Worst
# Write-Output "Average: " $Average
# Write-Output "Finished."