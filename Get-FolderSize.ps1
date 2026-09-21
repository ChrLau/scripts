# PowerShell script to list the size (in GB/MB) of directories, similar to the Linux "du" command
# Source:
# 
# In orde to add this function to our PowerShell profile, do:
# 1. New-Item -ItemType File -Path $PROFILE -Force
# 2. notepad $PROFILE
# 3. Enter the function below
function Get-FolderSize {
    param([string]$Path = ".")
    Get-ChildItem $Path -Directory | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            Folder = $_.Name
            "Size(MB)" = "{0:N2}" -f ($size / 1MB)
            "Size(GB)" = "{0:N2}" -f ($size / 1GB)
        }
    } | Sort-Object { [double]($_."Size(MB)") } -Descending | Format-Table -AutoSize
}
