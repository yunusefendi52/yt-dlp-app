param (
    [System.IO.DirectoryInfo] $Source
)

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
elseif ($IsMacOS) {
    $YtDlUrl = "https://github.com/yt-dlp/yt-dlp/releases/download/2021.12.27/yt-dlp_macos"
}
elseif ($IsLinux) {
    $YtDlUrl = "https://github.com/yt-dlp/yt-dlp/releases/download/2021.12.27/yt-dlp"
}

if ($IsWindows) {
    $YtDlFileName = "yt-dlp.exe"
}
else {
    $YtDlFileName = "yt-dlp"
}
$YtDl = Join-Path "temp" $YtDlFileName
if (!(Test-Path $YtDl)) {
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($YtDl))
    Write-Host "Downloading youtube-dlp" -ForegroundColor Blue
    Invoke-WebRequest $YtDlUrl -OutFile $YtDl
    Write-Host "Done downloading youtube-dlp" -ForegroundColor Green
    Write-Host ""
    if (!$IsWindows) {
        chmod a+rx $YtDl
    }
}

$SourceFolder = if ($Source) {
    if (Test-Path $Source) {
        [System.IO.Directory]::CreateDirectory($Source)
    }
    $Source
} else {
    "list"
}
$YtIndex = Get-ChildItem $SourceFolder -Recurse | Where-Object { $_.Name -eq "ytindex.txt" }
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