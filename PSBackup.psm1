function Log($message)
{
    Write-Host $message
    Add-Content -Path $($script:logFile) -Value $($message)
}

function CopyFile($f, $p, $i)
{
    Log("Backing up $($f.FullName) to $($finalFilePath)")
    Copy-Item -Recurse -Force -Path $f.FullName -Destination $finalFilePath
    if(-Not $i)
    {
        $script:updatedCount += 1
    }
}

function DoBackup($job)
{
    Log("`n--- Running Job: $($job.name) ---`n")

    $sources = $job.sources
    $root = $job.sourceRoot
    $destinations = $job.destinations

    # if $sources is empty, we should add one that is just \
    # which will just back up everything in the root directory
    if ($sources.Count -eq 0)
    {
        $sources = @("\")
    }

    foreach ($src in $sources)
    {
        $s = "$($root)\$($src)"

        if (-Not (Test-Path $s)) 
        {
            Log("WARNING: Source $($s) does not exist")
            continue;
        }

        # test if source is a directory or file
        if($(Get-Item $s) -is [System.IO.DirectoryInfo])
        {
            # grab a list of all the files from a source directory
            $files = Get-ChildItem $s\*.* -Recurse -Force
        }
        else
        {
            # put the file in a list by itself
            $files = Get-ChildItem $s -Recurse -Force
        }

        # add to the total file count
        $script:totalCount += $files.Count

        # for every file in the list
        foreach ($f in $files)
        { 
            $subpath = "$($f.Directory)" -replace [regex]::escape($root), ""

            for (($i = 0); $i -lt $destinations.Count; $i++)
            {
                # create new destination structure using that list
                $finalDestinationDir = "$($destinations[$i])$($subpath)"
                $finalFilePath = "$($finalDestinationDir)\$($f.Name)"

                # create all missing folders
                New-Item -Path $finalDestinationDir -ItemType Directory -Force | Out-Null

                # check if file exists
                if (Test-Path $finalFilePath) 
                {
                    # if the file exists, check the modified date
                    if ($f.LastWriteTime -eq $(Get-Item -Force $finalFilePath).LastWriteTime)
                    {
                        Log("$($f.FullName) is up to date on $($finalFilePath)")
                    }
                    else
                    {
                        CopyFile($f, $finalFilePath, $i)
                    }
                }
                else 
                {
                    CopyFile($f, $finalFilePath, $i)
                }
            }
        }
    }
}

function Start-PSBackup()
{
    param(
        [Parameter(Mandatory=$true)] [string] $jobFileInfo,
        [Parameter(Mandatory=$false)] [switch] $FullPath
    )

    # create the home psbackup directory if it doesnt exist
    if (-Not (Test-Path "$($HOME)\psbackup\"))
    {
        New-Item -Path "$($HOME)\psbackup" -ItemType Directory -Force | Out-Null
    }

    # create the log directory if it doesnt exist
    if (-Not (Test-Path "$($HOME)\psbackup\log"))
    {
        New-Item -Path "$($HOME)\psbackup\log" -ItemType Directory -Force | Out-Null
    }

    $script:logFile = "$($HOME)\psbackup\log\$(Get-Date -Format "yyyyMMdd_HHmm").txt"

    if (-Not (Test-Path $script:logFile))
    {
        New-Item -Path "$($script:logFile)" -ItemType File -Force | Out-Null
    }

    # if the jobfile is empty
    if($jobFileInfo -eq "")
    {
        Log("`nERROR: No job file name provided`n")
        return
    }

    # If the FullPath switch is present then the path provide is
    # the full path to the job file, use it as is.
    # If not, then we assume the job file is in the $HOME\psbackup directory
    if($FullPath.IsPresent)
    {
        $jobFile = "$($jobFileInfo)"
    }
    else
    {
        $jobFile = "$($HOME)\psbackup\$($jobFileInfo).json"
    }


    if (-Not (Test-Path $jobFile))
    {
        Log("`nERROR: File '$($jobFile)' not found`n")
        return
    }

    Log("`n-------------------------------------------------------")
    Log("PSBackup  -  $(Get-Date -Format "yyyy/MM/dd HH:mm")`n")
    Log("Job File: $($jobFile)")
    Log("-------------------------------------------------------")

    Start-Sleep -Milliseconds 1000

    $script:jobs = Get-Content $jobFile | Out-String | ConvertFrom-Json
    $script:totalCount = 0
    $script:updatedCount = 0
    $script:activeJobs = 0
    $script:totalJobs = 0

    foreach ($script:j in $script:jobs)
    {
        if($script:j.active)
        {
            $script:activeJobs += 1
            DoBackup($script:j)
        }
        $script:totalJobs += 1
    }

    Log("`n------------------- Summary ---------------------------")
    Log("Job File        $($jobFile)")
    Log("Log File        $($logFile)")
    Log("Active Jobs     $($script:activeJobs)/$($script:totalJobs)")
    Log("Files Updated   $($script:updatedCount)/$($script:totalCount)")
    Log("-------------------------------------------------------`n")
}

Export-ModuleMember -Function Start-PSBackup

