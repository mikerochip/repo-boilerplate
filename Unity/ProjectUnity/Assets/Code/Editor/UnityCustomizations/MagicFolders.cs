using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace Company.ProjectUnity.Editor.UnityCustomizations
{
    public static class MagicFolders
    {
        [MenuItem("Window/Magic Folders/Working Directory")]
        private static void OpenWorkingDirectory()
        {
            var dirPath = Directory.GetCurrentDirectory();
            EditorUtility.RevealInFinder(dirPath);
        }

        [MenuItem("Window/Magic Folders/Persistent Data")]
        private static void OpenPersistentData()
        {
            var dirPath = Application.persistentDataPath;
            EditorUtility.RevealInFinder(dirPath);
        }

        [MenuItem("Window/Magic Folders/Editor Logs")]
        private static void OpenEditorLogs()
        {
            // https://docs.unity3d.com/Manual/LogFiles.html
            var dirPath = Application.platform switch
            {
                RuntimePlatform.LinuxEditor =>
                    @"~/.config/unity3d",
                RuntimePlatform.OSXEditor =>
                    @"~/Library/Logs/Unity",
                RuntimePlatform.WindowsEditor => System.Environment.ExpandEnvironmentVariables(
                    @"%LOCALAPPDATA%\Unity\Editor"),
                _ => throw new NotImplementedException($"Unknown Editor Logs folder for {Application.platform}"),
            };
            EditorUtility.RevealInFinder(dirPath);
        }

        [MenuItem("Window/Magic Folders/Player Logs")]
        private static void OpenPlayerLogs()
        {
            // https://docs.unity3d.com/Manual/LogFiles.html
            var dirPath = Application.platform switch
            {
                RuntimePlatform.LinuxEditor =>
                    @$"~/.config/unity3d/{Application.companyName}/{Application.productName}/Player.log",
                RuntimePlatform.OSXEditor =>
                    @$"~/Library/Logs/{Application.companyName}/{Application.productName}/Player.log",
                RuntimePlatform.WindowsEditor => System.Environment.ExpandEnvironmentVariables(
                    @$"%USERPROFILE%\AppData\LocalLow\{Application.companyName}\{Application.productName}\Player.log"),
                _ => throw new NotImplementedException($"Unknown Player Logs folder for {Application.platform}"),
            };
            EditorUtility.RevealInFinder(dirPath);
        }

        [MenuItem("Window/Magic Folders/Hub Logs")]
        private static void OpenHubLogs()
        {
            // https://docs.unity3d.com/Manual/LogFiles.html
            var dirPath = Application.platform switch
            {
                RuntimePlatform.LinuxEditor =>
                    @"~/.config/UnityHub/logs/Player.log",
                RuntimePlatform.OSXEditor =>
                    @"~/Library/Application Support/UnityHub/logs/info-log.json",
                RuntimePlatform.WindowsEditor => System.Environment.ExpandEnvironmentVariables(
                    @"%USERPROFILE%\AppData\Roaming\UnityHub\logs\info-log.json"),
                _ => throw new NotImplementedException($"Unknown Hub Logs folder for {Application.platform}"),
            };
            EditorUtility.RevealInFinder(dirPath);
        }

        [MenuItem("Window/Magic Folders/UPM Global Cache")]
        private static void OpenUpmGlobalCache()
        {
            // https://docs.unity3d.com/Manual/upm-cache.html
            var dirPath = Application.platform switch
            {
                RuntimePlatform.LinuxEditor =>
                    @"~/.config/unity3d/cache",
                RuntimePlatform.OSXEditor =>
                    @"~/Library/Unity/cache",
                RuntimePlatform.WindowsEditor => System.Environment.ExpandEnvironmentVariables(GetWindowsPath()),
                _ => throw new NotImplementedException($"Unknown UPM global cache folder for {Application.platform}"),
            };
            EditorUtility.RevealInFinder(dirPath);

            string GetWindowsPath()
            {
                using var identity = System.Security.Principal.WindowsIdentity.GetCurrent();
                return identity.IsSystem
                    ? @"%ALLUSERSPROFILE%\Unity\cache"
                    : @"%LOCALAPPDATA%\Unity\cache";
            }
        }

        [MenuItem("Window/Magic Folders/Asset Store Package Cache")]
        private static void OpenAssetStorePackageCache()
        {
            // https://docs.unity3d.com/Manual/AssetStorePackages.html
            var dirPath = Application.platform switch
            {
                RuntimePlatform.LinuxEditor =>
                    @"~/.local/share/unity3d/Asset Store-5.x",
                RuntimePlatform.OSXEditor =>
                    @"~/Library/Unity/Asset Store-5.x",
                RuntimePlatform.WindowsEditor => System.Environment.ExpandEnvironmentVariables(
                    @"%APPDATA%\Unity\Asset Store-5.x"),
                _ => throw new NotImplementedException($"Unknown Asset Store cache folder for {Application.platform}"),
            };
            EditorUtility.RevealInFinder(dirPath);
        }
    }
}
