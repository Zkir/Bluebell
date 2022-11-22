@echo off
rem "c:\Program Files\7-Zip\7z.exe" a %2 %1
del /q %2
c:\bluebell\tools\kzip.exe /y %2 %1
