<#
.SYNOPSIS 
    Converts an object to a JSON-formatted string
.DESCRIPTION
    The ConvertTo-Json function converts hashtable object to a string in JavaScript Object Notation (JSON) format by using System.Web.Script.Serialization.JavaScriptSerializer object.

    This function should be used in Powershell 2.0 that does not have the cmdlets for processing JSON data. In Povershell 3.0 and later there is standart ConvertTo-Json cmdlet that should be used instead.

    This function does not fully supports powershell objects should be used very carefully.
.PARAMETER InputObject
    Specifies the objects to convert to JSON format.
.PARAMETER Compress
    Do nothing. Needed for backward compatibility with ConvertTo-Json cmdlet from Povershell 3.0 and later.
.EXAMPLE
    @{'data' = 'value'} | ConvertTo-Json | ConvertFrom-Json
    Key                                                      Value                                                   
    ---                                                      -----                                                   
    data                                                     value

    ConvertTo-Json function convert the hashtable value to a JSON-formatted string and the ConvertFrom-Json cmdlet converts the JSON-formatted string to object.
.INPUTS
    System.Object
.OUTPUTS
    System.String
.NOTES
    https://msdn.microsoft.com/ru-ru/library/bb292287(v=vs.110).aspx
#>
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
