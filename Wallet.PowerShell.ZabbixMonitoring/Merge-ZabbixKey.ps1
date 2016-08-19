function Merge-ZabbixKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
        
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $KeyPattern,
        
        [Parameter(Position = 1)]
        [String[]]
        $KeyProperty
    )
    
    process
    {
        if ($InputObject)
        {
            foreach ($Object in $InputObject)
            {
                foreach ($Key in $Object.Keys)
                {
                    @{
                        $ZabbixMappingProperty    = $Key
                        $ZabbixMappingKey         = $KeyPattern -f $Object[$Key]
                        $ZabbixMappingKeyProperty = $KeyProperty
                    }
                }
            }
        }
    }
}