function Get-UnixDate
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [DateTime]
        $Date
    )

    begin
    {
        $UnixTimeFormat = '%s'
    }

    process
    {
        if (-not $Date)
        {
            $Date = Get-Date
        }
        foreach ($D in $Date)
        {
            [Int] [Double]::Parse((Get-Date -Date $D -UFormat $UnixTimeFormat))
        }
    }
}