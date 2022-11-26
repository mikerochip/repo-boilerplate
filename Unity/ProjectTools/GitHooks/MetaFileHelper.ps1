
class MetaFileHelper {
    static [string]FindGitPath([string]$path) {
        while ($path) {
            $gitPath = "$path/.git"
            if (Test-Path $gitPath -PathType Container) {
                return $gitPath
            }
            $path = [System.IO.Directory]::GetParent($path)
        }
        return $null
    }

    <#
    .SYNOPSIS
    Returns full paths of all folders that include meta files for the Unity project.
    .INPUTS
    The Unity project path.
    .DESCRIPTION
    Includes the 'Assets' folder and embedded package folders. Also includes local packages,
    but only if they are in the same repo as the Unity project.
    #>
    static [string[]]GetMetaFileFolderPaths([string]$unityProjectPath) {
        Write-Verbose 'GetMetaFileFolderPaths'
        Write-Verbose "  unityProjectPath `"$unityProjectPath`""

        $projectGitPath = [MetaFileHelper]::FindGitPath($unityProjectPath)
        Write-Verbose "  projectGitPath `"$projectGitPath`""

        # Unity adds meta files to:
        # 1. "Assets/"
        # 2. Embedded packages in "Packages/"
        # 3. Local packages from "Packages/manifest.json"
        $dirPaths = New-Object System.Collections.Generic.List[string]
        
        Write-Verbose "  Add Assets"
        $dirPaths.Add([System.IO.Path]::GetFullPath('Assets', $unityProjectPath))

        Write-Verbose "  Check Embedded Packages"
        foreach ($item in Get-ChildItem "Packages" -Directory) {
            Write-Verbose "  Check `"$item`""
            Write-Verbose "    Test `"$item/package.json`""
            if (Test-Path "$item/package.json" -PathType Leaf) {
                Write-Verbose "    Include"
                $dirPaths.Add($item.FullName)
            } else {
                Write-Verbose "    Skip: No `"package.json`""
            }
        }

        $prevWorkingDirectory = [System.IO.Directory]::GetCurrentDirectory()
        [System.IO.Directory]::SetCurrentDirectory("$unityProjectPath/Packages")

        Write-Verbose "  Check Local Packages"
        $manifest = Get-Content 'Packages/manifest.json' | ConvertFrom-Json
        foreach ($property in $manifest.dependencies.PSObject.Properties) {
            if ($property.Value -notlike 'file:*') {
                continue
            }

            $path = $property.Value -replace '^file:*', ''
            Write-Verbose "  Check `"$path`""
            
            $path = [System.IO.Path]::GetFullPath($path)
            Write-Verbose "    Path `"$path`""

            if ($dirPaths.Contains($path)) {
                Write-Verbose "    Skip: Duplicate"
                continue
            }

            $dependencyGitPath = [MetaFileHelper]::FindGitPath($path)
            Write-Verbose "    GitPath `"$dependencyGitPath`""

            if ($projectGitPath -ne $dependencyGitPath) {
                Write-Verbose "    Skip: DifferentGitPath"
                continue
            }
            
            Write-Verbose "    Include"
            $dirPaths.Add($path)
        }
        [System.IO.Directory]::SetCurrentDirectory($prevWorkingDirectory)

        return $dirPaths.ToArray()
    }
}
