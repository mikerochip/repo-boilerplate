
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

    static [bool]ShouldCheckChildItems([System.IO.FileSystemInfo]$item) {
        if (-not (Test-Path $item -PathType Container)) {
            return $false
        }

        $name = $item.Name

        # these are Mac app Bundles and Packages that Unity does not open, regardless of platform
        # see https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/AboutBundles/AboutBundles.html
        if ($name -like '*.bundle') {
            return $false
        }
        if ($name -like '*.app') {
            return $false
        }
        if ($name -like '*.framework') {
            return $false
        }
        if ($name -like '*.plugin') {
            return $false
        }

        return $true
    }

    static [string]FindGitPath([string]$path) {
        while ($path) {
            $gitPath = Join-Path $path '.git'
            if (Test-Path -LiteralPath $gitPath -PathType Container) {
                return $gitPath
            }
            $path = [System.IO.Directory]::GetParent($path)
        }
        return $null
    }

    static [string[]]ConvertGitLsResultToArray([string]$result) {
        if ($result) {
            return $result.Split("`0", [System.StringSplitOptions]::RemoveEmptyEntries)
        }
        return @()
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
        Write-Verbose "GetMetaFileFolderPaths"
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

        $packagesPath = Join-Path $unityProjectPath 'Packages'
        Write-Verbose "  Packages Path: $packagesPath"

        if (Test-Path -LiteralPath $packagesPath -PathType Container) {
            Write-Verbose "  Check Embedded Packages"
            foreach ($item in Get-ChildItem -LiteralPath $packagesPath -Directory) {
                $fullPath = $item.FullName
                Write-Verbose "  Check `"$fullPath`""

                $packageJsonPath = Join-Path $fullPath 'package.json'
                if (Test-Path -LiteralPath $packageJsonPath -PathType Leaf) {
                    Write-Verbose "    Add $fullPath"
                    $dirPaths.Add($fullPath)
                }
                else {
                    Write-Verbose "    Skip: No `"package.json`""
                }
            }

            $manifestPath = Join-Path $packagesPath 'manifest.json'
            if (Test-Path $manifestPath -PathType Leaf) {
                Write-Verbose "  Check Local Packages"
                $manifest = Get-Content $manifestPath | ConvertFrom-Json
                foreach ($property in $manifest.dependencies.PSObject.Properties) {
                    if ($property.Value -notlike 'file:*') {
                        continue
                    }

                    $path = $property.Value -replace '^file:*', ''
                    $fullPath = [System.IO.Path]::GetFullPath($path, $packagesPath)
                    Write-Verbose "  Check `"$fullPath`""

                    if ($dirPaths.Contains($fullPath)) {
                        Write-Verbose "    Skip: Duplicate"
                        continue
                    }

                    $dependencyGitPath = [MetaFileHelper]::FindGitPath($fullPath)
                    Write-Verbose "    GitPath `"$dependencyGitPath`""
                    if ($projectGitPath -ne $dependencyGitPath) {
                        Write-Verbose "    Skip: DifferentGitRepo"
                        continue
                    }

                    Write-Verbose "    Add $fullPath"
                    $dirPaths.Add($fullPath)
                }
            }
        }

        return $dirPaths.ToArray()
    }

    <#
    .SYNOPSIS
    Gather all Git-tracked file and folder full paths from the given directory.
    .PARAMETER basePath
    Path to start gathering Git files.
    .PARAMETER fileTable
    Will be filled in with all Git files.
    .PARAMETER folderTable
    Will be filled in with all parent folders and subfolders of Git files.
    .DESCRIPTION
    Runs git ls-files twice - once to catch all files and once more to remove deleted files.
    Uses the result to fill in a table of file full paths and a table of folder full paths.
    #>
    static GetGitTrackedFullPaths([string]$basePath, [hashtable]$fileTable, [hashtable]$folderTable) {
        Write-Verbose "GetGitTrackedFullPaths `"$basePath`""

        if ($null -eq $folderTable -and $null -eq $fileTable) {
            throw 'Either "$folderTable" or "$fileTable" must be specified'
        }

        # We have to specify -z otherwise Git will encode paths with escape sequences for
        # \ and " as well as use octal encoding(!) for Unicode characters. Also, -z means the
        # delimiter becomes the NULL character, and, for whatever reason, we can't combine
        # --format and --others, so we have to convert the output manually.
        # See https://stackoverflow.com/questions/40679814/unescaping-special-characters-in-git-output/40721503#40721503
        $listCmd = "git -C `"$basePath`" ls-files --others --cached --exclude-standard -z"
        $listDeletedCmd = "git -C `"$basePath`" ls-files --deleted --exclude-standard -z"
        $paths = [MetaFileHelper]::ConvertGitLsResultToArray((Invoke-Expression $listCmd))
        $deletedPaths = [MetaFileHelper]::ConvertGitLsResultToArray((Invoke-Expression $listDeletedCmd))

        $paths = $paths | Where-Object { $_ -notin $deletedPaths }

        foreach ($path in $paths) {
            $fullPath = [System.IO.Path]::GetFullPath($path, $basePath)

            if ($null -ne $fileTable) {
                Write-Verbose "  AddFile `"$fullPath`""
                $fileTable[$fullPath] = $true
            }

            if ($null -ne $folderTable) {
                $fullPath = [System.IO.Directory]::GetParent($fullPath).FullName
                while ($fullPath -ne $basePath -and !$folderTable.ContainsKey($fullPath)) {
                    Write-Verbose "  AddFolder `"$fullPath`""
                    $folderTable[$fullPath] = $true
                    $fullPath = [System.IO.Directory]::GetParent($fullPath).FullName
                }
            }
        }
    }
}
