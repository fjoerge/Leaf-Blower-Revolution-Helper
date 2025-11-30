# ===== ocr\GemValueOCR.ps1 =====
# Tesseract-basiertes OCR-Modul für Gem-Wert-Erkennung
# Optimiert für 32x32px Ziffern, unterstützt auch Werte 1-100

param(
    [string]$TesseractPath = "C:\Program Files\Tesseract-OCR\tesseract.exe"
)

Add-Type -AssemblyName System.Drawing

$script:TesseractExe = $TesseractPath
$script:TesseractAvailable = $false

if (Test-Path $script:TesseractExe) {
    $script:TesseractAvailable = $true
    Write-Host "Tesseract OCR erkannt: $script:TesseractExe" -ForegroundColor Green
} else {
    Write-Warning "âš  Tesseract nicht gefunden unter: $script:TesseractExe"
    Write-Host "Installieren Sie Tesseract mit: winget install UB-Mannheim.TesseractOCR" -ForegroundColor Yellow
}

function Prepare-ImageForOCR {
    param(
        [System.Drawing.Bitmap]$InputBitmap,
        [int]$ScaleFactor = 4,
        [int]$BinarizeThreshold = 140
    )

    if ($null -eq $InputBitmap) { return $null }

    $newWidth  = $InputBitmap.Width  * $ScaleFactor
    $newHeight = $InputBitmap.Height * $ScaleFactor

    $scaled = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
    $g      = [System.Drawing.Graphics]::FromImage($scaled)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::High
    $g.DrawImage($InputBitmap, 0, 0, $newWidth, $newHeight)
    $g.Dispose()

    for ($x = 0; $x -lt $newWidth; $x++) {
        for ($y = 0; $y -lt $newHeight; $y++) {
            $px = $scaled.GetPixel($x, $y)
            $brightness = ($px.R + $px.G + $px.B) / 3
            if ($brightness -gt $BinarizeThreshold) {
                $scaled.SetPixel($x, $y, [System.Drawing.Color]::White)  # Zahl
            } else {
                $scaled.SetPixel($x, $y, [System.Drawing.Color]::Black)  # Hintergrund
            }
        }
    }
    # Export Black/White Screenshotted
    #$scaled.Save("C:\Temp\L_53_inGemValue_scaled.png", [System.Drawing.Imaging.ImageFormat]::Png)
    return $scaled
}

function Get-NumberFromBitmapTesseract {
    param(
        [System.Drawing.Bitmap]$InputBitmap,
        [bool]$Prepare = $true
    )

    if (-not $script:TesseractAvailable) {
        return $null
    }
    
    if ($null -eq $InputBitmap) {
        return $null
    }
    
    $InputBitmap.Save("C:\Temp\L_7_inNumberFromBitmapTesseract_InputBitmap.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $tempImage = $null
    $tempOut = $null
    $preparedBitmap = $null
    
    try {
        $tempDir = [System.IO.Path]::GetTempPath()
        $guid = [System.Guid]::NewGuid().ToString()
        $tempImage = Join-Path $tempDir "ocr_temp_$guid.png"
        $tempOut = Join-Path $tempDir "ocr_result_$guid"
        
        # Bildvorbereitung
        if ($Prepare) {
            $preparedBitmap = Prepare-ImageForOCR -InputBitmap $InputBitmap -ScaleFactor 4

            if ($preparedBitmap -ne $null) {
                try {
                    $preparedBitmap.Save($tempImage, [System.Drawing.Imaging.ImageFormat]::Png)
                } catch {
                    Write-Warning "Fehler beim Speichern des vorbereiteten Bitmaps: $_"
                    $InputBitmap.Save($tempImage, [System.Drawing.Imaging.ImageFormat]::Png)
                }
            } else {
                # Fallback: Originalbild speichern
                $InputBitmap.Save($tempImage, [System.Drawing.Imaging.ImageFormat]::Png)
            }
        } else {
            $InputBitmap.Save($tempImage, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        
        if (-not (Test-Path $tempImage)) {
            Write-Warning "Temp-Image wurde nicht erstellt: $tempImage"
            return $null
        }

        # Tesseract-Aufruf
        $tesseractArgs = "`"$tempImage`" `"$tempOut`" --psm 7 --oem 3 -c tessedit_char_whitelist=0123456789"


        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.FileName = $script:TesseractExe
        $process.StartInfo.Arguments = $tesseractArgs
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        
        $started = $process.Start()
        
        if (-not $started) {
            Write-Warning "Warning:  Tesseract-Prozess konnte nicht gestartet werden"
            return $null
        }

        $finished = $process.WaitForExit(5000)
        
        if (-not $finished) {
            Write-Warning "âš  Tesseract-Timeout"
            try { $process.Kill() } catch {}
            return $null
        }

        $resultFile = "$tempOut.txt"

        if (-not (Test-Path $resultFile)) {
            $stderr = $process.StandardError.ReadToEnd()
            if ($stderr) {
                Write-Warning "Tesseract StdErr: $stderr"
            }
            return $null
        }

        if ((Get-Content $resultFile -Raw -Encoding UTF8) -eq $null) {
            return $null
        } else {
            $result = (Get-Content $resultFile -Raw -Encoding UTF8).Trim()
        }

        if ([string]::IsNullOrWhiteSpace($result)) {
            return $null
        }

        # Nur reine Zahlen akzeptieren
        if ($result -match '^\d+$') {
            $number = [int]$result
            Write-Log "Zahl gefunden: $result" "DEBUG"
            if ($number -ge 1 -and $number -le 100) {
                return $number
            }
        }

        return $null
    }
    catch {
        Write-Warning "âš  Fehler in Get-NumberFromBitmapTesseract: $_"
        return $null
    }
    finally {

        if ($preparedBitmap) { 
            try { $preparedBitmap.Dispose() } catch {}
        }
        
        if (Test-Path $tempImage) {
            try { Remove-Item $tempImage -Force -ErrorAction SilentlyContinue } catch {}
        }

        if (Test-Path "$tempOut.txt") {
            try { Remove-Item "$tempOut.txt" -Force -ErrorAction SilentlyContinue } catch {}
        }

        if ($preparedBitmap -ne $null) { 
            try { $preparedBitmap.Dispose() } catch {}
        }
    }
}

function Get-OCRStats {
    return @{
        TesseractAvailable = $script:TesseractAvailable
        TesseractPath = $script:TesseractExe
    }
}

# Export functions
#Export-ModuleMember -Function Get-NumberFromBitmapTesseract, Prepare-ImageForOCR, Get-OCRStats
