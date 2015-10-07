function Convert-Encoding
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(Position = 0)]
        [String]
        $From,

        [Parameter(Position = 1)]
        [String]
        $To
    )

    begin
    {
        if ($From)
        {
            $EncodingFrom = [System.Text.Encoding]::GetEncoding($From)
        }
        else
        {
            $EncodingFrom = $OutputEncoding
        }

        if ($To)
        {
            $EncodingTo = [System.Text.Encoding]::GetEncoding($To)
        }
        else
        {
            $EncodingTo = $OutputEncoding
        }

        $Content = @()
    }

    process
    {
        $Content += $InputObject
    }

    end
    {
        $Content = $Content | Out-String
        $Bytes = $EncodingTo.GetBytes($Content)
        $Bytes = [System.Text.Encoding]::Convert($EncodingFrom, $EncodingTo, $Bytes)
        $Content = $EncodingTo.GetString($Bytes)

        return $Content
    }
}
