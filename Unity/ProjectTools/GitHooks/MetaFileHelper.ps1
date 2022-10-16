
class MetaFileHelper
{
    [string] $BasePath = $pwd
    [string[]] $FolderPaths = @()
    [string[]] $IgnoredFullPaths = @()

    MetaFileHelper([string]$projectPath) {
        $this.BasePath = $projectPath
    }
    
    ReadFolderPaths() {
        $this.FolderPaths = [System.IO.Path]::GetFullPath('Assets', $this.BasePath)

        # Unity adds meta files to local/embedded packages, which we can read from manifest.json
        $manifest = Get-Content 'Packages/manifest.json' | ConvertFrom-Json

        $this.FolderPaths += foreach ($property in $manifest.dependencies.PsObject.Properties) {
            if ($property.Value -like 'file:*') {
                $path = $property.Value -replace '^file:*', ''
                [System.IO.Path]::GetFullPath($path, $this.BasePath)
            }
        }

        if ($PSBoundParameters['Verbose'] -ne 'SilentlyContinue') {
            Write-Verbose 'Folder Paths:'
            $this.FolderPaths | ForEach-Object { Write-Verbose "  `"$PSItem`""}
        }
    }

    ReadIgnoredFullPathsFromGit() {
        $gitIgnorePaths = git ls-files -i -o --directory --exclude-standard

        $this.IgnoredFullPaths = foreach ($path in $gitIgnorePaths) {
            # git returns folders with trailing slashes but Get-ChildItem does not,
            # so remove the trailing slash to make it work with Get-ChildItem
            $path = $path -replace '/$', ''
            [System.IO.Path]::GetFullPath($path, $this.BasePath)
        }

        if ($PSBoundParameters['Verbose'] -ne 'SilentlyContinue') {
            Write-Verbose 'Ignored Full Paths:'
            $this.IgnoredFullPaths | ForEach-Object { Write-Verbose "  `"$PSItem`""}
        }
    }

    [bool]ShouldIgnoreMetaChecks($item) {
        # Unity ignores items ending in ~
        if ($item -like '*~') {
            return $true
        }
        if ($this.IgnoredFullPaths | Where-Object { $item.FullName -like $PSItem }) {
            return $true
        }
        return $false
    }
}
