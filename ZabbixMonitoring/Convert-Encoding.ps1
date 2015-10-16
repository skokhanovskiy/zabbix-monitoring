<#
.SYNOPSIS 
    Converts string encoding
.DESCRIPTION
    The Convert-Encoding function converts code page of string from one encoding to another
.PARAMETER From
    Source code page
.PARAMETER To
    Destination code page
.EXAMPLE
    'This is string' | Convert-Encoding -From CP866 -To UTF-8
    Converts encoding of string from CP866 to UTF-8
.EXAMPLE
    'This is another string' | Convert-Encoding -To windows-1251
    Converts code page of string from default console encoding to windows-1251
.INPUTS
    System.String
.OUTPUTS
    System.String
.NOTES
    Full list of supported code page names here:
    
    https://msdn.microsoft.com/ru-ru/library/system.text.encoding(v=vs.110).aspx
#>
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
