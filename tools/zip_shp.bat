@echo off
rem "c:\Program Files\7-Zip\7z.exe" a %2 %1.shp %1.prj %1.dbf %1.shx 
del /Q %2
"c:\Program Files\WinRAR\Rar.exe" a -ep %2 %1.shp %1.prj %1.dbf %1.shx 