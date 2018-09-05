Function Show-FileSaveBox {
    <#
    .SYNOPSIS
        Select file to save.
    .DESCRIPTION
        This function leverages SaveFileDialog to allow the user to select a file.

        For more information visit: https://msdn.microsoft.com/en-us/library/system.windows.forms.SaveFileDialog(v=vs.110).aspx
    .PARAMETER Title
        Title of the window.
    .PARAMETER InitialDirectory
        Initial directory that will be shown. If not provided, will default to the current user profile.
    .PARAMETER Filter
        File filter(s) to be used by SaveFileDialog.

        If ommited, it will default to:
            "All files (*.*)|*.*"

        Other examples:
            "Text files (*.txt)|*.txt|All files (*.*)|*.*"
            "Image Files(*.BMP;*.JPG;*.GIF)|*.BMP;*.JPG;*.GIF|All files (*.*)|*.*"

        For more information visit: https://msdn.microsoft.com/en-us/library/system.windows.forms.filedialog.filter(v=vs.110).aspx
    .PARAMETER FilterIndex
        Which filter is selected by default. If ommited, it will default to 1.

        For more information visit: https://msdn.microsoft.com/en-us/library/system.windows.forms.filedialog.filterindex(v=vs.110).aspx
    .OUTPUTS
        [System.IO.FileInfo] containing selected file.
    .EXAMPLE
        Show-FileSaveBox "Select a File"
        Mode                LastWriteTime         Length Name
        ----                -------------         ------ ----
        -a----        7/10/2018  11:22 AM            354 SelectedDocument.pdf
    #>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Title,
        [Parameter(Position = 1)]
        [string] $InitialDirectory,
        [string] $Filter = "All files (*.*)|*.*",
        [int] $FilterIndex = 1
    )
    process {
        try {
            # create a SaveFileDialog
            $form = New-Object System.Windows.Forms.SaveFileDialog
            $form.Title = $Title
            $form.Filter = $Filter
            $form.FilterIndex = $FilterIndex
            # if the InitialDirectory is provided, use it, otherwise default to the current user profile
            if (![string]::IsNullOrWhiteSpace($InitialDirectory)) {
                $form.InitialDirectory = $InitialDirectory
            } else {
                $form.InitialDirectory = $env:USERPROFILE
            }
            # show the form, if anything but OK is returned, throw an exception, otherwise return the selected file(s)
            if ($form.ShowDialog((Get-ScriptWindowHandle -IWin32Window)) -eq [Windows.Forms.DialogResult]::OK) {
                return (New-Object IO.FileInfo $form.Filename)
            } else {
                throw "Aborted file selection!"
            }
        } catch {
            if (!$PSitem.InvocationInfo.MyCommand) {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        (New-Object "$($PSItem.Exception.GetType().FullName)" (
                                "$($PSCmdlet.MyInvocation.MyCommand.Name) : $($PSItem.Exception.Message)`n`nStackTrace:`n$($PSItem.ScriptStackTrace)`n"
                            )),
                        $PSItem.FullyQualifiedErrorId,
                        $PSItem.CategoryInfo.Category,
                        $PSItem.TargetObject
                    )
                )
            } else { $PSCmdlet.ThrowTerminatingError($PSitem) }
        }
    }
} # Show-FileSaveBox
