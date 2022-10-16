
class MetaFileHelper {
    static [string[]]GetMetaFileFolderPaths([string]$unityProjectPath) {
        $folderPaths = @([System.IO.Path]::GetFullPath('Assets', $unityProjectPath))
    
        # Unity adds meta files to local/embedded packages, which we can read from manifest.json
        $manifest = Get-Content 'Packages/manifest.json' | ConvertFrom-Json
    
        $folderPaths += foreach ($property in $manifest.dependencies.PsObject.Properties) {
            if ($property.Value -like 'file:*') {
                $path = $property.Value -replace '^file:*', ''
                # it's fine if the path is outside the unity project
                [System.IO.Path]::GetFullPath($path, $unityProjectPath)
            }
        }
    
        if ($PSBoundParameters['Verbose'] -ne 'SilentlyContinue') {
            Write-Verbose 'Meta File Folder Paths:'
            $folderPaths | ForEach-Object { Write-Verbose "  `"$PSItem`""}
        }

        return $folderPaths
    }
}
