Add-Type -AssemblyName System.Drawing

$sourcePath = "A:\Others\Desktop\icon.png"
if (-not (Test-Path $sourcePath)) {
    $sourcePath = "assets\icons\app_icon.png"
}

Write-Output "Generating all app icons from: $sourcePath"

$srcImage = [System.Drawing.Image]::FromFile($sourcePath)

function Resize-Image {
    param(
        [System.Drawing.Image]$image,
        [int]$width,
        [int]$height,
        [string]$outputPath
    )
    $destRect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
    $destImage = New-Object System.Drawing.Bitmap($width, $height)
    $destImage.SetResolution($image.HorizontalResolution, $image.VerticalResolution)

    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $graphics.DrawImage($image, $destRect, 0, 0, $image.Width, $image.Height, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()

    $dir = [System.IO.Path]::GetDirectoryName($outputPath)
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $destImage.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destImage.Dispose()
    Write-Output "Generated: $outputPath ($width x $height)"
}

function Generate-Canvas-Image {
    param(
        [System.Drawing.Image]$iconImage,
        [int]$canvasWidth,
        [int]$canvasHeight,
        [int]$iconSize,
        [string]$bgColorHex,
        [string]$outputPath
    )
    $destImage = New-Object System.Drawing.Bitmap($canvasWidth, $canvasHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $bgCol = [System.Drawing.ColorTranslator]::FromHtml($bgColorHex)
    $brush = New-Object System.Drawing.SolidBrush($bgCol)
    $graphics.FillRectangle($brush, 0, 0, $canvasWidth, $canvasHeight)
    $brush.Dispose()

    $x = ($canvasWidth - $iconSize) / 2
    $y = ($canvasHeight - $iconSize) / 2
    $graphics.DrawImage($iconImage, $x, $y, $iconSize, $iconSize)
    $graphics.Dispose()

    $dir = [System.IO.Path]::GetDirectoryName($outputPath)
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $destImage.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destImage.Dispose()
    Write-Output "Generated Canvas: $outputPath ($canvasWidth x $canvasHeight, bg=$bgColorHex)"
}

# 1. Android Mipmaps
Resize-Image $srcImage 48 48 "android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
Resize-Image $srcImage 72 72 "android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
Resize-Image $srcImage 96 96 "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
Resize-Image $srcImage 144 144 "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
Resize-Image $srcImage 192 192 "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

# Android TV Banner (320x180 on #1C1613 background)
Generate-Canvas-Image $srcImage 320 180 140 "#1C1613" "android\app\src\main\res\drawable\banner.png"

# 2. Web Icons
Resize-Image $srcImage 32 32 "web\favicon.png"
Resize-Image $srcImage 192 192 "web\icons\Icon-192.png"
Resize-Image $srcImage 512 512 "web\icons\Icon-512.png"
Resize-Image $srcImage 192 192 "web\icons\Icon-maskable-192.png"
Resize-Image $srcImage 512 512 "web\icons\Icon-maskable-512.png"

# 3. LG webOS TV
Resize-Image $srcImage 80 80 "webos\icon.png"
Resize-Image $srcImage 130 130 "webos\largeIcon.png"
# webOS 1080p Splash screen on #1C1613
Generate-Canvas-Image $srcImage 1920 1080 400 "#1C1613" "webos\splash.png"

# 4. macOS Assets
$macSizes = @(16, 32, 64, 128, 256, 512, 1024)
foreach ($s in $macSizes) {
    Resize-Image $srcImage $s $s "macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_$s.png"
}

# 5. Assets in Flutter Project
Resize-Image $srcImage 512 512 "assets\icons\app_icon.png"

$srcImage.Dispose()
Write-Output "All icons successfully generated from $sourcePath"

