<#
.SYNOPSIS 
    Expands console buffer size
.DESCRIPTION
    The Expand-HostSize function change width and height of buffer for the host of console.

    This can be useful to avoid newline characters in the long text console output.
.PARAMETER Width
    Specifies the width of the console buffer. Default value is 32766, maximal allowed.
.PARAMETER Height
    Specifies the height of the console buffer. Default value is current buffer height.
.EXAMPLE
    Expand-HostSIze
    
    Expands console buffer width to the maximal allowed value.
#>
function Expand-HostSize
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0)]
        [Int]
        $Width = 32766,

        [Parameter(Position = 1)]
        [Int]
        $Height = $Host.UI.RawUI.BufferSize.Width
    )

    if (-not $Height)
    {
        $Height = $Host.UI.RawUI.BufferSize.Height
    }

    $Host.UI.RawUI.BufferSize = New-Object -TypeName Management.Automation.Host.Size -ArgumentList $Width, $Height
}