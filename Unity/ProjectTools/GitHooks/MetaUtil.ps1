
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
        # we need to include the Unity Assets folder and any local/embedded packages
        # from the manifest.json
        $manifest = Get-Content 'Packages/manifest.json' | ConvertFrom-Json
        $manifestPaths = foreach ($property in $manifest.dependencies.PsObject.Properties) {
            if ($property.Value -like 'file:*') {
                $property.Value -replace '^file:*', ''
            }
        }
        return @('Assets') + $manifestPaths
    }
}
