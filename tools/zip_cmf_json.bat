@echo off
del /Q %2
"c:\Program Files\WinRAR\Rar.exe" a -ep1 -r -x*.CKAN.json  %2 %1\*.json 