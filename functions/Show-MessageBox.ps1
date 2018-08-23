# load the necessary assembly
Add-Type -AssemblyName System.Windows.Forms
Function Show-MessageBox {
    <#
    .SYNOPSIS
    Display a Message Box.

    .DESCRIPTION
    This function leverages [System.Windows.Forms.MessageBox] to display a Message Box with custom parameters.

    .PARAMETER Title
    Title text.

    .PARAMETER Message
    Message text.

    .PARAMETER Buttons
    One of [System.Windows.Forms.MessageBoxButtons] values to determine the visible button(s):
        OK, OKCancel, AbortRetryIgnore, YesNoCancel, YesNo, RetryCancel

    .PARAMETER Icon
    One of [System.Windows.Forms.MessageBoxIcon] values to determine the visible icon:
        None, Hand, Hand, Hand, Question, Warning, Warning, Asterisk, Asterisk

    .PARAMETER DefaultButton
    One of [System.Windows.Forms.MessageBoxDefaultButton] values to determine the default selected button:
        Button1, Button2, Button3

    .OUTPUTS
    [System.Windows.Forms.DialogResult] value, one of {None, OK, Cancel, Abort, Retry, Ignore, Yes, No}

    .EXAMPLE
    Show-MessageBox "Notificaiton" "Hey, you're awesome!"
    OK

    .EXAMPLE
    Show-MessageBox "Uh Oh!" "Something went wrong!" AbortRetryIgnore Asterisk
    Retry
    #>
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.DialogResult])]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Title,
        [Parameter(Position = 1, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,
        [Parameter(Position = 2)]
        [System.Windows.Forms.MessageBoxButtons] $Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
        [Parameter(Position = 3)]
        [System.Windows.Forms.MessageBoxIcon] $Icon = [System.Windows.Forms.MessageBoxIcon]::None,
        [Parameter(Position = 4)]
        [System.Windows.Forms.MessageBoxDefaultButton] $DefaultButton = [System.Windows.Forms.MessageBoxDefaultButton]::Button1
    )
    Process {
        try {
            # show message box with specified parameters and return the returned value
            # the first parameter generates a IWin32Window to use as the parent, to make sure the window spawns as the top-most
            return [System.Windows.Forms.MessageBox]::Show((Get-ScriptWindowHandle -IWin32Window), $Message, $Title, $Buttons, $Icon, $DefaultButton)
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
} # Show-MessageBox
