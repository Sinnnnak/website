# Publishes this folder to here.now. Run in PowerShell:  powershell -ExecutionPolicy Bypass -File publish.ps1
# Optional: $env:HERENOW_API_KEY = "..." first for a permanent site on your account.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$h = @{ 'X-HereNow-Client' = 'claude-design/publish-ps1' }
if ($env:HERENOW_API_KEY) { $h['Authorization'] = "Bearer $env:HERENOW_API_KEY" }
$files = @(
  @{ path = 'index.html'; size = (Get-Item 'index.html').Length; contentType = 'text/html; charset=utf-8' },
  @{ path = 'uploads/Mohamed-Elmojtaba-CV.pdf'; size = (Get-Item 'uploads/Mohamed-Elmojtaba-CV.pdf').Length; contentType = 'application/pdf' }
)
$body = @{ displayName = 'Mohamed Elmojtaba - Portfolio'; files = $files } | ConvertTo-Json -Depth 5
$r = Invoke-RestMethod -Method Post -Uri 'https://here.now/api/v1/publish' -Headers $h -ContentType 'application/json' -Body $body
foreach ($u in $r.upload.uploads) {
  $ct = ($files | Where-Object { $_.path -eq $u.path }).contentType
  Invoke-WebRequest -Method Put -Uri $u.url -ContentType $ct -InFile $u.path -UseBasicParsing | Out-Null
  Write-Host "uploaded $($u.path)"
}
Invoke-RestMethod -Method Post -Uri $r.upload.finalizeUrl -Headers $h -ContentType 'application/json' -Body (@{ versionId = $r.upload.versionId } | ConvertTo-Json) | Out-Null
$r | ConvertTo-Json -Depth 6 | Set-Content '.herenow-response.json'
Write-Host ""
Write-Host "Live: $($r.siteUrl)"
if ($r.claimUrl) { Write-Host "Claim link (sign in to keep it permanently): $($r.claimUrl)" } else { Write-Host "Saved to your here.now account." }
