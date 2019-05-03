Function Show-InputBox {
    <#
    .SYNOPSIS
        Display an Input Box.
    .DESCRIPTION
        This function leverages [System.Windows.Forms.Form] to generate and display an Input Box with custom parameters. Depending on the Multi switch, the Input Box can either be single or multi-line.
    .PARAMETER Title
        Title text.
    .PARAMETER Message
        Message text.
    .PARAMETER DefaultResponse
        Default Input Box text.
    .PARAMETER Multi
        Use multi-line Input Box.
    .PARAMETER AcceptReturn
        Enable RETURN in a multi-line Input Box.
    .PARAMETER AcceptTab
        Enable TAB in a multi-line Input Box.
    .PARAMETER WordWrap
        Enable WordWrap in a multi-line Input Box.
    .PARAMETER DontSplit
        Return a single string from a multi-line Input Box. Default is to split lines in to an array.
    .OUTPUTS
        [String] or [String[]] with user text.
    .EXAMPLE
        Show-InputBox "Data Request" "Please provide some input:"
        This is the text the user provided
    .EXAMPLE
        Show-InputBox "Data Request" "Please provide some input:" -Multi -AcceptReturn
        This
        is the
        input
        the user provided
        on multiple
        lines!
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([String], [String[]])]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Title,
        [Parameter(Position = 1, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,
        [Parameter(Position = 2)]
        [string] $DefaultResponse = "",
        [Parameter(ParameterSetName = "Multi")]
        [switch] $Multi,
        [Parameter(ParameterSetName = "Multi")]
        [switch] $AcceptReturn,
        [Parameter(ParameterSetName = "Multi")]
        [switch] $AcceptTab,
        [Parameter(ParameterSetName = "Multi")]
        [switch] $WordWrap,
        [Parameter(ParameterSetName = "Multi")]
        [switch] $DontSplit
    )
    begin {
        Add-Type -AssemblyName System.Drawing
        # if using Multi, we'll need to shift UI elements down for a taller input box
        if ($Multi) {
            $multiShift = 10
        } else {
            $multiShift = 1
        }
    }
    process {
        try {
            #region create the main window
            $form = New-Object System.Windows.Forms.Form
            $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
            $form.Size = New-Object System.Drawing.Point(64, 64)
            $form.AutoSize = $true
            $form.Text = $Title
            #endregion

            #region create and attach the Text label
            $lblText = New-Object System.Windows.Forms.Label
            $lblText.Location = New-Object System.Drawing.Point(8, 8)
            $lblText.Margin = New-Object System.Windows.Forms.Padding(8)
            $lblText.AutoSize = $true
            $lblText.Text = $Message
            $form.Controls.Add($lblText)
            #endregion

            #region create and attach the Input textbox
            $txtInput = New-Object System.Windows.Forms.TextBox
            $txtInput.Location = New-Object System.Drawing.Point(8, 48)
            $txtInput.Margin = New-Object System.Windows.Forms.Padding(8)
            $txtInput.Width = 640
            $txtInput.AutoSize = $true
            # if doing multi-line, set relevant properties
            if ($Multi) {
                $txtInput.Multiline = $true
                $txtInput.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
                $txtInput.AcceptsReturn = $AcceptReturn
                $txtInput.AcceptsTab = $AcceptTab
                $txtInput.WordWrap = $WordWrap
                # grow the input box vertically to better accomodate multi-line input
                $txtInput.Height *= $multiShift
            }
            $txtInput.Text = $DefaultResponse
            $form.Controls.Add($txtInput)
            #endregion

            #region create and attach the OK button
            $btnOK = New-Object System.Windows.Forms.Button
            $btnOK.Margin = New-Object System.Windows.Forms.Padding(8)
            $btnOK.Location = New-Object System.Drawing.Point($btnOK.Margin.Left, ($txtInput.Location.Y + $txtInput.Height + $txtInput.Margin.Bottom + $btnOK.Margin.Top))
            $btnOK.Text = 'OK'
            $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.AcceptButton = $btnOK
            $form.Controls.Add($btnOK)
            #endregion

            #region create and attach the Cancel button
            $btnCancel = New-Object System.Windows.Forms.Button
            $btnCancel.Margin = New-Object System.Windows.Forms.Padding(8)
            $btnCancel.Location = New-Object System.Drawing.Point(($btnOK.Location.X + $btnOK.Width + $btnOK.Margin.Right + $btnCancel.Margin.Left), $btnOK.Location.Y)
            $btnCancel.Text = 'Cancel'
            $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $form.CancelButton = $btnCancel
            $form.Controls.Add($btnCancel)
            #endregion

            # hide the resizing of the form by user
            $form.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide
            $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

            # make the window the top-most window
            $form.Topmost = $true

            # activate the form and focus on the Input textbox
            $form.Add_Shown( {$txtInput.Select()})

            # show the form, and if it is closed with OK, return the Input textbox text
            if ($form.ShowDialog((Get-ScriptWindowHandle -IWin32Window)) -eq [System.Windows.Forms.DialogResult]::OK) {
                if ([string]::IsNullOrWhiteSpace($txtInput.Text)) {
                    throw "InputBox is blank!"
                } else {
                    if ($Multi -and !$DontSplit) {
                        return $txtInput.Text -split "`r`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                    } else {
                        return $txtInput.Text
                    }
                }
            } else {
                throw "Aborted text input!"
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
} # Show-InputBox
