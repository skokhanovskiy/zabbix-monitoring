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