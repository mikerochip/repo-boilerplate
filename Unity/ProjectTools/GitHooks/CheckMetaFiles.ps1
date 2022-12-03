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

function Get-ItemName([string]$path) {
    return [System.IO.Path]::GetFileName($path)
}

function Test-IsEmptyForGit($items) {
    foreach ($item in $items) {
        if (Test-Path $item -PathType Container) {
            return $false
        }
        if ($item -in $gitItems) {
            return $false
        }
    }
    return $true
}

function Test-IgnoreMetaChecks($item) {
    # Unity ignores items ending in ~
    if ($item -like '*~') {
        return $true
    }
    if ((Test-Path $item -PathType Leaf) -and ($item -notin $gitItems)) {
        return $true
    }
    return $false
}

$indent = [System.Text.StringBuilder]::new()

function Test-MetaFiles($path) {
    $null = $indent.Insert(0, "  ")

    Write-Verbose "$($indent)Get-ChildItem `"$(Get-RelativePath($path))`""

    $items = Get-ChildItem $path

    # is this folder empty or have all ignored files?
    if (Test-IsEmptyForGit $items) {
        Write-Host ("Folder `"$(Get-RelativePath($path))`" is empty or has all ignored files`n" +
                    "Either delete it or add a blank file named `".keep`" to keep it")
        if (-not $DryRun) {
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

            if (-not (Test-Path -Path $companionItemPath)) {
                Write-Host "There is no file or folder for `"$(Get-RelativePath($fullPath))`""
                if (-not $DryRun) {
                    exit 1
                }
            }
        } else {
            # is this an item without a meta file?
            $metaItemPath = $fullPath + '.meta'
            Write-Verbose "$($indent)Test-Path `"$(Get-ItemName($metaItemPath))`""

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

    $null = $indent.Remove(0, 2)
}

# main block
Write-Verbose "Param `$UnityProjectPath: `"$UnityProjectPath`""
$UnityProjectPath = [System.IO.Path]::GetFullPath($UnityProjectPath)
Write-Verbose "Full `$UnityProjectPath: `"$UnityProjectPath`""

$metaFileFolderPaths = [MetaFileHelper]::GetMetaFileFolderPaths($UnityProjectPath)

Write-Verbose 'Begin Test-MetaFiles'
foreach ($path in $metaFileFolderPaths) {
    $gitItems = [MetaFileHelper]::GetGitItems($path)
    
    Test-MetaFiles $path
}
