<#
    .SYNOPSIS
        Exports all assets from all mods in a folder

    .DESCRIPTION
        Loops through each jar file in a folder recursively, extracting any assets folders within and placing
        them in the destination folder

    .PARAMETER Source
        The folder that contains the mods

    .PARAMETER Destination
        The folder that assets should be placed in
#>
Function Export-ModAssets {

    Param(

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Source,

        [Parameter(Mandatory = $true)]
        [string] $Destination

    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $jars = Get-ChildItem -Path $Source -Filter "*.jar" -Recurse -File


    $destinationPath = Resolve-Path $Destination
    $fileTable = @{}
    $fileCount = 0

    ForEach ($jar in $jars) {

        $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName)
        $modName = $jar

        # Get mcmod.info
        $mcMod = $zip.Entries | Where-Object { $_.FullName -eq "mcmod.info" } | Select -First 1

        If ($mcMod -eq $null) {
            Write-Warning "$jar does not contain an mcmod.info file"
        }
        Else {
            $stream = $mcMod[0].Open()
            $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $stream

            $content = $reader.ReadToEnd()

            $reader.Dispose()
            $stream.Dispose()

            $modInfo = $content | ConvertFrom-Json
            If ($modInfo -eq $null) {
                # Unable to parse mod info
                Write-Warning "Unable to parse mcmod.info in $jar"
                $modName = $jar
            }
            ElseIf ($modInfo -is [array])
            {
                # ModList version 1
                $modName = $modInfo[0].name
            }
            ElseIf ($modInfo.modListVersion -eq 2) {
                # ModList version 2
                $modName = $modInfo.modList[0].name
            }
            Else {
                # Unable to parse mod info
                Write-Warning "Unable to parse mcmod.info in $jar"
                $modName = $jar
            }

            If ($modName -eq $null) {
                Write-Warning "Unable to parse mcmod.info in $jar"
                $modName = $jar
            }
        }

        $entries = $zip.Entries | Where-Object { $_.FullName -like "assets/*" }
        Write-Host "Extracting $($entries.Length) assets from $modName"

        ForEach ($entry in $entries) {
            # Ignore folders
            If ($entry.FullName.EndsWith("\") -or $entry.FullName.EndsWith("/")) {
                Continue
            }

            $tableEntry = $fileTable[$entry.FullName]
            If ($tableEntry) {
                Write-Warning "$modName overwrites $($entry.FullName) from $tableEntry"
            }

            $fileTable[$entry.FullName] = $modName

            $folder = [System.IO.Path]::GetDirectoryName($entry.FullName)
            $destinationFolder = Join-Path $destinationPath $folder

            If ((Test-Path $destinationFolder) -ne $true) {
                Write-Verbose "Creating destination folder $folder"
                New-Item -Path $destinationFolder -ItemType Directory | Out-Null
            }

            Write-Verbose "Extracting $($entry.FullName)"
            $zipDestination = Join-Path $destinationPath $entry.FullName
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $zipDestination, $true)

            $fileCount += 1
        }

        $zip.Dispose()
    }

    Write-Host "Extracted $fileCount assets from $($jars.Length) mods"
}