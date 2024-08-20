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
    if ((Test-Path $path -PathType Leaf) -and $gitFileTable.Contains($path)) {
        return $true
    }
    if ((Test-Path $path -PathType Container) -and $gitFolderTable.Contains($path)) {
        return $true
    }
    return $false
}

$indent = [System.Text.StringBuilder]::new()

function Test-MetaFiles($path) {
    $null = $indent.Insert(0, "  ")

    Write-Verbose "$($indent)Get-ChildItem `"$(Get-RelativePath($path))`""

    $checkDirPaths = New-Object System.Collections.Generic.List[string]

    $items = Get-ChildItem $path -Force
    foreach ($item in $items) {
        Write-Verbose "$($indent)Check `"$($item.Name)`""

        $fullPath = $item.FullName

        if ([MetaFileHelper]::IsUnityHiddenItem($item)) {
            Write-Verbose "$($indent)Ignored by Unity: `"$($item.Name)`""
            continue
        }
        if (-not (Test-GitTracked $fullPath)) {
            Write-Verbose "$($indent)Ignored by Git: `"$($item.Name)`""
            continue
        }

        if ($item -like '*.meta') {
            $companionItemPath = $fullPath -replace '.meta$', ''
            Write-Verbose "$($indent)Test companion `"$(Get-ItemName($companionItemPath))`""

            if ([System.IO.File]::Exists($companionItemPath)) {
                # is the file source controlled?
                if (!$gitFileTable.Contains($companionItemPath)) {
                    Write-Host ("File `"$(Get-RelativePath($companionItemPath))`" is not in source control, " +
                                "but its .meta file is")
                    if (-not $WhatIfPreference) {
                        exit 1
                    }
                }
            } elseif ([System.IO.Directory]::Exists($companionItemPath)) {
                # does the directory have any source controlled files?
                if (!$gitFolderTable.Contains($companionItemPath)) {
                    Write-Host ("Folder `"$(Get-RelativePath($companionItemPath))`" has a .meta file " +
                                "but is empty or has all ignored files.`n" +
                                "Add a blank file named `".keep`" to keep it.")
                    if (-not $WhatIfPreference) {
                        exit 1
                    }
                }
            } else {
                Write-Host "There is no file or folder for `"$(Get-RelativePath($fullPath))`""
                if (-not $WhatIfPreference) {
                    exit 1
                }
            }
        } else {
            $metaItemPath = $fullPath + '.meta'
            Write-Verbose "$($indent)Test meta `"$(Get-ItemName($metaItemPath))`""

            if (!$gitFileTable.Contains($metaItemPath)) {
                Write-Host "The .meta file for `"$(Get-RelativePath($fullPath))`" is not in source control"
                if (-not $WhatIfPreference) {
                    exit 1
                }
            }
        }

        if ([MetaFileHelper]::ShouldCheckChildItems($item)) {
            $checkDirPaths.Add($fullPath)
        }
    }

    foreach ($dirPath in $checkDirPaths) {
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
