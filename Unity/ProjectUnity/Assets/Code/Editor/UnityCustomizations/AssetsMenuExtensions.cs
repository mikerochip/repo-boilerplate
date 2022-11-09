using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace Company.ProjectUnity.Editor.UnityCustomizations
{
    public static class AssetsMenuExtensions
    {
        [MenuItem("Assets/Copy Full Path", isValidateFunction: true)]
        private static bool ValidateCopyFullPath() =>
            Selection.GetFiltered<Object>(SelectionMode.DeepAssets).Length > 0;
        
        [MenuItem("Assets/Copy Full Path", priority = 20_000)]
        private static void CopyFullPath()
        {
            var builder = new StringBuilder();
            foreach (var obj in Selection.GetFiltered<Object>(SelectionMode.DeepAssets))
            {
                var assetPath = AssetDatabase.GetAssetPath(obj);
                var fullPath = Path.GetFullPath(assetPath);
                builder.AppendLine(fullPath);
            }
            
            // feels better with one element to not have a trailing newline
            if (Selection.assetGUIDs.Length == 1)
                builder.Remove(builder.Length - 1, 1);

            var paths = builder.ToString();
            EditorGUIUtility.systemCopyBuffer = paths;
            Debug.Log(paths);
        }
        
        [MenuItem("Assets/Copy Guid", isValidateFunction: true)]
        private static bool ValidateCopyGuid() =>
            Selection.GetFiltered<Object>(SelectionMode.DeepAssets).Length > 0;
        
        [MenuItem("Assets/Copy Guid", priority = 20_000)]
        private static void CopyGuid()
        {
            var builder = new StringBuilder();
            foreach (var obj in Selection.GetFiltered<Object>(SelectionMode.DeepAssets))
            {
                var assetPath = AssetDatabase.GetAssetPath(obj);
                var guid = AssetDatabase.AssetPathToGUID(assetPath);
                builder.AppendLine(guid);
            }
            
            // feels better with one element to not have a trailing newline
            if (Selection.assetGUIDs.Length == 1)
                builder.Remove(builder.Length - 1, 1);

            var guids = builder.ToString();
            EditorGUIUtility.systemCopyBuffer = guids;
            Debug.Log(guids);
        }
        
        [MenuItem("Assets/Force Save Selected", isValidateFunction: true)]
        private static bool ValidateForceSaveSelected() =>
            Selection.GetFiltered<Object>(SelectionMode.DeepAssets | SelectionMode.Editable).Length > 0;
        
        [MenuItem("Assets/Force Save Selected", priority = 20_000)]
        private static void ForceSaveSelected()
        {
            foreach (var obj in Selection.GetFiltered<Object>(SelectionMode.DeepAssets | SelectionMode.Editable))
            {
                var assetPath = AssetDatabase.GetAssetPath(obj);
                var asset = AssetDatabase.LoadMainAssetAtPath(assetPath);
                EditorUtility.SetDirty(asset);
            }
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }
}
