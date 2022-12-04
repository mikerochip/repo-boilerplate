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

function Test-HasGitItems([string]$dirPath) {
    Write-Verbose "$($indent)Test-HasGitItems `"$dirPath`""
    $contains = $gitFolderTable.ContainsKey($dirPath)
    Write-Verbose "$($indent)  $contains"
    return $contains
}

function Remove-EmptyFolder($path) {
    $null = $indent.Insert(0, "  ")

    Write-Verbose "$($indent)Get-ChildItem `"$(Get-RelativePath($path))`""

    $childItems = Get-ChildItem $path

    foreach ($item in $childItems) {
        Write-Verbose "$($indent)Check `"$($item.Name)`""

        if (-not (Test-Path $item -PathType Container)) {
            continue
        }

        $fullPath = $item.FullName

        if (Test-HasGitItems $fullPath) {
            # if git thinks this folder exists, then we need to go deeper
            Remove-EmptyFolder $fullPath
        } else {
            # either this folder is empty or only has ignored files, delete it
            Write-Host "$($indent)Remove `"$(Get-RelativePath($fullPath))`""
            if (-not $DryRun) {
                Get-ChildItem $item.FullName -Recurse -Force | Remove-Item -Recurse -Force
            }

            # remove meta file for this folder
            $metaItemPath = $fullPath + '.meta'
            if (Test-Path $metaItemPath -PathType Leaf) {
                Write-Host "$($indent)Remove `"$(Get-RelativePath($metaItemPath))`""
                if (-not $DryRun) {
                    Remove-Item $metaItemPath -Force
                }
            }
        }
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
    $null = [MetaFileHelper]::GetGitItems($path, $gitFolderTable)

    Remove-EmptyFolder $path
}
