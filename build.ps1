<#

    .Synopsis
    Build script for the JSTR Modded texture pack

    .Description
        Compiles all the textures in the JSTR Modded pack into something that can be dropped into your
        Minecraft resourcepacks folder

    .Parameter Source
        The path to the JSTR Modded repository. Defaults to the current directory.

    .Parameter Destination
        The path that that the resource pack should be assembled in. Defaults to dist/JSTR-Modded-1.7.10

    .Parameter Branch
        If set, only modified files in the current branch will be included in the build.
        Very useful for speeding up build times. Requires git on PATH

    .Parameter Force
        If set, any destination folder will be overwritten

    .Parameter PackMeta
        The path to the pack.mcmeta file to copy into the resource pack
#>


Param(
    
    [string] $Source = ".",

    [string] $Destination = "dist/JSTR-Modded-1.7.10",

    [switch] $Branch = $false,

    [switch] $Force = $false,

    [string] $PackMeta = "pack.mcmeta"
)


If ((Test-Path $Destination) -ne $true) {
    New-Item $Destination -ItemType Directory
} ElseIf ($Force -eq $true) {
    Write-Host "Removing destination folder"
    Remove-Item $Destination -Recurse -Force:$Force
}
Else {
    Write-Error "$Destination already exists. To overwrite, use -Force"
    Exit
}

$sourceFiles

If ($Branch) {
    $sourceFiles = git diff-tree --no-commit-id --name-only -r master..head
}
Else {
    $sourceFiles = Get-ChildItem $Source -Recurse -Filter "assets" -Directory
}

Write-Host "Copying $($sourceFiles.Length) files"

$sourceFiles | Copy-Item -Destination $Destination -Recurse -Force

Write-Host "Copying pack.mcmeta"
Copy-Item $PackMeta -Destination $Destination -Force:$Force