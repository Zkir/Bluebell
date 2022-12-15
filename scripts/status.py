import time
import sys
from datetime import datetime
import os
import os.path

STATUS_TARGET_NAME = 0
STATUS_TARGET_LAST_COMLETED_DATE = 1
STATUS_TARGET_STATUS = 2
STATUS_TARGET_STATUS_DATE = 3
STATUS_TARGET_DURATION = 4
STATUS_TARGET_DEPENDANCIES = 5
STATUS_TARGET_LOG_FOLDER = 6

DATE_FORMAT = "%Y-%m-%dT%H:%M:%S"

dat_file_name = "99_WebUI/status.dat"
dashboard_file_name = "99_WebUI/index.html"


#====================================================================================
# home-brew relational DB interface
# plain files pipe (|) separated
#====================================================================================
def loadDatFile(strInputFile, encoding="utf-8", separator="|"):
    cells = []
    if os.path.exists(strInputFile):
        filehandle = open(strInputFile, 'r', encoding=encoding)
        txt = filehandle.readline().strip()
        while len(txt) != 0:
            if txt[0:1] != "#":
                row = txt.strip().split(separator)
                for i in range(len(row)):
                    row[i] = row[i].strip()
                if len(row)>1:
                    cells.append(row)
            txt = filehandle.readline()
        # end of while
        filehandle.close()
    return cells

def saveDatFile(cells,strOutputFile):

    filehandle = open(strOutputFile, 'w', encoding="utf-8" )
    for row in cells:
        txt = "" 
        for field in row: 
            if txt!="":
                txt = txt + "|"   
            txt = txt + field
        filehandle.write(txt+'\n') 
    filehandle.close() 


def print_html(strOutputFile,tblStatus1):
    tblStatus = sorted(tblStatus1, key = lambda record : record[STATUS_TARGET_STATUS_DATE], reverse=True)
     
    pipeline_status='Idle' 
    n_targets_total = 0
    n_targets_in_progress = 0
    n_targets_frozen = 0
    n_targets_failed = 0
    oldest_completed = ''

    for record in tblStatus:
        n_targets_total = n_targets_total + 1
        if record[STATUS_TARGET_STATUS] == "started":
            pipeline_status='Up and Running'
            n_targets_in_progress = n_targets_in_progress + 1  
        elif record[STATUS_TARGET_STATUS] == "failed":
            n_targets_failed = n_targets_failed + 1
        elif record[STATUS_TARGET_STATUS] == "completed":
            if oldest_completed == '':
                oldest_completed = record[STATUS_TARGET_STATUS_DATE]
            elif oldest_completed>record[STATUS_TARGET_STATUS_DATE]:
                oldest_completed = record[STATUS_TARGET_STATUS_DATE]


    fo = open(strOutputFile, 'w', encoding="utf-8")
    fo.write('<html>\n')
    fo.write('<head>\n')
    fo.write('<style>\n')
    fo.write('    table, th, td {\n')
    fo.write('        border: 1px solid black;\n')
    fo.write('        border-collapse: collapse;\n')
    fo.write('    } ')
    fo.write('    th, td {\n')
    fo.write('        padding: 15px;\n')
    fo.write('    }\n')
    fo.write('    tr.started {\n')
    fo.write('        background-color: yellow; \n')
    fo.write('    }\n')
    fo.write('    tr.failed {\n')
    fo.write('        background-color: red; \n')
    fo.write('    }\n')
    fo.write('</style>\n')
    fo.write('<script src="/sorttable.js" type="text/javascript"> </script>')
    fo.write('</head>\n')
    fo.write('<body>\n')
    fo.write('<h1>Bluebell Pipeline Dashboard</h1>\n')
    fo.write('<table>\n')
    fo.write('    <tr>\n')
    fo.write('        <td><b>Pipeline Status</b></td>\n')
    fo.write('        <td align="center"><b>'+ pipeline_status+ '</b></td>\n')
    fo.write('    </tr>\n')
    fo.write('    <tr>\n')
    fo.write('        <td>Targets total</td>\n')
    fo.write('        <td align="center">'+ str(n_targets_total)+ '</b></td>\n')
    fo.write('    </tr>\n')
    fo.write('    <tr>\n')
    fo.write('        <td>Targets in progress</td>\n')
    fo.write('        <td align="center">'+ str(n_targets_in_progress)+ '</b></td>\n')
    fo.write('    </tr>\n')
    fo.write('    <tr>\n')
    fo.write('        <td>Targets frozen</td>\n')
    fo.write('        <td align="center">'+ str(n_targets_frozen) + '</td>\n')
    fo.write('    </tr>\n')
    fo.write('    <tr>\n')
    fo.write('        <td>Targets failed</td>\n')
    fo.write('        <td align="center">'+ str(n_targets_failed) + '</td>\n')
    fo.write('    </tr>\n')
    fo.write('    <tr>\n')
    fo.write('        <td>Oldest completed target</td>\n')
    fo.write('        <td align="center">'+ oldest_completed.replace('T', ' ') + '</td>\n')
    fo.write('    </tr>\n')
    fo.write('</table>\n')
    fo.write('<h3>Target statuses</h3>\n')
    fo.write('<table class="sortable">\n')
    fo.write('    <tr>\n')
    fo.write('        <th>Target name</th>\n')
    fo.write('        <th>Last completed date</th>\n')
    fo.write('        <th>Status</th>\n')
    fo.write('        <th>Status date</th>\n')
    fo.write('        <th>Duration</th>\n')
    fo.write('        <th>Log</th>\n')
    fo.write('      </tr>\n')
    for record in tblStatus:
        log_url="https://geocint.kontur.io/geocint/logs/"+record[6]+"/" + record[0] + "/log.txt"  
        fo.write('      <tr class="'+record[2]+'">\n')
        fo.write('        <td>'+record[0]+'</td>\n') #target_name
        fo.write('        <td>'+record[1].replace('T', ' ')+'</td>\n') #last completed date
        fo.write('        <td>'+record[2]+'</td>\n') #status
        fo.write('        <td>'+record[3].replace('T', ' ')+'</td>\n') #time
        fo.write('        <td>'+record[4]+'</td>\n') #time
        fo.write('        <td> <a href ="' + log_url +'">'+'...'+'</a></td>\n') # log
        fo.write('      </tr>\n')

    fo.write('</table>\n')
    fo.write('</body>\n')
    fo.write('</html>\n')
 
    fo.close()

def processTargetStatus(target_name,target_status, status_date, dependencies, target_log_folder):
    #1. read file
    tblStatus = loadDatFile(dat_file_name)

    #2-#3. find record, update status and date

    index = -1
    for i in range(len(tblStatus)):
        if tblStatus[i][STATUS_TARGET_NAME] == target_name:
            index = i
            break 

    if index == -1:
        tblStatus.append([target_name, "", "", "", "", "", ""]) 

    target_duration = ""

    if (target_status == "completed") and (tblStatus[index][STATUS_TARGET_STATUS] == "started"):
        target_duration =  datetime.strptime(status_date, DATE_FORMAT) - datetime.strptime(tblStatus[index][STATUS_TARGET_STATUS_DATE], DATE_FORMAT) 

    tblStatus[index][STATUS_TARGET_STATUS] = target_status
    tblStatus[index][STATUS_TARGET_STATUS_DATE] = status_date

    if (target_status == "completed") :
        tblStatus[index][STATUS_TARGET_LAST_COMLETED_DATE] = status_date

    if str(target_duration) != "":
        tblStatus[index][STATUS_TARGET_DURATION] = str(target_duration)

    if dependencies != "": 
        tblStatus[index][STATUS_TARGET_DEPENDANCIES] = dependencies

    tblStatus[index][STATUS_TARGET_LOG_FOLDER] = target_log_folder
    


    #4. save file
    saveDatFile(tblStatus,dat_file_name)

    #5. update web-dashboard
    print_html(dashboard_file_name, tblStatus)
    return None

def processPipelineCompletion():
    #1. read file
    tblStatus = loadDatFile(dat_file_name)

    #2-#3. find record, update status. 
    #Pipeline completion just means that all started tasks are marked as failed.

    for i in range(len(tblStatus)):
        if tblStatus[i][STATUS_TARGET_STATUS] == "started":
            tblStatus[i][STATUS_TARGET_STATUS] = "failed"
            #status date is not changed, because the pipeline termination can occur a way after fail of particular task

    #4. save file
    saveDatFile(tblStatus,dat_file_name)

    #5. update web-dashboard
    print_html(dashboard_file_name, tblStatus)
    return None


#Main part
command = sys.argv[1]
if command == "target":
    target_name = sys.argv[2]
    target_status = sys.argv[3]
    if command == "target" and target_status == "started" : 
        dependencies = sys.argv[4]
    else:
      dependencies = ""
elif command == "pipeline":
    target_name = ""
    target_status = sys.argv[2]
elif command == "DB":
    pass
else:
    raise Exception('Command should be "target", "pipeline" or "DB" ')

if command == "target":
    processTargetStatus(target_name,target_status, datetime.now().strftime(DATE_FORMAT), dependencies, "")

elif command == "pipeline" and target_status == "completed":
    processPipelineCompletion()

elif command == "DB":
    DB = loadDatFile("c:/Bluebell/99_WebUI/make_profile.db", separator=" ")

   
    for record in DB:
        
        target_name = record[3]
        target_status_date = datetime.fromtimestamp(int(record[0])).strftime(DATE_FORMAT)
        target_log_folder = record[1]
        if record[2] =="start":
           target_status =  "started"
        elif record[2] =="finish":
            target_status =  "completed"
        else:
            raise Exception("unexpected status: " + str(record[2]))

        if target_status_date > "2022-11-15":
            print (target_status_date)
            processTargetStatus(target_name,target_status, target_status_date, "", target_log_folder )
           

    processPipelineCompletion()
