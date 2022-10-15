# support common parameters, mostly Verbose
[CmdletBinding()]
param(
    [switch]$DryRun = $false
)

# import scripts
. ./MetaUtil.ps1

# functions
function Get-RelativePath([string]$path) {
    # using this instead of [System.IO.Path]::GetRelativePath() so we get full paths in
    # case $basePath is not in $path
    return $path.TrimStart($basePath)
}

function Get-ItemName([string]$path) {
    return [System.IO.Path]::GetFileName($path)
}

function Test-MetaFiles($path) {
    Write-Verbose "Test `"$(Get-RelativePath($path))`""

    $dirPaths = New-Object System.Collections.Generic.List[string]

    $childItems = @(Get-ChildItem $path)
    foreach ($item in $childItems) {
        Write-Verbose "  Check `"$($item.Name)`""

        if ($metaUtil.ShouldIgnoreMetaChecks($item)) {
            Write-Verbose "    Ignore `"$($item.Name)`""
            continue
        }

        $fullPath = $item.FullName

        if ($item -like '*.meta') {
            # is this a meta file without a companion item?
            $companionItemPath = $fullPath -replace '.meta$', ''
            Write-Verbose "    Companion `"$(Get-ItemName($companionItemPath))`""

            if (-not (Test-Path -Path $companionItemPath)) {
                Write-Host "There is no file or folder for `"$(Get-RelativePath($fullPath))`""
                if (-not $DryRun) {
                    exit 1
                }
            }
        }
        else {
            # is this an item without a meta file?
            $metaItemPath = $fullPath + '.meta'
            Write-Verbose "    Meta `"$(Get-ItemName($metaItemPath))`""

            if (-not (Test-Path -Path $metaItemPath -PathType Leaf)) {
                Write-Host "There is no .meta file for `"$(Get-RelativePath($fullPath))`""
                if (-not $DryRun) {
                    exit 1
                }
            }
        }

        if (Test-Path $fullPath -PathType Container) {
            $dirPaths.Add($fullPath)
        }
    }

    foreach ($dirPath in $dirPaths) {
        Test-MetaFiles $dirPath
    }
}

# main block
$basePath = "$PSScriptRoot/../.."
Set-Location $basePath
Write-Verbose "Base Path: `"$(Get-Location)`""

$metaUtil = [MetaUtil]::new()
$metaUtil.SetIgnoredFullPathsFromGit($basePath)

foreach ($path in [MetaUtil]::FindUnityMetaFolders()) {
    Test-MetaFiles $path
}
