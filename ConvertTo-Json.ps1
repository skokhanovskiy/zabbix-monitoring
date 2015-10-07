function ConvertTo-Json
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter()]
        [Switch]
        $Compress
    )

    begin
    {
        Add-Type -AssemblyName System.Web.Extensions
        $JavaScriptSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    }

    process
    {
        $JavaScriptSerializer.Serialize($InputObject)
    }
}
