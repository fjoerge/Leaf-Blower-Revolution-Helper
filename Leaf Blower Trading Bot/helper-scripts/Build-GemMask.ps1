function build-Mask {
param(
    [string]$FolderPath,          # Ordner mit den Beispielbildern (alle gleich groß)
    [string]$Digit      = "1",    # "1","2","3" ...
    [string]$OutPath    = ".\GemMask_$Digit.ps1",
    [double]$Majority   = 1     # 40% der Bilder müssen hell sein
)

Add-Type -AssemblyName System.Drawing

# Bilddateien sammeln
$files = Get-ChildItem -Path $FolderPath -File |
         Where-Object { $_.Extension -in '.png', '.jpg', '.jpeg' }

if ($files.Count -eq 0) {
    Write-Error "Keine Bilddateien in '$FolderPath' gefunden."
    exit 1
}

# Größe aus erstem Bild
$firstBmp = [System.Drawing.Bitmap]::FromFile($files[0].FullName)
$w = $firstBmp.Width
$h = $firstBmp.Height
$firstBmp.Dispose()

Write-Host "Erzeuge Maske für Ziffer $Digit aus $($files.Count) Bildern, Größe ${w}x$h ..."

$hitCounts = New-Object 'int[,]' $w, $h

foreach ($f in $files) {
    $bmp = [System.Drawing.Bitmap]::FromFile($f.FullName)

    if ($bmp.Width -ne $w -or $bmp.Height -ne $h) {
        Write-Warning "Bild '$($f.Name)' hat andere Größe ($($bmp.Width)x$($bmp.Height)) – übersprungen."
        $bmp.Dispose()
        continue
    }

    for ($x = 0; $x -lt $w; $x++) {
        for ($y = 0; $y -lt $h; $y++) {
            $c = $bmp.GetPixel($x, $y)

            # exakt derselbe Bright-Check wie in Get-GemValue
            $isBright = ($c.R -ge 200 -and $c.G -ge 200 -and $c.B -ge 160)
            if ($isBright) {
                $hitCounts[$x,$y]++
            }
        }
    }

    $bmp.Dispose()
}

$imgCount = $files.Count
$minHits  = [math]::Ceiling($imgCount * $Majority)

Write-Host "Pixel wird 'true', wenn er in mindestens $minHits von $imgCount Bildern hell ist."

$sb = New-Object System.Text.StringBuilder

# Richtiger Maskenname je nach Digit, z.B. $mask1, $mask2, $mask3
[void]$sb.AppendLine("`$mask$Digit = New-Object 'bool[,]' $w, $h")

for ($x = 0; $x -lt $w; $x++) {
    for ($y = 0; $y -lt $h; $y++) {
        if ($hitCounts[$x,$y] -ge $minHits) {
            [void]$sb.AppendLine("`$mask$Digit[$x,$y] = `$true")
        }
    }
}

# In das richtige Dictionary-Element schreiben
[void]$sb.AppendLine("`$script:GemValueMasks[`"$Digit`"] = `$mask$Digit")

Set-Content -Path $OutPath -Value $sb.ToString() -Encoding UTF8
Write-Host "Fertige Maske geschrieben nach: $OutPath"


}
$Majority   = 0.5

build-Mask -FolderPath "D:\Dokumente\AHK\LBR Automation\Version 3.2\pictures\1\" -Digit 1 -OutPath GemMask_1.ps1 -Majority 0.5
build-Mask -FolderPath "D:\Dokumente\AHK\LBR Automation\Version 3.2\pictures\2\" -Digit 2 -OutPath GemMask_2.ps1 -Majority 0.5
build-Mask -FolderPath "D:\Dokumente\AHK\LBR Automation\Version 3.2\pictures\3\" -Digit 3 -OutPath GemMask_3.ps1 -Majority 0.65