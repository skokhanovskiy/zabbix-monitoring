<#
.SYNOPSIS 
    Converts an object to a zabbix data
.DESCRIPTION
    The ConvertTo-ZabbixData function converts any object to hashtable with zabbix data. 
.PARAMETER InputObject
    Specifies the objects to convert to zabbix data.
.PARAMETER HostName
    Specifies the hostname that will be assigned for each item in zabbix data.
.PARAMETER PropertyMapping
    Specifies the hashtables that containts a mapping information between objects properties and zabbix keys.

    Each hashtable should contain the "$ZabbixMappingProperty" key with value of object's property name and "$ZabbixMappingKey" key with value of zabbix item key.

    A hashtable may contain "$ZabbixMappingKeyProperty" key with one or few property names that will be formatted by -f operator with "$ZabbixMappingKey" value.
.EXAMPLE
    Get-Service -Name wuauserv | ConvertTo-ZabbixData -HostName $env:COMPUTERNAME -PropertyMapping @{'Property' = 'Status'; 'Key' = 'windowsupdate[state]'}
    Name                           Value                                                                                                                                                                                                                             
    ----                           -----                                                                                                                                                                                                                             
    host                           COMPUTERNAME                                                                                                                                                                                                                          
    key                            windowsupdate[state]                                                                                                                                                                                                              
    value                          Running    

    Converts the Windows Update service object to hashtable with zabbix data that containts status of service
.EXAMPLE
    Get-Service | Select-Object -Last 3 | ConvertTo-ZabbixData -HostName $env:COMPUTERNAME -PropertyMapping @{'Property'='Status';'Key'='service["{0}",state]';'KeyProperty'='Name'} | % {New-Object PSObject -Property $_}
    host                   key                               value                                                                                
    ----                   ---                               -----                                                                                
    COMPUTERNAME           service["wuauserv",state]         Running                                                                              
    COMPUTERNAME           service["wudfsvc",state]          Stopped                                                                              
    COMPUTERNAME           service["WwanSvc",state]          Stopped                                                                                 

    Converts the service objects to hashtable with zabbix data that containts status of last 3 services from Get-Service output.

    Last New-Object in the pipe just to format output only.
.INPUTS
    System.Object
.OUTPUTS
    System.Collections.Hashtable
.LINKS
    New-ZabbixData
#>

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