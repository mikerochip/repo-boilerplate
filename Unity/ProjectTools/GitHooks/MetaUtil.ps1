
class MetaUtil
{
    [string] $BasePath
    [string[]] $IgnoredFullPaths = @()
    [string[]] $FolderPathsWithMetaFiles = @()

    MetaUtil([string]$basePath) {
        $this.BasePath = $basePath
    }

    SetIgnoredFullPathsFromGit() {
        Write-Verbose 'Ignored Paths:'

        $this.IgnoredFullPaths = foreach ($path in @(git ls-files -i -o --directory --exclude-standard)) {
            # remove trailing '/' from paths because that's what git ls-files does
            $fullPath = [System.IO.Path]::GetFullPath($path, $this.BasePath) `
                -replace '\\', '/' `
                -replace '/$', ''

            Write-Verbose "  `"$fullPath`""

            $fullPath
        }
    }
    
    ReadFolderPathsWithMetaFiles() {
        Write-Verbose 'Folder Paths with Meta Files:'

        $this.FolderPathsWithMetaFiles = 'Assets'
        Write-Verbose "  `"Assets`""

        # Unity adds meta files to local/embedded packages, which are in manifest.json
        $manifest = Get-Content 'Packages/manifest.json' | ConvertFrom-Json

        $this.FolderPathsWithMetaFiles += foreach ($property in $manifest.dependencies.PsObject.Properties) {
            if ($property.Value -like 'file:*') {
                $path = $property.Value -replace '^file:*', ''
                $fullPath = [System.IO.Path]::GetFullPath($path, $this.BasePath)

                Write-Verbose "  `"$fullPath`""

                $fullPath
            }
        }
    }

    [bool]ShouldIgnoreMetaChecks($item) {
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
}
