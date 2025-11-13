$sourcePath = "C:\Users\ictke\OneDrive\Desktop\November Script Back-up\ProcmonConverter-Production-Ready-20251105-214531\StreamingCSVProcessor.ps1"
$destPath = "C:\Users\ictke\OneDrive\Desktop\ProcmonConverter\StreamingCSVProcessor.ps1"

Write-Host "Copying from: $sourcePath"
Write-Host "Copying to: $destPath"

if (Test-Path $sourcePath) {
    Copy-Item -Path $sourcePath -Destination $destPath -Force
    Write-Host "Copy completed successfully"

    if (Test-Path $destPath) {
        $fileInfo = Get-Item $destPath
        Write-Host "Destination file size: $($fileInfo.Length) bytes"
    }
}
else {
    Write-Host "Source file not found!"
}

