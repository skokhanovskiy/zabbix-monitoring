<#
.SYNOPSIS 
    Starts repeated execution of the script block.
.DESCRIPTION
    The Start-Repeatly function periodically starts the script block during specified time and with predetermined frequency.
.PARAMETER ScriptBlock
    Specifies the script block for executing.
.PARAMETER Frequency
    Specifies the frequency of the script block executing in seconds. 
.PARAMETER Duration
    Specifies the duration of the script block executing in seconds.
.EXAMPLE
    Start-Repeatly -ScriptBlock { Write-Host Hallo } -Frequency 2 -Duration 10

    The Start-Repeatly function will be start script block every 2 seconds for 10 seconds. "Hallo" phrase will be output in the console 5 times.
#>
function Start-Repeatly
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 1)]
        [Int]
        $Frequency = 1,

        [Parameter(Position = 2)]
        [Int]
        $Duration = 0
    )

    if ($Frequency -lt 0)
    {
        throw "Frequency value must be greater or equal to 0"
    }

    if ($Duration -lt 0)
    {
        throw "Duration value must be greater or equal to 0"
    }

    $CmdletStartTime = Get-Date
    Write-Debug "Cmndlet start time: $CmdletStartTime"

    if ($Duration -gt 0)
    {
        $CmdletEndTime = $CmdletStartTime.AddSeconds($Duration)
    }
    else
    {
        $CmdletEndTime = [DateTime]::MaxValue
    }
    Write-Debug "Cmndlet end time: $CmdletEndTime"

    $Counter = 0

    while ((Get-Date) -lt $CmdletEndTime)
    {        
        $ExecuteStartTime = Get-Date
        Write-Verbose "Start scriptblock execution"

        try
        {
            $Counter++
            & $ScriptBlock
        }
        finally
        {
            $ExecuteDuration = (Get-Date) - $ExecuteStartTime
            Write-Verbose "Scriptblock finished. Duration $($ExecuteDuration.TotalMilliseconds) ms"
        }

        if ($Frequency -gt 0)
        {
            if ($ExecuteDuration.TotalSeconds -gt $Frequency)
            {
                Write-Error "Scriptblock execution time ($($ExecuteDuration.TotalSeconds) seconds) greater than the specified frequency ($Frequency seconds)" -Category InvalidOperation
            }

            $AddSeconds = ([Math]::Truncate(((Get-Date) - $CmdletStartTime).TotalSeconds / $Frequency) + 1) * $Frequency
            $ExecuteStartTime = $CmdletStartTime.AddSeconds($AddSeconds)
        }
        else
        {
            $ExecuteStartTime = Get-Date
        }

        Write-Debug "Next start at $ExecuteStartTime" 

        if ($ExecuteStartTime -ge $CmdletEndTime)
        {
            break
        }
        else
        {
            $SleepTime = ($ExecuteStartTime - (Get-Date)).TotalMilliseconds

            if ($SleepTime -ge 0)
            {
                Write-Debug "Start sleeping $SleepTime ms"
                Start-Sleep -Milliseconds $SleepTime
            }
        }
    }

    Write-Verbose "Total number of executions: $Counter"
}