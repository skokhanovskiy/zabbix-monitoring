<#
.SYNOPSIS 
    Converts an object to a zabbix discovery JSON-formatted string
.DESCRIPTION
    The ConvertTo-ZabbixDiscoveryJson function converts object to a JSON-formatted string with information for zabbix low-level discovery (LLD).
.PARAMETER InputObject
    Specifies the objects to convert to convert to LLD JSON string.
.PARAMETER Property
    Specifies the property of the objects, the names and values which will be used to build LLD JSON. The default value is 'Name'.
.EXAMPLE
    Get-Service | Select-Object -Last 3 | ConvertTo-ZabbixDiscoveryJson
    {"data":[{"{#NAME}":"wuauserv"},{"{#NAME}":"wudfsvc"},{"{#NAME}":"WwanSvc"}]}

    Converts the names of the last 3 services in the zabbix low-level discovery JSON string.
.EXAMPLE
    Get-Service | Select-Object -Last 3 | ConvertTo-ZabbixDiscoveryJson Name, DisplayName
    {"data":[{"{#NAME}":"wuauserv","{#DISPLAYNAME}":"Windows Update"},{"{#NAME}":"wudfsvc","{#DISPLAYNAME}":"Windows Driver Foundation - User-mode Driver Framework"},{"{#NAME}":"Zabbix Agent","{#DISPLAYNAME}":"Zabbix Agent"}]}

    Converts the names and display names of the last 3 services in the zabbix low-level discovery JSON string.
.INPUTS
    System.Object
.OUTPUTS
    System.String
#>
function ConvertTo-ZabbixDiscoveryJson
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(Position = 0)]
        [String[]]
        $Property = "Name"
    )

    begin
    {
        $Result = @()
    }

    process
    {
        if ($InputObject)
        {
            $Result += foreach ($Obj in $InputObject)
            {
                if ($Obj)
                {
                    $Element = @{}

                    foreach ($P in $Property)
                    {
                        $Key = $ZabbixJsonDiscoveryKey -f $P.ToUpper()
                        $Element[$Key] = [String] $Obj.$P
                    }

                    $Element
                }
            }
        }
    }

    end
    {
        $Result = @{$ZabbixJsonData = $Result}

        return $Result | ConvertTo-Json -Compress
    }
}