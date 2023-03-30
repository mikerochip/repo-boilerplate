
class MetaFileHelper {
    # see https://docs.unity3d.com/Manual/SpecialFolders.html
    static [bool]IsUnityHiddenItem([System.IO.FileSystemInfo]$item) {
        $name = $item.Name

        if ($item.Attributes -band [System.IO.FileAttributes]::Hidden) {
            return $true
        }
        if ($name -like '.*') {
            return $true
        }
        if ($name -like '*~') {
            return $true
        }
        if ($name -like 'cvs') {
            return $true
        }
        if ($name -like '*.tmp') {
            return $true
        }

        return $false
    }

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
        
        $assetsPath = [System.IO.Path]::GetFullPath('Assets', $unityProjectPath)
        Write-Verbose "  Add $assetsPath"
        $dirPaths.Add($assetsPath)

        $prevLocation = Get-Location
        $prevWorkingDirectory = [System.IO.Directory]::GetCurrentDirectory()
        
        $newWorkingDirectory = [System.IO.Path]::Combine($unityProjectPath, "Packages")
        Write-Verbose "  Set Dir `"$newWorkingDirectory`""
        [System.IO.Directory]::SetCurrentDirectory($newWorkingDirectory)
        Set-Location $newWorkingDirectory

        Write-Verbose "  Check Embedded Packages"
        foreach ($item in Get-ChildItem -Directory) {
            Write-Verbose "  Check `"$item`""
            Write-Verbose "    Test `"$item/package.json`""
            if (Test-Path "$item/package.json" -PathType Leaf) {
                Write-Verbose "    Add"
                $dirPaths.Add($item.FullName)
            } else {
                Write-Verbose "    Skip: No `"package.json`""
            }
        }

        Write-Verbose "  Check Local Packages"
        $manifest = Get-Content 'manifest.json' | ConvertFrom-Json
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
        Set-Location $prevLocation

        return $dirPaths.ToArray()
    }

    <#
    .SYNOPSIS
    Returns all full file paths in current directory that git is aware of.

    .PARAMETER basePath
    Path to start gathering Git files.

    .PARAMETER gitFolderTable
    Will be filled in with all parent folders and subfolders of Git files.

    .DESCRIPTION
    Runs git ls-files twice - once to catch all files and once more to remove deleted files.
    Returns the array resulting from removing the deleted files from all files.
    #>
    static [string[]]GetGitTrackedFullPaths([string]$basePath, [hashtable]$gitFolderTable) {
        Write-Verbose "GetGitTrackedFullPaths `"$basePath`""

        # the PowerShell Location APIs are what commands base their paths on
        $prevLocation = Get-Location
        Set-Location $basePath
        $paths = @(git ls-files --others --cached --exclude-standard)
        $deletedPaths = @(git ls-files --deleted --exclude-standard)
        $paths = @($paths | Where-Object { $PSItem -notin $deletedPaths })
        Set-Location $prevLocation

        # the .Net APIs affect working directory paths
        $workingDirectory = [System.IO.Directory]::GetCurrentDirectory()
        [System.IO.Directory]::SetCurrentDirectory($basePath)
        
        for ($i = 0; $i -lt $paths.Length; ++$i) {
            $path = $paths[$i]
            $fullPath = [System.IO.Path]::GetFullPath($path)
            Write-Verbose "  Path `"$fullPath`""
            $paths[$i] = $fullPath

            if ($null -ne $gitFolderTable) {
                $path = [System.IO.Directory]::GetParent($path).FullName
                while ($path -ne $basePath) {
                    $gitFolderTable[$path] = $true
                    $path = [System.IO.Directory]::GetParent($path).FullName
                }
            }
        }

        [System.IO.Directory]::SetCurrentDirectory($workingDirectory)

        return $paths
    }
    static [string[]]GetGitTrackedFullPaths([string]$basePath) {
        return [MetaFileHelper]::GetGitTrackedFullPaths($basePath, $null)
    }
}
