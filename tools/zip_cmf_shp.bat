@echo off
del /Q %2
"c:\Program Files\WinRAR\Rar.exe" a -r -ep1 %2  %1\*.shp %1\*.prj %1\*.dbf %1\*.shx  %1\*.cpg