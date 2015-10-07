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

foreach ($Constant in $GlobalConstant.GetEnumerator())
{
    Set-Variable -Scope Global -Option ReadOnly -Name $Constant.Key -Value $Constant.Value
}

$ExportFunction = (
    'ConvertTo-ZabbixDiscoveryJson',
    'Out-UnicodeFileWithoutBom',
    'Convert-Encoding',
    'Expand-HostSize',
    'Send-ZabbixData',
    'New-ZabbixData',
    'Get-UnixDate'
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