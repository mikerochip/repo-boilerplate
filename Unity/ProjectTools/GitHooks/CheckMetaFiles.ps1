# support common parameters, mostly Verbose
[CmdletBinding()]
param()

# import scripts
. ./Util.ps1

# functions
function Get-RelativePath($item)
{
    return [System.IO.Path]::GetRelativePath($basePath, $item.FullName)
}

function Get-ItemName([string]$path)
{
    return [System.IO.Path]::GetFileName($path)
}

function Test-MetaFiles($path)
{
    Write-Verbose "Test `"$path`""

    $dirPaths = New-Object System.Collections.Generic.List[string]

    $childItems = @(Get-ChildItem $path)
    foreach ($item in $childItems)
    {
        Write-Verbose "  Check `"$($item.Name)`""

        if ($gitUtil.ShouldIgnoreMetaChecks($item))
        {
            Write-Verbose "    Ignore `"$($item.Name)`""
            continue
        }

        $fullPath = $item.FullName
        $relativePath = Get-RelativePath($item)

        if ($item -like '*.meta')
        {
            # is this a meta file without a companion item?
            $companionItemPath = $fullPath -replace '.meta$', ''
            Write-Verbose "    Companion `"$(Get-ItemName($companionItemPath))`""

            if (-not (Test-Path -Path $companionItemPath))
            {
                Write-Host "There is no file or folder for `"$relativePath`""
                #exit 1
            }
        }
        else
        {
            # is this an item without a meta file?
            $metaItemPath = $fullPath + '.meta'
            Write-Verbose "    Meta `"$(Get-ItemName($metaItemPath))`""

            if (-not (Test-Path -Path $metaItemPath -PathType Leaf))
            {
                Write-Host "There is no .meta file for `"$relativePath`""
                #exit 1
            }
        }

        if (Test-Path $fullPath -PathType Container)
        {
            $dirPaths.Add($relativePath)
        }
    }

    foreach ($dirPath in $dirPaths)
    {
        Test-MetaFiles $dirPath
    }
}

# main block
$basePath = "$PSScriptRoot/../.."
Set-Location $basePath
Write-Verbose "Base Path: `"$(Get-Location)`""

$gitUtil = [Util]::new()
$gitUtil.SetGitIgnoredFullPaths($basePath)
Write-Verbose 'Ignore Paths:'
$gitUtil.IgnoredFullPaths | ForEach-Object {
    Write-Verbose "  `"$PSItem`""
}

[Util]::FindUnityMetaFolders() | ForEach-Object {
    Test-MetaFiles $PSItem
}
