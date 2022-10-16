# support common parameters, mostly Verbose
[CmdletBinding()]
param(
    [string]$UnityBasePath = $pwd,
    [switch]$DryRun
)

# import scripts
. $PSScriptRoot/MetaUtil.ps1

# functions
function Get-RelativePath([string]$path) {
    # instead of using [System.IO.Path]::GetRelativePath(), we either want to remove
    # $UnityBasePath if $path starts with that, or we just want the original $path
    return $path -replace "^($UnityBasePath)*", ''
}

function Get-ItemName([string]$path) {
    return [System.IO.Path]::GetFileName($path)
}

function Test-MetaFiles($path) {
    Write-Verbose "Get-ChildItem `"$(Get-RelativePath($path))`""

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
            Write-Verbose "    Test-Path `"$(Get-ItemName($companionItemPath))`""

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
            Write-Verbose "    Test-Path `"$(Get-ItemName($metaItemPath))`""

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
Write-Verbose "Param `$UnityBasePath: `"$UnityBasePath`""
$UnityBasePath = [System.IO.Path]::GetFullPath($UnityBasePath)
Write-Verbose "Full `$UnityBasePath: `"$UnityBasePath`""

Set-Location $UnityBasePath

$metaUtil = [MetaUtil]::new($UnityBasePath)
$metaUtil.ReadFolderPaths()
$metaUtil.ReadIgnoredFullPathsFromGit()

Write-Verbose 'Begin Test-MetaFiles'
foreach ($path in $metaUtil.FolderPaths) {
    Test-MetaFiles $path
}
