<#
.SYNOPSIS 
    Sends output to a UTF-8 file without BOM
.DESCRIPTION
    The Out-UnicodeFileWithoutBom function sends output to a file encoded in UTF8 without byte order mark (BOM).

    Standart powershell cmdlet Out-File does not support UTF8 without BOM encoding.
.PARAMETER InputObject
    Specifies the objects to be written to the file.
.PARAMETER FilePath
    Specifies the path to the output file.
.EXAMPLE
    'Some text' | Out-UnicodeFileWithoutBom 'output.txt'

    Creates file 'output.txt' without BOM and with UTF-8 encoded content 'Some text'.
.INPUTS
    System.Object
#>
function Out-UnicodeFileWithoutBom
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(Position = 0)]
        [String]
        $FilePath
    )

    begin
    {
        $Content = @()
    }

    process
    {
        $Content += $InputObject
    }

    end
    {
        $Content = $Content | Out-String
        $Utf8NoBomEncoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
        [System.IO.File]::WriteAllLines($FilePath, $Content, $Utf8NoBomEncoding)
    }
}
