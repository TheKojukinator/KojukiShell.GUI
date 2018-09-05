# enable StrictMode for this module
Set-StrictMode -Version Latest

# get public and private functions
$public = @(Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue)
$private = @(Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue)

# dot source all the functions
foreach ($function in @($public + $private)) {
    try {
        . $function.FullName
    } catch {
        Write-Error -Message "KojukiShell.GUI : Failed to import $($function.FullName): $PSItem"
    }
}

# export only the public functions as module members
Export-ModuleMember -Function $public.BaseName
