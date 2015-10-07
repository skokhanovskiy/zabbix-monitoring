function Get-ZabbixBufferHeader
{
    return "ZBXD"
}

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
            $ZabbixJsonData = $Data
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
        $Length = [BitConverter]::GetBytes([Long] $Json.Length)
        
        $Data = $Utf8NoBomEncoding.GetBytes($Json)

        return $Header + $Length + $Data
    }
}

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

        New-Object -TypeName PSObject -Property $Property
    }
}

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
