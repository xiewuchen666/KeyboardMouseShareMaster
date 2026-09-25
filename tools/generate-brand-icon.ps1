$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "src\apps\res"
$pngPath = Join-Path $outDir "keymouse-share-master.png"
$icoPath = Join-Path $outDir "deskflow.ico"

function New-RoundedPath {
  param([float]$X,[float]$Y,[float]$W,[float]$H,[float]$R)
  $p = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $R * 2
  $p.AddArc($X,$Y,$d,$d,180,90)
  $p.AddArc($X+$W-$d,$Y,$d,$d,270,90)
  $p.AddArc($X+$W-$d,$Y+$H-$d,$d,$d,0,90)
  $p.AddArc($X,$Y+$H-$d,$d,$d,90,90)
  $p.CloseFigure()
  return $p
}

$bmp = [System.Drawing.Bitmap]::new(512,512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::Transparent)

$bg = New-RoundedPath 18 18 476 476 104
$grad = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
  [System.Drawing.PointF]::new(25,25),
  [System.Drawing.PointF]::new(487,487),
  [System.Drawing.Color]::FromArgb(255,7,103,255),
  [System.Drawing.Color]::FromArgb(255,18,199,232)
)
$g.FillPath($grad,$bg)

$dark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,15,48,87))
$blue = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,29,169,255))
$cyan = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,55,199,242))
$white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,246,252,255))
$key = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,181,218,243))
$wheel = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,52,116,201))
$outline = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(245,238,249,255),8)
$thin = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255,211,238,255),6)
$arrow = [System.Drawing.Pen]::new([System.Drawing.Color]::White,14)
$arrow.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$arrow.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

$monitor = New-RoundedPath 62 108 196 128 12
$monitorInner = New-RoundedPath 78 124 164 96 6
$g.FillPath($dark,$monitor)
$g.DrawPath($outline,$monitor)
$g.FillPath($blue,$monitorInner)
$stand = [System.Drawing.PointF[]]@(
  [System.Drawing.PointF]::new(124,252),
  [System.Drawing.PointF]::new(198,252),
  [System.Drawing.PointF]::new(210,280),
  [System.Drawing.PointF]::new(112,280)
)
$g.FillPolygon($white,$stand)

$laptop = New-RoundedPath 278 138 166 110 12
$laptopInner = New-RoundedPath 294 154 134 78 6
$g.FillPath($dark,$laptop)
$g.DrawPath($outline,$laptop)
$g.FillPath($cyan,$laptopInner)
$base = [System.Drawing.PointF[]]@(
  [System.Drawing.PointF]::new(264,248),
  [System.Drawing.PointF]::new(454,248),
  [System.Drawing.PointF]::new(434,272),
  [System.Drawing.PointF]::new(282,272)
)
$g.FillPolygon($white,$base)

$g.DrawBezier($arrow,205,176,238,140,282,142,316,168)
$g.DrawLine($arrow,205,176,228,172)
$g.DrawLine($arrow,205,176,215,154)
$g.DrawLine($arrow,316,168,292,171)
$g.DrawLine($arrow,316,168,306,190)

$kbd = New-RoundedPath 92 318 264 84 18
$g.FillPath($white,$kbd)
$g.DrawPath($thin,$kbd)
for($row=0;$row -lt 2;$row++){
  for($col=0;$col -lt 6;$col++){
    $x=112+$col*34
    $y=338+$row*28
    $w=26
    if($row -eq 1 -and $col -eq 5){$w=42}
    $kp=New-RoundedPath $x $y $w 18 4
    $g.FillPath($key,$kp)
    $kp.Dispose()
  }
}

$mouse = New-RoundedPath 372 310 78 108 39
$g.FillPath($white,$mouse)
$g.DrawPath($thin,$mouse)
$wheelPath = New-RoundedPath 405 328 10 30 5
$g.FillPath($wheel,$wheelPath)

$bmp.Save($pngPath,[System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
foreach($d in @($bg,$grad,$dark,$blue,$cyan,$white,$key,$wheel,$outline,$thin,$arrow,$monitor,$monitorInner,$laptop,$laptopInner,$kbd,$mouse,$wheelPath)){ if($null -ne $d){$d.Dispose()} }

# Create a Windows ICO that embeds a PNG-compressed 256x256 frame.
$source = [System.Drawing.Image]::FromFile($pngPath)
$small = [System.Drawing.Bitmap]::new(256,256)
$sg = [System.Drawing.Graphics]::FromImage($small)
$sg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$sg.DrawImage($source,0,0,256,256)
$tmp = Join-Path $env:TEMP "keymouse-share-master-256.png"
$small.Save($tmp,[System.Drawing.Imaging.ImageFormat]::Png)
$sg.Dispose()
$small.Dispose()
$source.Dispose()

$bytes = [System.IO.File]::ReadAllBytes($tmp)
$stream = [System.IO.File]::Open($icoPath,[System.IO.FileMode]::Create)
$writer = [System.IO.BinaryWriter]::new($stream)
$writer.Write([UInt16]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]1)
$writer.Write([byte]0)
$writer.Write([byte]0)
$writer.Write([byte]0)
$writer.Write([byte]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]32)
$writer.Write([UInt32]$bytes.Length)
$writer.Write([UInt32]22)
$writer.Write($bytes)
$writer.Dispose()
$stream.Dispose()
Remove-Item $tmp -Force

if((Get-Item $icoPath).Length -lt 10000){ throw "Generated ICO is unexpectedly small." }
Write-Output "Generated:"
Get-Item $pngPath,$icoPath | Select-Object FullName,Length,LastWriteTime
