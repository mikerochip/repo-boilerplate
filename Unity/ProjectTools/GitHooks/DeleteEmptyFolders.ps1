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
    $indent.Insert(0, "  ")

    Write-Verbose "$($indent)Test `"$(Get-RelativePath($path))`""

    $childItems = Get-ChildItem $path
    Write-Verbose "$($indent)BeginCount $($childItems.Count)"

    $removeCount = 0
    foreach ($item in $childItems) {
        Write-Verbose "$($indent)Check `"$($item.Name)`""

        if ($metaFileHelper.IgnoredFullPaths | Where-Object { $item.FullName -like $PSItem }) {
            Write-Verbose "$($indent)Ignore `"$($item.Name)`""
            continue
        }

        if (-not (Test-Path $item -PathType Container)) {
            continue
        }

        if (Remove-EmptyFolder $item.FullName) {
            Write-Verbose "$($indent)Removed `"$(Get-RelativePath($item.FullName))`""
            ++$removeCount
        }
    }

    Write-Verbose "$($indent)EndCount $($childItems.Count - $removeCount) for `"$(Get-RelativePath($path))`""

    $isEmpty = $childItems.Count -eq $removeCount
    if ($isEmpty) {
        Write-Host "$($indent)Remove `"$(Get-RelativePath($path))`""
        if (-not $DryRun) {
            Remove-Item $path -Force
        }
    }

    $indent.Remove(0, 2)
    return $isEmpty
}

# main block
Write-Verbose "Param `$UnityProjectPath: `"$UnityProjectPath`""
$ProjectFullPath = [System.IO.Path]::GetFullPath($UnityProjectPath)
Write-Verbose "Full `$ProjectFullPath: `"$ProjectFullPath`""

Set-Location $ProjectFullPath

$metaFileHelper = [MetaFileHelper]::new($ProjectFullPath)
$metaFileHelper.ReadFolderPaths()
$metaFileHelper.ReadIgnoredFullPathsFromGit()

Write-Verbose 'Begin Remove-EmptyFolder'
foreach ($path in $metaFileHelper.FolderPaths) {
    # we don't need the output at the top level, so pipe it to null
    Remove-EmptyFolder $path | Out-Null
}
