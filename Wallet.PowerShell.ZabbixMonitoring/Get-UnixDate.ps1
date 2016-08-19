<#
.SYNOPSIS 
    Gets the current unix time
.DESCRIPTION
    The Get-UnixDate function get current date and time in unix time format.
.PARAMETER Date
    Specifies the date to convert to unix time format.
.EXAMPLE
    Get-UnixDate

    Gets the current unix time value.
.EXAMPLE
    Get-Date -Year (Get-Date).Year -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0 | Get-UnixDate

    Gets the unix time of last new year.
.INPUTS
    System.DateTime
.OUTPUTS
    System.Int32
#>
function Get-UnixDate
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [DateTime[]]
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