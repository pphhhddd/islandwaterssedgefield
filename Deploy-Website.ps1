# Deploy-Website.ps1

# 1. Set the working directory to the script's location
Set-Location -Path $PSScriptRoot

# 2. Prevent the script from uploading itself by adding it to .gitignore
$scriptName = $MyInvocation.MyCommand.Name
$gitignorePath = Join-Path -Path $PSScriptRoot -ChildPath ".gitignore"

if (-not (Test-Path $gitignorePath)) {
    New-Item -Path $gitignorePath -ItemType File | Out-Null
}

$gitignoreContent = Get-Content $gitignorePath -Raw
if ($gitignoreContent -notmatch $scriptName) {
    Add-Content -Path $gitignorePath -Value "`n$scriptName"
    Write-Host "Added $scriptName to .gitignore" -ForegroundColor Yellow
}

# --- NEW: Inject Timestamp into index.html ---
$indexPath = Join-Path -Path $PSScriptRoot -ChildPath "index.html"
if (Test-Path $indexPath) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $updateComment = "<!-- Last Updated: $timestamp -->"
    
    $htmlContent = Get-Content $indexPath -Raw
    
    # Check if the comment already exists; if yes, replace it. If no, inject it after DOCTYPE.
    if ($htmlContent -match "<!-- Last Updated: .*? -->") {
        $htmlContent = $htmlContent -replace "<!-- Last Updated: .*? -->", $updateComment
    } else {
        $htmlContent = $htmlContent -replace "(?i)(<!DOCTYPE html>)", "`$1`n$updateComment"
    }
    
    Set-Content -Path $indexPath -Value $htmlContent
    Write-Host "Injected timestamp into index.html: $timestamp" -ForegroundColor Magenta
}
# ---------------------------------------------

# 3. Stage all new and modified files
Write-Host "Staging website files..." -ForegroundColor Cyan
git add .

# 4. Check if there are actually any changes to upload
$status = git status --porcelain
if ($status) {
    # Generate an auto-commit message with the current timestamp
    $commitTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Found changes. Committing as 'Auto-update: $commitTimestamp'..." -ForegroundColor Cyan
    git commit -m "Auto-update: $commitTimestamp" | Out-Null
    
    # Push to GitHub
    Write-Host "Pushing files to GitHub Pages..." -ForegroundColor Cyan
    git push origin main
    
    Write-Host "`nDeploy successful! The website will update in about 60 seconds." -ForegroundColor Green
} else {
    Write-Host "`nNo new changes detected. Everything is already up to date." -ForegroundColor Yellow
}

# Keep the window open so you can see the result
Write-Host "`n"
Read-Host -Prompt "Press Enter to close"