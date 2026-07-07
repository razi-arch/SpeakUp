$ErrorActionPreference = "SilentlyContinue"

function Get-FreeSpaceGb {
    $drive = [System.IO.DriveInfo]::new("C")
    return [math]::Round($drive.AvailableFreeSpace / 1GB, 2)
}

function Get-DirectorySizeBytes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return 0
    }

    $sum = (Get-ChildItem -LiteralPath $Path -Force -Recurse -File | Measure-Object Length -Sum).Sum
    if ($null -eq $sum) {
        return 0
    }

    return [int64]$sum
}

function Remove-ChildrenSafely {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    Get-ChildItem -LiteralPath $Path -Force | ForEach-Object {
        try {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Host "Skipped locked item:" $_.FullName
        }
    }
}

function Remove-DirectorySafely {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Host "Skipped locked folder:" $Path
    }
}

$targets = @(
    @{
        Label = "Project build output"
        Path = "C:\Users\mdsma\StudioProjects\smart_aac_speech_learning\build"
        Mode = "RemoveDirectory"
    },
    @{
        Label = "Windows temp files"
        Path = "C:\Users\mdsma\AppData\Local\Temp"
        Mode = "RemoveChildren"
    }
)

$beforeFreeGb = Get-FreeSpaceGb
Write-Host ""
Write-Host "Free space on C: before cleanup:" $beforeFreeGb "GB"
Write-Host ""

foreach ($target in $targets) {
    $beforeBytes = Get-DirectorySizeBytes -Path $target.Path

    if ($target.Mode -eq "RemoveDirectory") {
        Remove-DirectorySafely -Path $target.Path
    } else {
        Remove-ChildrenSafely -Path $target.Path
    }

    $afterBytes = Get-DirectorySizeBytes -Path $target.Path
    $freedGb = [math]::Round(($beforeBytes - $afterBytes) / 1GB, 2)

    Write-Host $target.Label ":" $freedGb "GB freed"
}

$afterFreeGb = Get-FreeSpaceGb
$totalRecoveredGb = [math]::Round($afterFreeGb - $beforeFreeGb, 2)

Write-Host ""
Write-Host "Free space on C: after cleanup:" $afterFreeGb "GB"
Write-Host "Total recovered:" $totalRecoveredGb "GB"
Write-Host ""
Write-Host "Optional extra savings (admin required): turn off hibernation with 'powercfg /h off' to recover about 6.29 GB."
