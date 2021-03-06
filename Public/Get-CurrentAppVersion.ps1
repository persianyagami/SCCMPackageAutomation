function Get-CurrentAppVersion {
    <#
.SYNOPSIS

Gets the current app version for a given app
.DESCRIPTION

Gets the current app package version for a given app. Uses the Get-PSADTAppVersion function to get the version
.PARAMETER App

The App you want the version of.
.EXAMPLE

Get-CurrentAppVersion -App Firefox
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
            HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip', 'BigFix', 'Chrome', 'CutePDF', 'Etcher', 'Firefox', 'Flash', 'GIMP', 'Git', 'Insync', 'Notepad++', 'OpenJDK', 'Putty', 'Reader', 'Receiver', 'SoapUI', 'VLC', 'VSCode', 'WinSCP', 'WireShark', IgnoreCase = $true)]
        $App
    )

    begin {
        $App = $App.ToLower()

        Mount-PackageShare
    }

    process {
        $App = $App.ToLower()
        # Get-ChildItem has trouble working with UNC paths from the $SCCM_Site: drive. That is why I map a $SCCM_Share_Letter drive
        $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
        # Gets the most recent folder for a given app, split it up into multiple lines to make it easier to read and debug
        $RootAppPath = $($MaintainedApps | Where-Object { $_.Name -eq $App }).RootApplicationPath
        $LatestApplicationPath = "$($SCCM_Share_Letter):\" + $RootAppPath.Substring($count) | Get-ChildItem
        $LatestApplicationPath = $LatestApplicationPath | Where-Object { $_.Name -match $SCCM_SourceFolderRegex }
        $LatestApplicationPath = $LatestApplicationPath | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
        $CurrentAppVersion = Get-PSADTAppVersion -PackageRootFolder "$($LatestApplicationPath.Fullname)"
        if ($app -eq "reader") {
            return $CurrentAppVersion #readers versions often have leading 0s
        }
        else {
            return [version]$CurrentAppVersion
        }
    }
}