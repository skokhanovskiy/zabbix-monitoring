<#
.SYNOPSIS 
    Creates an item of zabbix data
.DESCRIPTION
    The New-ZabbixData function creates a hashtable with required information for sending to zabbix.
.PARAMETER HostName
    Specifies the monitored host name as registered in Zabbix frontend.
.PARAMETER Key
    Specifies the key of zabbix item.
.PARAMETER HostName
    Specifies the value of zabbix item.
.PARAMETER TimeStamp
    Specifies the timestamp for a value.
.EXAMPLE
    New-ZabbixData 'MYSQL1' 'mysql.queries' '347.4' | Send-ZabbixData 'zabbix'

    The New-ZabbixData function creates the zabbix data item with '347.4' as value for 'mysql.queries' key in 'MYSQL1' host. The Send-ZabbixData function sends this value to zabbix server with name 'zabbix'.
.INPUTS
    System.String
.OUTPUTS
    System.Object.Hashtable
.LINKS
    Send-ZabbixData
.NOTES
    The resulting hashtable will be converted to JSON as is before sending it to the zabbix server.

    https://www.zabbix.org/wiki/Docs/protocols/zabbix_sender/2.0
#>
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