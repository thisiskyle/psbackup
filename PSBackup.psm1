function CopyFile($f, $p, $i)
{
    Write-Host "Backing up $($f.FullName) to $($finalFilePath)"
    Copy-Item -Recurse -Force -Path $f.FullName -Destination $finalFilePath
    if(-Not $i)
    {
        $script:updatedCount += 1
    }
}

function DoBackup($job)
{
    Write-Host "--- Running Job: $($job.name) ---"

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
            Write-Host "WARNING: Source $($s) does not exist"
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
                        Write-Host "$($f.FullName) is up to date on $($finalFilePath)"
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

function Start-PSBackup($jobFile)
{

    if($jobFile -eq "")
    {
        Write-Host ""
        Write-Host "ERROR: No job file provided"
        Write-Host ""
        return
    }

    if (-Not (Test-Path $jobFile))
    {
        Write-Host ""
        Write-Host "ERROR: File '$($jobFile)' not found"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "-------------------------------------------------------"
    Write-Host "PSBackup  -  $(Get-Date -Format "yyyy/MM/dd HH:mm")"
    Write-Host ""
    Write-Host "Job File: $($jobFile)"
    Write-Host "-------------------------------------------------------"
    Write-Host ""

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

    Write-Host ""
    Write-Host "------------------- Summary ---------------------------"
    Write-Host "Job File        $($jobFile)"
    Write-Host "Active Jobs     $($script:activeJobs)/$($script:totalJobs)"
    Write-Host "Files Updated   $($script:updatedCount)/$($script:totalCount)"
    Write-Host "-------------------------------------------------------"
    Write-Host ""
}

Export-ModuleMember -Function Start-PSBackup

