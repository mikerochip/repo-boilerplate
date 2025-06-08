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

$indent = [System.Text.StringBuilder]::new()

function Remove-EmptyFolders($basePath) {
    $null = $indent.Insert(0, "  ")

    # Get all subdirectory paths
    $allFoldersFullPaths = Get-ChildItem -LiteralPath $basePath -Directory -Recurse -Force
    $allFoldersFullPaths = $allFoldersFullPaths | ForEach-Object { $_.FullName }
    # Sort directories by path length descending (i.e. deepest first) so we can safely check
    # and delete empty subdirs (empty meaning all non-git-tracked content)
    $allFoldersFullPaths = $allFoldersFullPaths | Sort-Object { $_.Length } -Descending

    foreach ($fullPath in $allFoldersFullPaths) {
        Write-Verbose "$($indent)Check `"$(Get-RelativePath($fullPath))`""
        $null = $indent.Insert(0, "  ")

        if ($gitFolderTable.Contains($fullPath)) {
            Write-Verbose "$($indent)Keep `"$(Get-RelativePath($fullPath))`""
            $null = $indent.Remove(0, 2)
            continue
        }

        Write-Host "$($indent)Remove `"$(Get-RelativePath($fullPath))`""
        if (-not $WhatIfPreference) {
            Get-ChildItem -LiteralPath $fullPath -Force | Remove-Item -Force
            Remove-Item -LiteralPath $fullPath -Force
        }

        # Remove meta file for this folder
        $metaItemPath = $fullPath + '.meta'
        if (Test-Path -LiteralPath $metaItemPath -PathType Leaf) {
            Write-Host "$($indent)Remove `"$(Get-RelativePath($metaItemPath))`""
            if (-not $WhatIfPreference) {
                Remove-Item -LiteralPath $metaItemPath -Force
            }
        }

        $null = $indent.Remove(0, 2)
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

    $gitFolderTable = @{}
    [MetaFileHelper]::GetGitTrackedFullPaths($path, $null, $gitFolderTable)
    Remove-EmptyFolders $path
}
