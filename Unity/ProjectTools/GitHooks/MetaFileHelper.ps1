
class MetaFileHelper
{
    [string] $BasePath = $pwd
    [string[]] $FolderPaths = @()

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
}
