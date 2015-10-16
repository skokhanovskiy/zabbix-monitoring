function ConvertTo-ZabbixData
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
        
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $HostName,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [System.Collections.Hashtable[]]
        $PropertyMapping
    )
    
    process
    {
        if ($InputObject)
        {
            foreach ($Object in $InputObject)
            {
                foreach ($Mapping in $PropertyMapping)
                {
                    $Key = $Mapping[$ZabbixMappingKey]

                    if ($Mapping[$ZabbixMappingKeyProperty])
                    {
                        $KeyPropertyValue = foreach ($Property in $Mapping[$ZabbixMappingKeyProperty])
                        {
                            $Object | Select-Object -ExpandProperty $Property
                        }

                        $Key = $Key -f $KeyPropertyValue
                    }

                    $Value = $Object | Select-Object -ExpandProperty $Mapping[$ZabbixMappingProperty]

                    New-ZabbixData -HostName $HostName -Key $Key -Value $Value
                }
            }
        }
    }
}