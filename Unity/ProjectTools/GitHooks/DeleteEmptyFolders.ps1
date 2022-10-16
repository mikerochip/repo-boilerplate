# support common parameters, mostly Verbose
[CmdletBinding()]
param(
    [string]$UnityProjectPath = $pwd,
    [switch]$DryRun
)

# import scripts
. $PSScriptRoot/MetaFileHelper.ps1

# functions
function Get-RelativePath([string]$path) {
    # instead of using [System.IO.Path]::GetRelativePath(), we either want to remove
    # $ProjectFullPath if $path starts with that, or we just want the original $path
    return $path -replace "^($ProjectFullPath)*", ''
}

$indent = [System.Text.StringBuilder]::new()

function Remove-EmptyFolder($path) {
    $null = $indent.Insert(0, "  ")

    Write-Verbose "$($indent)Get-ChildItem `"$(Get-RelativePath($path))`""

    $childItems = Get-ChildItem $path
    Write-Verbose "$($indent)BeginCount $($childItems.Count)"

    $removeCount = 0
    foreach ($item in $childItems) {
        Write-Verbose "$($indent)Check `"$($item.Name)`""

        if (-not (Test-Path $item -PathType Container)) {
            continue
        }

        if (Remove-EmptyFolder $item.FullName) {
            Write-Verbose "$($indent)Removed `"$(Get-RelativePath($item.FullName))`""
            ++$removeCount

            # remove meta file for this folder
            $metaItemPath = $item.FullName + '.meta'
            if (Test-Path $metaItemPath -PathType Leaf) {
                Write-Host "Remove `"$(Get-RelativePath($metaItemPath))`""
                if (-not $DryRun) {
                    Remove-Item $metaItemPath -Force
                }
                ++$removeCount
            }
        }
    }

    $endCount = $childItems.Count - $removeCount
    Write-Verbose "$($indent)EndCount $endCount for `"$(Get-RelativePath($path))`""

    $isEmpty = $endCount -eq 0
    if ($isEmpty) {
        Write-Host "Remove `"$(Get-RelativePath($path))`""
        if (-not $DryRun) {
            Remove-Item $path -Force
        }
    }

    $null = $indent.Remove(0, 2)
    return $isEmpty
}

# main block
Write-Verbose "Param `$UnityProjectPath: `"$UnityProjectPath`""
$ProjectFullPath = [System.IO.Path]::GetFullPath($UnityProjectPath)
Write-Verbose "Full `$ProjectFullPath: `"$ProjectFullPath`""

Set-Location $ProjectFullPath

$metaFileHelper = [MetaFileHelper]::new($ProjectFullPath)
$metaFileHelper.ReadFolderPaths()

Write-Verbose 'Begin Remove-EmptyFolder'
foreach ($path in $metaFileHelper.FolderPaths) {
    # we don't need the output at the top level
    $null = Remove-EmptyFolder $path
}
