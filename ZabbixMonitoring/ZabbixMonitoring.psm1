$GlobalConstant = @{
    'ZabbixJsonHost'         = 'host'
    'ZabbixJsonKey'          = 'key'
    'ZabbixJsonValue'        = 'value'
    'ZabbixJsonTimestamp'    = 'clock'
    'ZabbixJsonRequest'      = 'request'
    'ZabbixJsonData'         = 'data'
    'ZabbixJsonSenderData'   = 'sender data'
    'ZabbixJsonDiscoveryKey' = '{{#{0}}}'
}

$GlobalConstant += @{
    'ZabbixMappingProperty'    = 'Property'
    'ZabbixMappingKey'         = 'Key'
    'ZabbixMappingKeyProperty' = 'KeyProperty'
}

foreach ($Constant in $GlobalConstant.GetEnumerator())
{
    Set-Variable -Scope Global -Option ReadOnly -Name $Constant.Key -Value $Constant.Value -Force
}

$ExportFunction = (
    'ConvertTo-ZabbixDiscoveryJson',
    'Out-UnicodeFileWithoutBom',
    'Convert-Encoding',
    'Expand-HostSize',
    'Send-ZabbixData',
    'New-ZabbixData',
    'Get-UnixDate',
    'ConvertTo-ZabbixData'
)

if ($Host.Version.Major -le 2)
{
    $ExportFunction += ('ConvertTo-Json', 'ConvertFrom-Json')
}

foreach ($Function in $ExportFunction)
{
    . (Join-Path $PSScriptRoot "$Function.ps1")
}

Export-ModuleMember -Function $ExportFunction