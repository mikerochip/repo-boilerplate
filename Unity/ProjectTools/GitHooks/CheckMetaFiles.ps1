. ./Util.ps1

$Main =
{
    Write-Output '`nIgnored Files:'
    [Util]::GetGitIgnoredFilePaths()
    Write-Output '`nUnity Paths:'
    [Util]::FindUnityMetaFolders() | ForEach-Object | Test-MetaFiles
    Test-Exit
}

function Test-Exit
{
    Write-Output 'Can I finish before I...'
    exit 1
    Write-Output 'Exit?'
}

function Test-MetaFiles($path)
{
    Write-Verbose "Test " $path

    $ignoredFilePaths = [Util]::GetGitIgnoredFilePaths()
    $childItems = @(Get-ChildItem $path)
    $dirPaths = New-Object System.Collections.Generic.List[string]

    foreach ($item in $childItems)
    {
        Write-Verbose "Check " $item.Name

        if ($ignoredFilePaths | Where-Object {$item -like $PSItem})
        {
            Write-Verbose "Ignore " $item.Name
            continue
        }

        if ($item -like '*.meta$')
        {
            # is this a meta file without an item?
            $nonMetaItemPath = $ite.FullName -replace '.meta$', ''
            if (-not (Test-Path -Path $nonMetaItemPath))
            {
                Write-Error "There is no file or folder for `"$($item.FullName)`""
                exit 1
            }
        }
        else
        {
            # is this an item without a meta file?
            $metaItemPath = $item.FullName + '.meta'
            if (-not (Test-Path -Path $metaItemPath -PathType Leaf))
            {
                Write-Error "There is no .meta file for `"$($item.FullName)`""
                exit 1
            }
        }

        if (Test-Path $item.FullName -PathType Container)
        {
            $dirPaths.Add($item.FullName)
        }
    }

    foreach ($dirPath in $dirPaths)
    {
        Test-MetaFiles $dirPath
    }
}

& $Main
