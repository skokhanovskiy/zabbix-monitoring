function New-ZabbixData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $HostName,

        [Parameter(Position = 1, Mandatory = $true)]
        [String]
        $Key,

        [Parameter(Position = 2, ValueFromPipeLine = $true)]
        [String[]]
        $Value,

        [Parameter(Position = 3)]
        [DateTime]
        $Timestamp
    )

    process
    {
        if ($Value)
        {
            foreach ($V in $Value)
            {
                $Item = @{
                    $ZabbixJsonHost = $HostName
                    $ZabbixJsonKey = $Key
                    $ZabbixJsonValue = $V
                }
                if ($Timestamp)
                {
                    $Item[$ZabbixJsonTimestamp] = $Timestamp | Get-UnixDate
                }

                $Item
            }
        }
    }
}