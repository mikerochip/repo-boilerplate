
class MetaFileHelper {
    static [string]FindGitPath([string]$path) {
        while ($path) {
            $gitPath = Get-ChildItem $path -Hidden | Where-Object { $PSItem.Name -eq '.git' }
            if ($gitPath) {
                return $gitPath
            }
            $path = [System.IO.Directory]::GetParent($path)
        }
        return $null
    }

    <#
    .SYNOPSIS
    Returns full paths of all top-level folders that include meta files.
    .INPUTS
    The Unity project at the given path.
    .DESCRIPTION
    Includes the 'Assets' folder. Also includes local and embedded package dependencies, but
    only if they live in the same repo as the Unity project.
    #>
    static [string[]]GetMetaFileFolderPaths([string]$unityProjectPath) {
        Write-Verbose 'GetMetaFileFolderPaths'
        Write-Verbose "  unityProjectPath `"$unityProjectPath`""

        $projectGitPath = [MetaFileHelper]::FindGitPath($unityProjectPath)
        Write-Verbose "  projectGitPath `"$projectGitPath`""

        # Unity adds meta files to:
        # 1. "Assets/"
        # 2. Any local or embedded packages in "Packages/manifest.json"
        $folderPaths = @([System.IO.Path]::GetFullPath('Assets', $unityProjectPath))
    
        $manifest = Get-Content 'Packages/manifest.json' | ConvertFrom-Json
        $folderPaths += foreach ($property in $manifest.dependencies.PSObject.Properties) {
            if ($property.Value -notlike 'file:*') {
                continue
            }

            $path = $property.Value -replace '^file:*', ''
            Write-Verbose "  Check `"$path`""

            $dependencyGitPath = [MetaFileHelper]::FindGitPath($path)
            Write-Verbose "  dependencyGitPath `"$dependencyGitPath`""

            if ($projectGitPath -ne $dependencyGitPath) {
                Write-Verbose "  Skip `"$path`""
                continue
            }
            
            Write-Verbose "  Include `"$path`""
            [System.IO.Path]::GetFullPath($path, $unityProjectPath)
        }

        return $folderPaths
    }
}
