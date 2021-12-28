function ExecSafe([scriptblock] $cmd) {
    & $cmd 
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
}

$FfmpegVersion = ffmpeg 2>&1 | Out-String
if (!($FfmpegVersion -match "Copyright")) {
    Write-Error "Ffmpeg is not installed"
    return
}

if ($IsWindows) {
    $YtDlUrl = "https://github.com/yt-dlp/yt-dlp/releases/download/2021.12.27/yt-dlp_min.exe"
}

$YtDl = Join-Path "temp" "yt-dlp.exe"
if (!(Test-Path $YtDl)) {
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($YtDl))
    Write-Host "Downloading youtube-dlp" -ForegroundColor Blue
    Invoke-WebRequest $YtDlUrl -OutFile $YtDl
    Write-Host "Done downloading youtube-dlp" -ForegroundColor Green
    Write-Host ""
}

$YtIndex = Get-ChildItem "list" -Recurse | Where-Object { $_.Name -eq "ytindex.txt" }
foreach ($item in $YtIndex) {
    Get-Content $item | ForEach-Object {
        # Start-Process $YtDl -Wait -PassThru -NoNewWindow -ArgumentList "-f","`"bestvideo[height<=720,ext=mp4]+bestaudio/best[height<=720,ext=m4a]`"","'$_'"
        ExecSafe {
            # & $YtDl -f 'bestvideo[height<=720,ext=mp4]+bestaudio/best[height<=720,ext=m4a]' $_
            $ParentDir = [System.IO.Path]::GetDirectoryName($item.FullName)
            & $YtDl -f b -o "$ParentDir/%(title)s[%(id)s].%(ext)s" $_
        }
    }
}