Function Get-ScriptWindowHandle {
    <#
    .SYNOPSIS
        Get the window handle of what is spawning the script.
    .DESCRIPTION
        Starting with the Process ID of the PowerShell.exe instance executing the script, this function traverses the process parent chain until it finds a process with a Window Handle.
    .PARAMETER IWin32Window
        Returns NativeWindow instead of IntPtr.
    .OUTPUTS
        [System.IntPtr] by default.
        [System.Windows.Forms.NativeWindow] if using IWin32Window switch.
    .EXAMPLE
        Get-ScriptWindowHandle
        15338922
    .EXAMPLE
        Get-ScriptWindowHandle -IWin32Window
        Handle
        ------
        658874
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([System.IntPtr], ParameterSetName = "Default")]
    [OutputType([System.Windows.Forms.NativeWindow], ParameterSetName = "IWin32Window")]
    param(
        [Parameter(ParameterSetName = "IWin32Window")]
        [switch] $IWin32Window
    )
    process {
        try {
            # get PID of shell and attempt to get the MainWindowHandle
            $ppID = $PID
            $windowHandle = (Get-process -Id $ppID).MainWindowHandle
            # as long as ppID is not null and windowHandle is le 0, work up the process chain till windowHandle is gt 0
            while ($null -ne $ppID -and $windowHandle.ToInt32() -le 0) {
                $ppID = (Get-CimInstance Win32_Process -Filter "ProcessID = $ppID").ParentProcessId
                $windowHandle = (Get-process -Id $ppID).MainWindowHandle
            }
            # return the windowHandle in appropriate format
            if ($IWin32Window) {
                $nativeWindow = New-Object System.Windows.Forms.NativeWindow
                $nativeWindow.AssignHandle($windowHandle)
                return $nativeWindow
            } else {
                return $windowHandle
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
} # Get-ScriptWindowHandle
