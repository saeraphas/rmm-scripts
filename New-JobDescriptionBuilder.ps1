# 1. Setup and Import
Import-Module ImportExcel
# Import everything (Excel Row 1 = headers)
$allRows = Import-Excel "C:\nexigen\descriptions\NOC_Roles_Responsibilities.xlsx"

# Excel Row 2 (Index 0 in $allRows) contains the Competencies/Skills
$competenciesRow = $allRows[0]

# Select only rows 3 and below (the actual job tiers)
$rows = $allRows | Select-Object -Skip 1

# Get headers in sheet order
$headers = $rows[0].PSObject.Properties.Name

# Define non-cumulative columns (Displayed in Header/Footer)
$nonCumulative = @("Job Title", "On-Call", "Competitor Salary", "Experience Summary")

# NEW: Define columns that should be ignored entirely in the output
$hiddenColumns = @("Access")

# Initialize accumulator
$cumulative = @{}

# 2. Process Data: Build Cumulative Objects
$result = foreach ($row in $rows) {
    foreach ($header in $headers) {
        $current = $row.$header
        $currTrim = if ($current) { $current.Trim() } else { "" }
        
        # Get the competency for this specific column from Row 2
        $compValue = if ($competenciesRow.$header) { $competenciesRow.$header.Trim() } else { "" }

        if ($nonCumulative -contains $header) {
            # Non-cumulative: overwrite with current row value (e.g., Job Title)
            $cumulative[$header] = $current
        }
        else {
            if ($currTrim -ne "") {
                if ($cumulative.ContainsKey($header) -and $cumulative[$header] -and $cumulative[$header].Trim() -ne "") {
                    # NEWEST FIRST: Prepend the new tier responsibilities to the existing string
                    $cumulative[$header] = ($currTrim + " " + $cumulative[$header].Trim())
                }
                else {
                    # INITIALIZE: First time this category has content
                    $cumulative[$header] = $currTrim
                    
                    # APPEND COMPETENCIES: Join with a NEWLINE if Row 2 isn't empty
                    if ($compValue -ne "") {
                        $cumulative[$header] = $cumulative[$header] + "`nCompetencies: " + $compValue
                    }
                }
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

# 3. Visual Confirmation
$result | Out-GridView

# 4. Formatted File Output
foreach ($jobDescription in $result) {
    # Ensure filename-safe title
    $safeTitle = $jobDescription."Job Title" -replace '[\\\/:*?"<>|]', ''
    $filePath = "$PSScriptRoot\$safeTitle.txt"

    # Build the text file content
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("=================================================================")
    [void]$sb.AppendLine(" JOB DESCRIPTION: $($jobDescription.'Job Title')")
    [void]$sb.AppendLine("=================================================================")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("EXPERIENCE SUMMARY:")
    [void]$sb.AppendLine($jobDescription."Experience Summary")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("CORE RESPONSIBILITIES:")
    [void]$sb.AppendLine("----------------------")

    # Add Responsibility sections
    foreach ($header in $headers) {
        # Check if the column is NOT in the metadata list AND NOT in the hidden list
        if ($nonCumulative -notcontains $header -and $hiddenColumns -notcontains $header) {
            $value = $jobDescription.$header
            if ($value -and $value.Trim() -ne "") {
                [void]$sb.AppendLine("[$header]")
                [void]$sb.AppendLine($value)
                [void]$sb.AppendLine("") # Extra space for readability
            }
        }
    }

    [void]$sb.AppendLine("----------------------")
    [void]$sb.AppendLine("ON-CALL REQUIREMENT: $($jobDescription.'On-Call')")
    [void]$sb.AppendLine("COMPETITIVE SALARY REF: $($jobDescription.'Competitor Salary')")
    [void]$sb.AppendLine("=================================================================")

    # Write to file
    $sb.ToString() | Out-File -FilePath $filePath -Encoding utf8
}

Write-Host "Success: Job descriptions generated in $PSScriptRoot" -ForegroundColor Green