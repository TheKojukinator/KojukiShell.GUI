@{
    ModuleVersion     = '0.1'
    Author            = 'Stephen Kojoukhine'
    Copyright         = '(c) 2018 Stephen Kojoukhine. All rights reserved.'
    GUID              = '69732ccf-3903-4941-94b7-cc636ba2bb85'
    PowerShellVersion = '5.1'
    NestedModules     = @(
        '.\functions\Get-ScriptWindowHandle.ps1',
        '.\functions\Show-FileOpenBox.ps1',
        '.\functions\Show-FileSaveBox.ps1',
        '.\functions\Show-FolderOpenBox.ps1',
        '.\functions\Show-InputBox.ps1',
        '.\functions\Show-MessageBox.ps1'
    )
    FunctionsToExport = @('*')
}
