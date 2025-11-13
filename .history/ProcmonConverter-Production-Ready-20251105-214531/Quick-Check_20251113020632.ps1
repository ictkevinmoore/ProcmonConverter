$content = Get-Content ".\Generate-Professional-Report.ps1" -Raw
Write-Host "`nChecking for 'Process Name' headers..." -ForegroundColor Cyan
$matches = [regex]::Matches($content, '<th>Process Name</th>')
Write-Host "Found $($matches.Count) instances of '<th>Process Name</th>'" -ForegroundColor $(if($matches.Count -ge 2){'Green'}else{'Red'})

Write-Host "`nChecking for old 'Process' headers..." -ForegroundColor Cyan
$oldMatches = [regex]::Matches($content, '<th>Process</th>')
Write-Host "Found $($oldMatches.Count) instances of '<th>Process</th>'" -ForegroundColor $(if($oldMatches.Count -eq 0){'Green'}else{'Red'})

if ($matches.Count -ge 2 -and $oldMatches.Count -eq 0) {
    Write-Host "`n✓ SUCCESS - Column standardization complete!" -ForegroundColor Green
} else {
    Write-Host "`n✗ FAILED - Issues found" -ForegroundColor Red
}
