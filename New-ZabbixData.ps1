function New-ZabbixData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [String]
        $HostName,

        [Parameter(Mandatory = $true, Position = 1)]
        [String]
        $Key,

        [Parameter(Mandatory = $true, Position = 2)]
        [String]
        $Value,

        [Parameter(Position = 3)]
        [DateTime]
        $Timestamp
    )

    $Item = @{
        $ZabbixJsonHost = $HostName
        $ZabbixJsonKey = $Key
        $ZabbixJsonValue = $Value
    }
    if ($Timestamp)
    {
        $Item[$ZabbixJsonTimestamp] = $Timestamp | Get-UnixDate
    }

    return $Item
}