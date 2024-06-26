# support common parameters, mostly Verbose
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$UnityProjectPath = $pwd
)

# import scripts
. $PSScriptRoot/MetaFileHelper.ps1

# functions
function Get-RelativePath([string]$path) {
    # instead of using [System.IO.Path]::GetRelativePath(), we either want to remove
    # $UnityProjectPath if $path starts with that, or we just want the original $path
    return $path.Replace("$UnityProjectPath", '')
}

function Get-ItemName([string]$path) {
    return [System.IO.Path]::GetFileName($path)
}

function Test-NoSourceControlledFiles($items) {
    foreach ($item in $items) {
        if (Test-Path $item -PathType Container) {
            return $false
        }
        if ($gitFileTable.Contains($item.FullName)) {
            return $false
        }
    }
    return $true
}

function Test-IgnoreMetaChecks($item) {
    if ([MetaFileHelper]::IsUnityHiddenItem($item)) {
        return $true
    }
    if ((Test-Path $item -PathType Leaf) -and !$gitFileTable.Contains($item.FullName)) {
        return $true
    }
    if ((Test-Path $item -PathType Container) -and !$gitFolderTable.Contains($item.FullName)) {
        return $true
    }
    return $false
}

$indent = [System.Text.StringBuilder]::new()

function Test-MetaFiles($path) {
    $null = $indent.Insert(0, "  ")

    Write-Verbose "$($indent)Get-ChildItem `"$(Get-RelativePath($path))`""

    $items = Get-ChildItem $path -Force

    # this folder is subject to meta checks, but is empty or has all ignored files
    if (Test-NoSourceControlledFiles $items) {
        Write-Host ("Folder `"$(Get-RelativePath($path))`" is empty or has all ignored files`n" +
                    "Either delete it or add a blank file named `".keep`" to keep it")
        if (-not $WhatIfPreference) {
            exit 1
        } else {
            $null = $indent.Remove(0, 2)
            return
        }
    }

    $dirPaths = New-Object System.Collections.Generic.List[string]

    foreach ($item in $items) {
        Write-Verbose "$($indent)Check `"$($item.Name)`""

        if (Test-IgnoreMetaChecks $item) {
            Write-Verbose "$($indent)Ignore `"$($item.Name)`""
            continue
        }

        $fullPath = $item.FullName

        if ($item -like '*.meta') {
            # is this a meta file without a companion item?
            $companionItemPath = $fullPath -replace '.meta$', ''
            Write-Verbose "$($indent)Test-Path `"$(Get-ItemName($companionItemPath))`""

            if (-not (Test-Path -LiteralPath $companionItemPath)) {
                Write-Host "There is no file or folder for `"$(Get-RelativePath($fullPath))`""
                if (-not $WhatIfPreference) {
                    exit 1
                }
            }
        } else {
            # is this an item without a meta file?
            $metaItemPath = $fullPath + '.meta'
            Write-Verbose "$($indent)Test-Path `"$(Get-ItemName($metaItemPath))`""

            if (-not (Test-Path -LiteralPath $metaItemPath -PathType Leaf)) {
                Write-Host "There is no .meta file for `"$(Get-RelativePath($fullPath))`""
                if (-not $WhatIfPreference) {
                    exit 1
                }
            }
        }

        if ([MetaFileHelper]::ShouldCheckChildItems($item)) {
            $dirPaths.Add($fullPath)
        }
    }

    foreach ($dirPath in $dirPaths) {
        Test-MetaFiles $dirPath
    }

    $null = $indent.Remove(0, 2)
}

# main block
Write-Verbose "Param `$UnityProjectPath: `"$UnityProjectPath`""
$UnityProjectPath = [System.IO.Path]::GetFullPath($UnityProjectPath)
Write-Verbose "Full `$UnityProjectPath: `"$UnityProjectPath`""

$metaFileFolderPaths = [MetaFileHelper]::GetMetaFileFolderPaths($UnityProjectPath)

foreach ($path in $metaFileFolderPaths) {
    Write-Verbose "Check Top-Level `"$path`""

    $gitFileTable = @{}
    $gitFolderTable = @{}
    [MetaFileHelper]::GetGitTrackedFullPaths($path, $gitFileTable, $gitFolderTable)

    Test-MetaFiles $path
}
