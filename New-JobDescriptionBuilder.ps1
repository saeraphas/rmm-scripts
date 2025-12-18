# Import everything (row 1 = headers)
$allRows = Import-Excel "C:\nexigen\descriptions\NOC_Roles_Responsibilities.xlsx"

# Select only rows 3–8 (skip row 2 competencies)
$rows = $allRows | Select-Object -Skip 1

# Get headers in sheet order
$headers = $rows[0].PSObject.Properties.Name

# Define non-cumulative columns
$nonCumulative = @("Job Title", "On-Call", "Competitor Salary", "Experience Summary")

# Initialize accumulator
$cumulative = @{}

# Iterate through each row and build cumulative objects
$result = foreach ($row in $rows) {
    foreach ($header in $headers) {
        $current = $row.$header
        $currTrim = if ($current) { $current.Trim() } else { "" }

        if ($nonCumulative -contains $header) {
            # Non-cumulative: overwrite with current row value
            $cumulative[$header] = $current
        }
        else {
            if ($cumulative.ContainsKey($header)) {
                # Additive: append with a space only if current value is non-empty
                if ($currTrim -ne "") {
                    if ($cumulative[$header] -and $cumulative[$header].Trim() -ne "") {
                        $cumulative[$header] = ($cumulative[$header].Trim() + " " + $currTrim)
                    }
                    else {
                        $cumulative[$header] = $currTrim
                    }
                }
            }
            else {
                # Initialize with trimmed value or empty string
                $cumulative[$header] = $currTrim
            }
        }
    }

    # Rebuild object in the same order as spreadsheet headers
    $ordered = [ordered]@{}
    foreach ($header in $headers) {
        $ordered[$header] = $cumulative[$header]
    }

    [PSCustomObject]$ordered
}

Import-Module PSWriteOffice

# Output the cumulative objects
foreach ($jobDescription in $result) {
    # Ensure filename-safe title (removes slashes or colons)
    $JobTitle = $jobDescription."Job Title" -replace '[\\\/:*?"<>|]', ''
    $jobDescription | Out-File -FilePath "$PSScriptRoot\$JobTitle.txt" 
}