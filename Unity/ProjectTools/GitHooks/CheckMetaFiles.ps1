# support common parameters, mostly Verbose
[CmdletBinding()]
param(
    [string]$BasePath = $pwd,
    [switch]$DryRun = $false
)

# import scripts
. $PSScriptRoot/MetaUtil.ps1

# functions
function Get-RelativePath([string]$path) {
    # using this instead of [System.IO.Path]::GetRelativePath() so we get full paths in
    # case $BasePath is not in $path
    return $path -replace "^($BasePath)*", ''
}

function Get-ItemName([string]$path) {
    return [System.IO.Path]::GetFileName($path)
}

function Test-MetaFiles($path) {
    Write-Verbose "Test `"$(Get-RelativePath($path))`""

    $dirPaths = New-Object System.Collections.Generic.List[string]

    $childItems = @(Get-ChildItem $path)
    foreach ($item in $childItems) {
        Write-Verbose "  Test `"$($item.Name)`""

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
Write-Verbose "Param `$BasePath: `"$BasePath`""
$BasePath = [System.IO.Path]::GetFullPath($BasePath)
Write-Verbose "Full `$BasePath: `"$BasePath`""

Set-Location $BasePath

$metaUtil = [MetaUtil]::new($BasePath)
$metaUtil.SetIgnoredFullPathsFromGit()
$metaUtil.ReadFolderPathsWithMetaFiles()

foreach ($path in $metaUtil.FolderPathsWithMetaFiles) {
    Test-MetaFiles $path
}
