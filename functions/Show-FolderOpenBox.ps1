# load the necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
# source: https://www.sapien.com/forums/viewtopic.php?t=8662
Add-Type -TypeDefinition @"
                using System;
                using System.Windows.Forms;
                using System.Reflection;
                namespace FolderSelect
                {
                    public class FolderSelectDialog
                    {
                        System.Windows.Forms.OpenFileDialog ofd = null;
                        public FolderSelectDialog()
                        {
                            ofd = new System.Windows.Forms.OpenFileDialog();
                            ofd.Filter = "Folders|\n";
                            ofd.AddExtension = false;
                            ofd.CheckFileExists = false;
                            ofd.DereferenceLinks = true;
                            ofd.Multiselect = false;
                        }
                        public string InitialDirectory
                        {
                            get { return ofd.InitialDirectory; }
                            set { ofd.InitialDirectory = value == null || value.Length == 0 ? Environment.CurrentDirectory : value; }
                        }
                        public string Title
                        {
                            get { return ofd.Title; }
                            set { ofd.Title = value == null ? "Select a folder" : value; }
                        }
                        public string FileName
                        {
                            get { return ofd.FileName; }
                        }
                        public bool ShowDialog()
                        {
                            return ShowDialog(IntPtr.Zero);
                        }
                        public bool ShowDialog(IntPtr hWndOwner)
                        {
                            bool flag = false;

                            if (Environment.OSVersion.Version.Major >= 6)
                            {
                                var r = new Reflector("System.Windows.Forms");
                                uint num = 0;
                                Type typeIFileDialog = r.GetType("FileDialogNative.IFileDialog");
                                object dialog = r.Call(ofd, "CreateVistaDialog");
                                r.Call(ofd, "OnBeforeVistaDialog", dialog);
                                uint options = (uint)r.CallAs(typeof(System.Windows.Forms.FileDialog), ofd, "GetOptions");
                                options |= (uint)r.GetEnum("FileDialogNative.FOS", "FOS_PICKFOLDERS");
                                r.CallAs(typeIFileDialog, dialog, "SetOptions", options);
                                object pfde = r.New("FileDialog.VistaDialogEvents", ofd);
                                object[] parameters = new object[] { pfde, num };
                                r.CallAs2(typeIFileDialog, dialog, "Advise", parameters);
                                num = (uint)parameters[1];
                                try
                                {
                                    int num2 = (int)r.CallAs(typeIFileDialog, dialog, "Show", hWndOwner);
                                    flag = 0 == num2;
                                }
                                finally
                                {
                                    r.CallAs(typeIFileDialog, dialog, "Unadvise", num);
                                    GC.KeepAlive(pfde);
                                }
                            }
                            else
                            {
                                var fbd = new FolderBrowserDialog();
                                fbd.Description = this.Title;
                                fbd.SelectedPath = this.InitialDirectory;
                                fbd.ShowNewFolderButton = false;
                                if (fbd.ShowDialog(new WindowWrapper(hWndOwner)) != DialogResult.OK) return false;
                                ofd.FileName = fbd.SelectedPath;
                                flag = true;
                            }
                            return flag;
                        }
                    }
                    public class WindowWrapper : System.Windows.Forms.IWin32Window
                    {
                        public WindowWrapper(IntPtr handle)
                        {
                            _hwnd = handle;
                        }
                        public IntPtr Handle
                        {
                            get { return _hwnd; }
                        }

                        private IntPtr _hwnd;
                    }
                    public class Reflector
                    {
                        string m_ns;
                        Assembly m_asmb;
                        public Reflector(string ns)
                            : this(ns, ns)
                        { }
                        public Reflector(string an, string ns)
                        {
                            m_ns = ns;
                            m_asmb = null;
                            foreach (AssemblyName aN in Assembly.GetExecutingAssembly().GetReferencedAssemblies())
                            {
                                if (aN.FullName.StartsWith(an))
                                {
                                    m_asmb = Assembly.Load(aN);
                                    break;
                                }
                            }
                        }
                        public Type GetType(string typeName)
                        {
                            Type type = null;
                            string[] names = typeName.Split('.');

                            if (names.Length > 0)
                                type = m_asmb.GetType(m_ns + "." + names[0]);

                            for (int i = 1; i < names.Length; ++i) {
                                type = type.GetNestedType(names[i], BindingFlags.NonPublic);
                            }
                            return type;
                        }
                        public object New(string name, params object[] parameters)
                        {
                            Type type = GetType(name);
                            ConstructorInfo[] ctorInfos = type.GetConstructors();
                            foreach (ConstructorInfo ci in ctorInfos) {
                                try {
                                    return ci.Invoke(parameters);
                                } catch { }
                            }

                            return null;
                        }
                        public object Call(object obj, string func, params object[] parameters)
                        {
                            return Call2(obj, func, parameters);
                        }
                        public object Call2(object obj, string func, object[] parameters)
                        {
                            return CallAs2(obj.GetType(), obj, func, parameters);
                        }
                        public object CallAs(Type type, object obj, string func, params object[] parameters)
                        {
                            return CallAs2(type, obj, func, parameters);
                        }
                        public object CallAs2(Type type, object obj, string func, object[] parameters) {
                            MethodInfo methInfo = type.GetMethod(func, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                            return methInfo.Invoke(obj, parameters);
                        }
                        public object Get(object obj, string prop)
                        {
                            return GetAs(obj.GetType(), obj, prop);
                        }
                        public object GetAs(Type type, object obj, string prop) {
                            PropertyInfo propInfo = type.GetProperty(prop, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                            return propInfo.GetValue(obj, null);
                        }
                        public object GetEnum(string typeName, string name) {
                            Type type = GetType(typeName);
                            FieldInfo fieldInfo = type.GetField(name);
                            return fieldInfo.GetValue(null);
                        }
                    }
                }
"@ -ReferencedAssemblies ('System.Windows.Forms', 'System.Reflection') -ErrorAction STOP
Function Show-FolderOpenBox {
    <#
    .SYNOPSIS
    Select a folder.

    .DESCRIPTION
    This function, by default, leverages FolderBrowserDialog to allow the user to select a folder. This dialog is very simple, but may be enough for many use cases.

    For more information visit: https://msdn.microsoft.com/en-us/library/system.windows.forms.folderbrowserdialog(v=vs.110).aspx

    If the Advanced switch is provided, this function instead leverages a custom OpenFileDialog modified exclusively for folder selection.

    .PARAMETER Title
    Title of the window.

    .PARAMETER Advanced
    Use the advanced folder selection form, resembling OpenFileDialog.

    .PARAMETER InitialDirectory
    Initial directory that will be shown. If not provided, will default to the current user profile.

    .OUTPUTS
    [string] containing selected path.

    .EXAMPLE
    Show-FolderOpenBox "Select a Folder"
    C:\Users\testUser\Documents\SelectedFolder

    .EXAMPLE
    Show-FolderOpenBox "Select a Folder" -Advanced -InitialDirectory "c:\initialDir"
    C:\initialDir\SelectedFolder
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([string])]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Title,
        [Parameter(ParameterSetName = "Advanced")]
        [switch] $Advanced,
        [Parameter(ParameterSetName = "Advanced")]
        [string] $InitialDirectory
    )
    Process {
        try {
            # if not using Advanced mode, use the pre-made [System.Windows.Forms.FolderBrowserDialog], otherwise use the custom [FolderSelect.FolderSelectDialog]
            if (!$Advanced) {
                # create a new FolderBrowserDialog
                $form = New-Object System.Windows.Forms.FolderBrowserDialog
                # set the title
                $form.Description = $Title
                # show the form, if anything but OK is returned, throw an exception, otherwise return the selected folder
                if ($form.ShowDialog((Get-ScriptWindowHandle -IWin32Window)) -eq [Windows.Forms.DialogResult]::OK) {
                    return $form.SelectedPath
                } else {
                    throw "Aborted folder selection!"
                }
            } else {
                # create a new custom FolderSelectDialog
                $form = New-Object FolderSelect.FolderSelectDialog
                # set the title
                $form.Title = $Title
                # if the InitialDirectory is provided, use it, otherwise default to the current user profile
                if (![string]::IsNullOrWhiteSpace($InitialDirectory)) {
                    $form.InitialDirectory = $InitialDirectory
                } else {
                    $form.InitialDirectory = $env:USERPROFILE
                }
                # show the form, if anything but OK is returned, throw an exception, otherwise return the selected folder
                if ($form.ShowDialog((Get-ScriptWindowHandle)) -eq [Windows.Forms.DialogResult]::OK) {
                    return $form.Filename
                } else {
                    throw "Aborted advanced folder selection!"
                }
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
} # Show-FolderOpenBox
