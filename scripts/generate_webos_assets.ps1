Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path 'webos' | Out-Null

$srcPath = 'web\icons\Icon-512.png'
$srcImg = [System.Drawing.Image]::FromFile((Resolve-Path $srcPath))

function Resize-Image($img, $w, $h, $outPath) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, 0, 0, $w, $h)
    $g.Dispose()
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Generated $outPath"
}

Resize-Image $srcImg 80 80 'webos\icon.png'
Resize-Image $srcImg 130 130 'webos\largeIcon.png'

# Generate 1920x1080 Splash Screen
$splashBmp = New-Object System.Drawing.Bitmap(1920, 1080)
$sg = [System.Drawing.Graphics]::FromImage($splashBmp)
$sg.Clear([System.Drawing.Color]::FromArgb(255, 11, 15, 25))
$sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$sg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

# Center the 256x256 logo on splash
$logoSize = 256
$posX = [int]((1920 - $logoSize) / 2)
$posY = [int]((1080 - $logoSize) / 2 - 40)
$sg.DrawImage($srcImg, $posX, $posY, $logoSize, $logoSize)
$sg.Dispose()
$splashBmp.Save('webos\splash.png', [System.Drawing.Imaging.ImageFormat]::Png)
$splashBmp.Dispose()
Write-Output "Generated webos\splash.png"

$srcImg.Dispose()

