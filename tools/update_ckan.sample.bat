@echo off
rem Add YOUR api key insted of xxxxxxxxxxxxxxxxxxxxxxx!!!
rem two calls are necessary, because no feedback is analyzed.
c:\Bluebell\tools\curl1\bin\curl -d @%1 -H "Authorization: xxxxxxxxxxxxxxxxxxxxxxx" -X POST "https://geocint.kontur.io/ckan/api/3/action/package_create"
c:\Bluebell\tools\curl1\bin\curl -d @%1 -H "Authorization: xxxxxxxxxxxxxxxxxxxxxxx" -X POST "https://geocint.kontur.io/ckan/api/3/action/package_update"




