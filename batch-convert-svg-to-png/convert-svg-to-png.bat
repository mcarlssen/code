@echo off
setlocal enabledelayedexpansion

:: Get the current directory
set "currentDir=%~dp0"

:: Recursively find all SVG files
for /r "%currentDir%" %%f in (*.svg) do (
    set "svgFile=%%~f"
    set "pngFile=%%~dpnf.png"

    :: Check if the PNG file exists
    if not exist "!pngFile!" (
        echo Converting !svgFile! to !pngFile!
        :: Run the Inkscape command to convert SVG to PNG with the specific parameters
        inkscape --export-background-opacity=0 --export-width=256 --export-type=png --export-filename="!pngFile!" "!svgFile!"
    ) else (
        echo PNG already exists for !svgFile!.
    )
)

echo Done!
pause
