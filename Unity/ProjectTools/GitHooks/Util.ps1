
class Util
{
    static [string[]]GetGitIgnoredFilePaths()
    {
        $PrevLocation = Get-Location
        Set-Location "$PSScriptRoot/../../../"

        $Files = @(git ls-files -i -o --exclude-standard)

        Set-Location $PrevLocation
        return $Files
    }
    
    static [string[]]FindUnityMetaFolders()
    {
        return @(
            "$PSScriptRoot/ProjectUnity/Assets/"
            "$PSScriptRoot/ProjectShared/Company.Project.Package/"
        )
    }
}
