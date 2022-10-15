
class MetaUtil
{
    [string[]] $IgnoredFullPaths = @()

    SetIgnoredFullPathsFromGit($basePath)
    {
        Write-Verbose 'Ignored Paths:'

        $this.IgnoredFullPaths = foreach ($path in @(git ls-files -i -o --directory --exclude-standard)) {
            # remove trailing '/' from paths because that's what git ls-files does
            $fullPath = [System.IO.Path]::GetFullPath($path, $basePath) `
                -replace '\\', '/' `
                -replace '/$', ''

            Write-Verbose "  `"$fullPath`""

            $fullPath
        }
    }

    [bool]ShouldIgnoreMetaChecks($item)
    {
        # Unity ignores items ending in ~
        if ($item -like '*~')
        {
            return $true
        }
        if ($this.IgnoredFullPaths | Where-Object { $item.FullName -like $PSItem })
        {
            return $true
        }
        return $false
    }
    
    static [string[]]FindFolderPathsWithMetaFiles()
    {
        return @(
            "ProjectUnity/Assets"
            "ProjectShared/Company.Project.Package"
        )
    }
}
