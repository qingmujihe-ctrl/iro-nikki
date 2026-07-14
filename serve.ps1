# iro-nikki local server
# Camera (getUserMedia) only works on localhost/https, not file://.
# Usage: run  ./serve.ps1  in PowerShell, then open http://localhost:8136

$port = 8136
$root = $PSScriptRoot
$prefix = "http://localhost:$port/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
} catch {
    Write-Host "Could not open port $port : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  iro-nikki (color diary) is running" -ForegroundColor Cyan
Write-Host "  Open in browser:  $prefix" -ForegroundColor Green
Write-Host "  Stop: Ctrl + C"
Write-Host ""

Start-Process $prefix

$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $req = $context.Request
        $res = $context.Response

        $rel = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart("/"))
        if ([string]::IsNullOrWhiteSpace($rel)) { $rel = "index.html" }
        $path = Join-Path $root $rel

        if (Test-Path $path -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($path)
            $ext = [System.IO.Path]::GetExtension($path).ToLower()
            if ($mime.ContainsKey($ext)) { $res.ContentType = $mime[$ext] }
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $res.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $rel")
            $res.OutputStream.Write($msg, 0, $msg.Length)
        }
        $res.OutputStream.Close()
    } catch {
        # ignore client disconnects and keep serving
    }
}
