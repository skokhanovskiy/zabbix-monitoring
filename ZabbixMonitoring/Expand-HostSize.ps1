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