<#
.SYNOPSIS 
    Converts a JSON-formatted string to a custom object.
.DESCRIPTION
    The ConvertFrom-Json function converts a JSON-formatted string to a custom object by using System.Web.Script.Serialization.JavaScriptSerializer object.

    This function should be used in Powershell 2.0 that does not have the cmdlets for processing JSON data. In Povershell 3.0 and later there is standart ConvertFrom-Json cmdlet that should be used instead.

    This function does not fully supports powershell objects and it should be used very carefully.
.PARAMETER InputObject
    Specifies the JSON strings to convert to JSON objects.
.EXAMPLE
    @{'data' = 'value'} | ConvertTo-Json | ConvertFrom-Json
    Key                                                      Value                                                   
    ---                                                      -----                                                   
    data                                                     value

    ConvertTo-Json cmdlets convert the hashtable value to a JSON-formatted string and the ConvertFrom-Json cmdlet converts the JSON-formatted string to object
.INPUTS
    System.String
.OUTPUTS
    System.Object
.NOTES
    https://msdn.microsoft.com/ru-ru/library/system.web.script.serialization.javascriptserializer.deserializeobject(v=vs.110).aspx
#>
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