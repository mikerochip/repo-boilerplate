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
    # $UnityProjectPath if $path starts with that, or we just want the original $path
    return $path.Replace("$UnityProjectPath", '')
}

$indent = [System.Text.StringBuilder]::new()

function Remove-EmptyFolder($path) {
    $null = $indent.Insert(0, "  ")

    Write-Verbose "$($indent)Get-ChildItem `"$(Get-RelativePath($path))`""

    Set-Location $path
    $childItems = Get-ChildItem
    $gitItems = [MetaFileHelper]::GetCurrentDirGitItems()

    foreach ($item in $childItems) {
        Write-Verbose "$($indent)Check `"$($item.Name)`""

        if (-not (Test-Path $item -PathType Container)) {
            continue
        }

        if ($gitItems.Contains($item.Name)) {
            # if git thinks this folder exists, then we need to go deeper
            Remove-EmptyFolder $item.FullName
            Set-Location $path
        } else {
            # either this folder is empty or only has ignored files, delete it
            Write-Host "$($indent)Remove `"$(Get-RelativePath($item.FullName))`""
            if (-not $DryRun) {
                Remove-Item $path -Recurse -Force
            }

            # remove meta file for this folder
            $metaItemPath = $item.FullName + '.meta'
            if (Test-Path $metaItemPath -PathType Leaf) {
                Write-Host "$($indent)Remove `"$(Get-RelativePath($metaItemPath))`""
                if (-not $DryRun) {
                    Remove-Item $metaItemPath -Force
                }
            }
        }
    }

    $null = $indent.Remove(0, 2)
    return $isEmpty
}

# main block
Write-Verbose "Param `$UnityProjectPath: `"$UnityProjectPath`""
$UnityProjectPath = [System.IO.Path]::GetFullPath($UnityProjectPath)
Write-Verbose "Full `$UnityProjectPath: `"$UnityProjectPath`""

Set-Location $UnityProjectPath

$metaFileFolderPaths = [MetaFileHelper]::GetMetaFileFolderPaths($UnityProjectPath)

Write-Verbose 'Begin Remove-EmptyFolder'
foreach ($path in $metaFileFolderPaths) {
    # we don't need the output at the top level
    $null = Remove-EmptyFolder $path
}
