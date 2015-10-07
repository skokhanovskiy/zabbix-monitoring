function ConvertFrom-Json
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    begin
    {
        Add-Type -AssemblyName System.Web.Extensions
        $JavaScriptSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    }

    process
    {
        $JavaScriptSerializer.DeserializeObject($InputObject)
    }
}