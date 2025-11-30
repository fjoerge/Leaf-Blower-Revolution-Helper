# >>> Pfad anpassen <<<
$BasePath = "D:\Dokumente\AHK\LBR Automation\Version 4.1\gemMasks"

# ------------------------------------------------------------
# Export-MaskPng: nutzt Mask[x,y] und erzeugt ein PNG
# ------------------------------------------------------------
function Export-MaskPng {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool[,]] $Mask,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [int] $PixelSize = 1,

        [System.Drawing.Color] $OnColor  = [System.Drawing.Color]::White,
        [System.Drawing.Color] $OffColor = [System.Drawing.Color]::Black
    )

    Add-Type -AssemblyName System.Drawing

    if ($Mask.Rank -ne 2) {
        throw "Mask hat Rank $($Mask.Rank), erwartet ist 2 (bool[,])."
    }

    # Interpretation: erste Dimension = X, zweite = Y
    $width  = [int]$Mask.GetLength(0)   # X
    $height = [int]$Mask.GetLength(1)   # Y

    $bmpWidth  = [int]($width  * $PixelSize)
    $bmpHeight = [int]($height * $PixelSize)

    $bitmap   = [System.Drawing.Bitmap]::new($bmpWidth, $bmpHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    $graphics.Clear($OffColor)

    $brushOn = [System.Drawing.SolidBrush]::new($OnColor)

    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {

            if ($Mask[$x, $y]) {
                $px = [int]($x * $PixelSize)
                $py = [int]($y * $PixelSize)

                $rect = [System.Drawing.Rectangle]::new(
                    $px,
                    $py,
                    [int]$PixelSize,
                    [int]$PixelSize
                )

                $graphics.FillRectangle($brushOn, $rect)
            }
        }
    }

    $dir = [System.IO.Path]::GetDirectoryName($Path)
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }

    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)

    $brushOn.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

# Sicherstellen, dass der Zielordner existiert
if (-not (Test-Path $BasePath)) {
    New-Item -ItemType Directory -Path $BasePath | Out-Null
}

# ------------------------------------------------------------
# Helper: Skripttext in GemMask_[N].ps1 schreiben und PNG erzeugen
# ------------------------------------------------------------
function New-GemMaskFile {
    param(
        [int]$Number,
        [string]$ScriptText
    )

    $ps1Path = Join-Path $BasePath ("GemMask_{0}.ps1" -f $Number)
    $pngPath = Join-Path $BasePath ("GemMask_{0}.png" -f $Number)

    # PS1-Datei erzeugen
    $ScriptText | Set-Content -Path $ps1Path -Encoding UTF8

    # Skript einlesen, Maske ins $script:GemValueMasks laden
    . $ps1Path

    # PNG rendern
    $mask = $script:GemValueMasks["$Number"]
    Export-MaskPng -Mask $mask -Path $pngPath -PixelSize 20
}

# ------------------------------------------------------------
# Masken-Definitionen (robust, 16x16, Mask[x,y])
# ------------------------------------------------------------

# 1
$mask1Script = @'
$mask1 = New-Object 'bool[,]' 16, 16

# Vertikaler Strich in der Mitte
for ($y = 2; $y -le 13; $y++) {
    $mask1[7, $y] = $true
    $mask1[8, $y] = $true
}

# Kleiner Querbalken oben
for ($x = 6; $x -le 9; $x++) {
    $mask1[$x, 2] = $true
}

$script:GemValueMasks["1"] = $mask1
'@

# 2 (ohne diagPoints / +1)
$mask2Script = @'
$mask2 = New-Object 'bool[,]' 16, 16

# Oberer Balken
for ($x = 4; $x -le 11; $x++) {
    $mask2[$x, 2] = $true
    $mask2[$x, 3] = $true
}

# Rechte Vertikale oben
for ($y = 4; $y -le 6; $y++) {
    $mask2[10, $y] = $true
    $mask2[11, $y] = $true
}

# Diagonale nach links unten (explizite Punkte)
$mask2[10,7] = $true; $mask2[9,7]  = $true
$mask2[9,8]  = $true; $mask2[8,8]  = $true
$mask2[8,9]  = $true; $mask2[7,9]  = $true
$mask2[7,10] = $true; $mask2[6,10] = $true

# Unterer Balken
for ($x = 4; $x -le 11; $x++) {
    $mask2[$x, 11] = $true
    $mask2[$x, 12] = $true
}

$script:GemValueMasks["2"] = $mask2
'@

# 3
$mask3Script = @'
$mask3 = New-Object 'bool[,]' 16, 16

# Oberer Balken
for ($x = 4; $x -le 11; $x++) {
    $mask3[$x, 2] = $true
    $mask3[$x, 3] = $true
}

# Mittlerer Balken
for ($x = 5; $x -le 11; $x++) {
    $mask3[$x, 7] = $true
    $mask3[$x, 8] = $true
}

# Unterer Balken
for ($x = 4; $x -le 11; $x++) {
    $mask3[$x, 12] = $true
    $mask3[$x, 13] = $true
}

# Rechte Vertikale
for ($y = 4; $y -le 11; $y++) {
    $mask3[11, $y] = $true
    $mask3[10, $y] = $true
}

$script:GemValueMasks["3"] = $mask3
'@

# 4
$mask4Script = @'
$mask4 = New-Object 'bool[,]' 16, 16

# Linke Stütze
for ($y = 4; $y -le 11; $y++) {
    $mask4[4, $y] = $true
    $mask4[5, $y] = $true
}

# Querbalken in der Mitte
for ($x = 4; $x -le 11; $x++) {
    $mask4[$x, 7] = $true
    $mask4[$x, 8] = $true
}

# Rechte Hauptsäule
for ($y = 2; $y -le 13; $y++) {
    $mask4[11, $y] = $true
    $mask4[10, $y] = $true
}

$script:GemValueMasks["4"] = $mask4
'@

# ------------------------------------------------------------
# Dateien + PNGs erzeugen
# ------------------------------------------------------------
#New-GemMaskFile -Number 1 -ScriptText $mask1Script -pixelsize 1
#New-GemMaskFile -Number 2 -ScriptText $mask2Script -pixelsize 1
#New-GemMaskFile -Number 3 -ScriptText $mask3Script -pixelsize 1
#New-GemMaskFile -Number 4 -ScriptText $mask4Script -pixelsize 1

Write-Host "GemMask_1..4.ps1 und GemMask_1..4.png wurden in $BasePath erzeugt."

Export-MaskPng -Mask .\GemMask_1.ps1 -PixelSize 1