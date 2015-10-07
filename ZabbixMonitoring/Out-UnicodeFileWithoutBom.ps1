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
