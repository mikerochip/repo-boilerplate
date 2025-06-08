# support common parameters, mostly Verbose and WhatIf
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$UnityProjectPath = $pwd
)

# imports
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

function Test-GitTracked([string]$path) {
    return $gitFileTable.Contains($path) -or $gitFolderTable.Contains($path)
}

$indent = [System.Text.StringBuilder]::new()

function Test-MetaFiles($path) {
    $null = $indent.Insert(0, "  ")

    # Get all items at once to minimize file system calls
    $allItems = Get-ChildItem -LiteralPath $path -Force -Recurse

    # Create lookup tables for faster access
    $filesByFullPath = New-Object System.Collections.Generic.List[string]
    $foldersByFullPath = New-Object System.Collections.Generic.List[string]

    # First pass: Build lookup tables and filter to just files and folders
    # that need to be checked for matching meta files
    Write-Verbose "$($indent)First pass: Filter items that need meta files"
    $null = $indent.Insert(0, "  ")

    foreach ($item in $allItems) {
        $fullPath = $item.FullName

        if ([MetaFileHelper]::IsUnityHiddenItem($item)) {
            Write-Verbose "$($indent)Ignored by Unity: `"$($item.Name)`""
            continue
        }
        if (-not (Test-GitTracked $fullPath)) {
            Write-Verbose "$($indent)Ignored by Git: `"$($item.Name)`""
            continue
        }

        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            Write-Verbose "$($indent)Add file: `"$(Get-RelativePath($fullPath))`""
            $filesByFullPath.Add($fullPath)
        }
        else {
            Write-Verbose "$($indent)Add folder: `"$(Get-RelativePath($fullPath))`""
            $foldersByFullPath.Add($fullPath)
        }
    }

    $null = $indent.Remove(0, 2)

    # Second pass: Check file table
    # Two categories:
    # 1. meta files that should have companion files
    # 2. files that should have matching .meta files
    Write-Verbose "$($indent)Second pass: Check files"
    $null = $indent.Insert(0, "  ")

    foreach ($fullPath in $filesByFullPath) {
        $isMetaFile = $fullPath -like '*.meta'

        Write-Verbose "$($indent)Check file: `"$(Get-RelativePath($fullPath))`""

        if ($isMetaFile) {
            $companionItemPath = $fullPath -replace '\.meta$', ''

            if ([System.IO.File]::Exists($companionItemPath)) {
                if (!$gitFileTable.Contains($companionItemPath)) {
                    Write-Host ("File `"$(Get-RelativePath($companionItemPath))`" is not in source control, " +
                        "but its .meta file is")
                    if (-not $WhatIfPreference) {
                        exit 1
                    }
                }
            }
            elseif ([System.IO.Directory]::Exists($companionItemPath)) {
                if (!$gitFolderTable.Contains($companionItemPath)) {
                    Write-Host ("Folder `"$(Get-RelativePath($companionItemPath))`" is not in source control, " +
                        "but its .meta file is")
                    if (-not $WhatIfPreference) {
                        exit 1
                    }
                }
            }
            else {
                Write-Host "There is no companion `"$(Get-RelativePath($companionItemPath))`" for `"$(Get-RelativePath($fullPath))`""
                if (-not $WhatIfPreference) {
                    exit 1
                }
            }
        }
        else {
            $metaItemPath = $fullPath + '.meta'

            if (!$gitFileTable.Contains($metaItemPath)) {
                Write-Host "The .meta file for `"$(Get-RelativePath($fullPath))`" is not in source control"
                if (-not $WhatIfPreference) {
                    exit 1
                }
            }
        }
    }

    $null = $indent.Remove(0, 2)

    # Third pass: Check folder table
    Write-Verbose "$($indent)Third pass: Check folders"
    $null = $indent.Insert(0, "  ")

    foreach ($fullPath in $foldersByFullPath) {
        Write-Verbose "$($indent)Check folder: `"$(Get-RelativePath($fullPath))`""

        $companionItemPath = $fullPath + '.meta'

        if ([System.IO.File]::Exists($companionItemPath)) {
            continue
        }

        Write-Host "The .meta file for `"$(Get-RelativePath($fullPath))`" is not in source control"
        if (-not $WhatIfPreference) {
            exit 1
        }
    }
    $null = $indent.Remove(0, 2)

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
