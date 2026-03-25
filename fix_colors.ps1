$files = @(
    'lib\screens\service_request_screen.dart',
    'lib\screens\bookings_screen.dart'
)

foreach ($f in $files) {
    if (Test-Path $f) {
        $content = Get-Content $f -Raw
        # Fix "const AppTheme.xxx" -> "AppTheme.xxx" (const is invalid with static fields)
        $content = $content -replace 'const AppTheme\.', 'AppTheme.'
        Set-Content $f $content -NoNewline
        Write-Host "Fixed const prefix in: $f"
    }
}
