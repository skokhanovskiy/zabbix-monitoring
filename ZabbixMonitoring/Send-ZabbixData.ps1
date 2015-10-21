<#
.SYNOPSIS 
    Gets zabbix header for buffer of message
.DESCRIPTION
    The Get-ZabbixBufferHeader function gets zabbix header for buffer of message
.OUTPUTS
    System.String
.LINKS
    Send-ZabbixData
#>
function Get-ZabbixBufferHeader
{
    return "ZBXD"
}

<#
.SYNOPSIS 
    Adds timestamp for zabbix data
.DESCRIPTION
    The Add-ZabbixDataTimestamp function checks whether the timestamp in at least one item of zabbix data. If found, it adds the timestamp with the current time value to all values that do not contain the timestamp. If not found, do nothing.
.PARAMETER InputObject
    Specifies the hashtable with zabbix data.
.PARAMETER Timestamped
    Specifies a reference to a variable of boolean type. There are items in zabbix data with a timestamp if its value is true.
.INPUTS
    System.Collections.Hashtable
.OUTPUTS
    System.Collections.Hashtable
.LINKS
    Send-ZabbixData
#>
function Add-ZabbixDataTimestamp
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [System.Collections.Hashtable[]]
        $InputObject,

        [Parameter(Position = 1)]
        [Ref]
        $Timestamped
    )

    begin
    {
        $Data = @()
        $TimestampedValue = $false
    }

    process
    {
        $Data += $InputObject
    }

    end
    {
        if ($Data)
        {
            foreach ($D in $Data)
            {
                if ($D[$ZabbixJsonTimestamp])
                {
                    $TimestampedValue = $true
                    break
                }
            }
            
            foreach ($D in $Data)
            {
                if ($TimestampedValue -and (-not $D[$ZabbixJsonTimestamp]))
                {
                    $D[$ZabbixJsonTimestamp] = Get-UnixDate
                }
                $D
            }
        }
        
        if ($Timestamped)
        {
            $Timestamped.Value = $TimestampedValue
        }
    }
}

<#
.SYNOPSIS 
    Gets buffer with zabbix data to send.
.DESCRIPTION
    The Get-ZabbixSendBuffer function gets buffer of bytes with zabbix data to send to remote zabbix server.
.PARAMETER InputObject
    Specifies the hashtable with zabbix data.
.INPUTS
    System.Collections.Hashtable
.OUTPUTS
    System.Array
.LINKS
    Send-ZabbixData
#>
function Get-ZabbixSendBuffer
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [System.Collections.Hashtable[]]
        $InputObject
    )

    begin
    {
        $Data = @()
    }

    process
    {
        $Data += $InputObject
    }

    end
    {
        $Timestamped = $false
        $Data = $Data | Add-ZabbixDataTimestamp -Timestamped ([Ref] $Timestamped)
        Write-Verbose "Timestamped: $Timestamped"

        $Data = @{
            $ZabbixJsonRequest = $ZabbixJsonSenderData
            $ZabbixJsonData = @($Data)
        }

        if ($Timestamped)
        {
            $Data[$ZabbixJsonTimestamp] = Get-UnixDate
        }
        
        try
        {
            $Json = $Data | ConvertTo-Json -Compress
            Write-Verbose "JSON message: $Json"
        }
        catch
        {
            throw $_
        }

        $Utf8NoBomEncoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
        $Header = $Utf8NoBomEncoding.GetBytes((Get-ZabbixBufferHeader)) + 1
        $Data = $Utf8NoBomEncoding.GetBytes($Json)
                
        $Length = [BitConverter]::GetBytes([Long] $Data.Length)

        return $Header + $Length + $Data
    }
}

<#
.SYNOPSIS 
    Receives data from socket.
.DESCRIPTION
    The ReceiveFrom-Socket function recieves buffer of bytes from network socket.
.PARAMETER Socket
    Specifies the System.Net.Sockets.Socket object.
.PARAMETER Size
    Specifies the size of buffer to recieve.
.PARAMETER Offset
    Specifies the offset in buffer in bytes. Default value is 0.
.PARAMETER
    Specifies the timeout of reading in miliseconds. Default value is 10000.
.OUTPUTS
    System.Array
.LINKS
    Send-ZabbixData
#>
function ReceiveFrom-Socket
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Net.Sockets.Socket]
        $Socket,

        [Parameter(Mandatory = $true)]
        [Int]
        $Size,

        [Parameter()]
        [Int]
        $Offset = 0,

        [Parameter()]
        [Int]
        $Timeout = 10000
    )

    $StartTickCount = [Environment]::TickCount
    $Received = 0

    $Buffer = New-Object -TypeName System.Byte[] -ArgumentList $Size

    do
    {
        if ([Environment]::TickCount -gt ($StartTickCount + $Timeout))
        {
            throw "Timeout waiting for a response from the server"
        }
        try
        {
            $Received += $Client.Receive($Buffer, $Received, $Size - $Received, [System.Net.Sockets.SocketFlags]::None)
        }
        catch [Net.Sockets.SocketException]
        {
            if (([Net.Sockets.SocketError]::WouldBlock, [Net.Sockets.SocketError]::IOPending, [Net.Sockets.SocketError]::NoBufferSpaceAvailable) -contains $_.SocketErrorCode)
            {
                Start-Sleep -Milliseconds 30
            }
            else
            {
                throw $_
            }
        }
    }
    while ($Received -lt $Size)

    if ($Received -gt 0)
    {
        return $Buffer
    }
}

<#
.SYNOPSIS 
    Receives a response from zabbix server.
.DESCRIPTION
    The Receive-ZabbixResponse function recieves and process a response from zabbix server.
.PARAMETER Socket
    Specifies the System.Net.Sockets.Socket object.
.PARAMETER Header
    Receives a header.
.PARAMETER DataLength
    Receives a length of data.
.PARAMETER Data
    Receives a data.
.PARAMETER Length
    Specifies the length of data.
.OUTPUTS
    System.Array
.LINKS
    Send-ZabbixData
#>
function Receive-ZabbixResponse
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'DataLength')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Data')]
        [System.Net.Sockets.Socket]
        $Socket,

        [Parameter(Mandatory = $true, ParameterSetName = 'Header')]
        [Switch]
        $Header,

        [Parameter(Mandatory = $true, ParameterSetName = 'DataLength')]
        [Switch]
        $DataLength,

        [Parameter(Mandatory = $true, ParameterSetName = 'Data')]
        [Switch]
        $Data,

        [Parameter(Mandatory = $true, ParameterSetName = 'Data')]
        [Int]
        $Length
    )
    
    switch ($PSCmdlet.ParameterSetName)
    {
        'Header'
        {
            $BufferSize = 5
        }
        'DataLength'
        {
            $BufferSize = 8
        }
        'Data'
        {
            $BufferSize = $Length
        }
    }

    $Buffer = ReceiveFrom-Socket -Socket $Client -Size $BufferSize

    switch ($PSCmdlet.ParameterSetName)
    {
        'Header'
        {
            $Utf8NoBomEncoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
            $HeaderValue = $Utf8NoBomEncoding.GetString($Buffer)

            if (-not $HeaderValue.StartsWith((Get-ZabbixBufferHeader)))
            {
                throw "Invalid response header: '$Header'"
            }
            else
            {
                Write-Verbose "Valid header in response"
                $HeaderValue
            }
        }
        'DataLength'
        {
            $DataLengthValue = [BitConverter]::ToInt32($Buffer, 0)

            if ($DataLengthValue -eq 0)
            {
                throw "Zero length of data in response"
            }
            else
            {
                Write-Verbose "Length of data in response: $DataLengthValue"
                $DataLengthValue
            }
        }
        'Data'
        {
            $Utf8NoBomEncoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
            $DataValue = $Utf8NoBomEncoding.GetString($Buffer)
            Write-Verbose "Response JSON: $DataValue"

            $DataValue
        }
    }        
}

<#
.SYNOPSIS 
    Converts a data from zabbix response to object.
.DESCRIPTION
    The Get-ZabbixSendBuffer function converts a data from response of zabbix server to object.
.PARAMETER InputObject
    Specifies the response data.
.INPUTS
    System.Array
.OUTPUTS
    System.Collections.Hashtable
.LINKS
    Send-ZabbixData
#>
function ConvertFrom-ZabbixResponse
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        $InputObject
    )

    begin
    {
        $ResponseSuccessPattern = 'success'
        $ResponseInfoPattern = `
            'processed:\s+(?<processed>\d+);' + 
            '\s+failed:\s+(?<failed>\d+);' +
            '\s+total:\s+(?<total>\d+);' +
            '\s+seconds\s+spent:\s+(?<spent>[\d.]+)'
    }

    process
    {
        $Data = $InputObject | ConvertFrom-Json

        $Property = @{}
        $Property['Success'] = $Data.response -match $ResponseSuccessPattern

        if ($Data.info -match $ResponseInfoPattern)
        {
            $Property['Processed'] = $Matches['processed']
            $Property['Failed'] = $Matches['failed']
            $Property['Total'] = $Matches['total']
            $Property['Spent'] = $Matches['spent']
        }
        else
        {
            $Property['Info'] = $Data['info']
        }

        New-Object -TypeName PSObject -Property $Property
    }
}

<#
.SYNOPSIS 
    Sends a data to the zabbix server
.DESCRIPTION
    The Send-ZabbixData function sends a data to the remote zabbix server
.PARAMETER InputObject
    Specifies the hashtable with data to send. 

    The hashtable must contain the following keys: 'host' with value of host name, 'key' with value of zabbix item key and 'value' with item's value. The hashtable may contain 'clock' key with timestamp for value in unix time format.

    The hashtable for this parameter can be easily created using the New-ZabbixData or ConvertTo-ZabbixData functions.
.PARAMETER Server
    Specifies the name of the zabbix server or zabbix proxy.
.PARAMETER Port
    Specifies an alternate port on the zabbix server. The default value is 10051, which is the default zabbix port.
.EXAMPLE
    New-ZabbixData 'MYSQL1' 'mysql.queries' '347.4' | Send-ZabbixData 'zabbix'

    The New-ZabbixData function creates the zabbix data item with '347.4' as value for 'mysql.queries' key in 'MYSQL1' host. The Send-ZabbixData function sends this value to zabbix server with name 'zabbix'.
.INPUTS
    System.Collections.Hashtable
.OUTPUTS
    System.Collections.Hashtable
.LINKS
    New-ZabbixData
    ConvertTo-ZabbixData
.NOTES
    https://www.zabbix.com/documentation/2.4/manual/concepts/sender
    https://www.zabbix.com/documentation/2.4/manpages/zabbix_sender
    https://www.zabbix.org/wiki/Docs/protocols/zabbix_sender/2.0
#>
function Send-ZabbixData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Server,

        [Parameter()]
        [Int]
        $Port = 10051,

        [Parameter(ValueFromPipeline = $true)]
        [System.Collections.Hashtable[]]
        $InputObject
    )

    begin
    {
        $SendData = @()
    }

    process
    {
        $SendData += $InputObject
    }

    end
    {
        if (-not $SendData)
        {
            Write-Verbose "Nothing to send"
        }
        else
        {
            Write-Verbose "Number of items: $(($SendData | Measure-Object).Count)"

            $SendBuffer = $SendData | Get-ZabbixSendBuffer
            Write-Verbose "Length of buffer to send: $($SendBuffer.Length) bytes"

            $Client = New-Object -TypeName Net.Sockets.Socket -ArgumentList (
                [System.Net.Sockets.AddressFamily]::InterNetwork, 
                [System.Net.Sockets.SocketType]::Stream,
                [System.Net.Sockets.ProtocolType]::Tcp
            )

            $Client.Connect($Server, $Port)
            if (-not $Client.Connected)
            {
                throw "Can not connect to server $Server, port $Port"
            }
            Write-Verbose "Connected to server $Server, port $Port"

            try
            {
                $Sended = $Client.Send($SendBuffer)
                Write-Verbose "Sended $Sended bytes to server"

                Receive-ZabbixResponse -Socket $Client -Header | Out-Null
                $DataLength = Receive-ZabbixResponse -Socket $Client -DataLength
                $Data = Receive-ZabbixResponse -Socket $Client -Data -Length $DataLength

                $Data | ConvertFrom-ZabbixResponse
            }
            finally
            {
                $Client.Close()
            }
        }
    }
}
