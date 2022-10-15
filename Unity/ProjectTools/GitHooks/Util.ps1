
class Util
{
    [string[]] $IgnoredFullPaths = @()

    SetGitIgnoredFullPaths($basePath)
    {
        $this.IgnoredFullPaths = foreach ($path in @(git ls-files -i -o --directory --exclude-standard)) {
            [System.IO.Path]::GetFullPath($path, $basePath) `
                -replace '\\', '/' `
                -replace '/$', ''
        }
    }

    [bool]ShouldIgnoreMetaChecks($item)
    {
        if ($item -like '*~')
        {
            return $true
        }
        if ($this.IgnoredFullPaths.Contains($item.FullName))
        {
            return $true
        }
        return $false
    }
    
    static [string[]]FindUnityMetaFolders()
    {
        return @(
            "ProjectUnity/Assets"
            "ProjectShared/Company.Project.Package"
        )
    }
}
