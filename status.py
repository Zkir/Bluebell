import time
import sys
from datetime import datetime
import os
import os.path

#====================================================================================
# home-brew relational DB interface
# plain files pipe (|) separated
#====================================================================================
def loadDatFile(strInputFile, encoding="utf-8"):
    cells = []
    if os.path.exists(strInputFile):
        filehandle = open(strInputFile, 'r', encoding=encoding)
        txt = filehandle.readline().strip()
        while len(txt) != 0:
            if txt[0:1] != "#":
                row = txt.strip().split("|")
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
    tblStatus = sorted(tblStatus1, key = lambda record : record[2],reverse=True)
     
    pipeline_status='Idle' 
    n_targets_in_progress = 0
    n_targets_frozen = 0
    n_targets_failed = 0
    oldest_completed = ''

    for record in tblStatus:
        if record[1] == "started":
            pipeline_status='Up and Running'
            n_targets_in_progress = n_targets_in_progress + 1  
        elif record[1] == "failed":
            n_targets_failed = n_targets_failed + 1
        elif record[1] == "completed":
            if oldest_completed == '':
                oldest_completed = record[2]
            elif oldest_completed>record[2]:
                oldest_completed = record[2]


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
    fo.write('</style>\n')
    fo.write('</head>\n')
    fo.write('<body>\n')
    fo.write('<h1>Bluebell Pipeline Dashboard</h1>\n')
    fo.write('<table>\n')
    fo.write('    <tr>\n')
    fo.write('        <td><b>Pipeline Status</b></td>\n')
    fo.write('        <td align="center"><b>'+ pipeline_status+ '</b></td>\n')
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
    fo.write('<table>\n')
    fo.write('    <tr>\n')
    fo.write('        <th>Target name</th>\n')
    fo.write('        <th>Status</th>\n')
    fo.write('        <th>Status date</th>\n')
    fo.write('        <th>Duration</th>\n')
    fo.write('      </tr>\n')
    for record in tblStatus:
        fo.write('      <tr class="'+record[1]+'">\n')
        fo.write('        <td>'+record[0]+'</td>\n') #target_name
        fo.write('        <td>'+record[1]+'</td>\n') #status
        fo.write('        <td>'+record[2].replace('T', ' ')+'</td>\n') #time
        fo.write('        <td>'+record[3]+'</td>\n') #time
        fo.write('      </tr>\n')

    fo.write('</table>\n')
    fo.write('</body>\n')
    fo.write('</html>\n')
 
    fo.close()


target_status = sys.argv[1]
target_name = sys.argv[2]
DATE_FORMAT = "%Y-%m-%dT%H:%M:%S"
current_timestamp = datetime.now().strftime(DATE_FORMAT)

dat_file_name="C:/Bluebell/99_WebUI/status.dat"
dashboard_file_name="C:/Bluebell/99_WebUI/index.html"
#1. read file
tblStatus = loadDatFile(dat_file_name)


#2-#3. find record, update status and date
blnRecordFound = False
for record in tblStatus:
    if record[0] == target_name:
        target_duration = ""
        if (target_status == "completed") and (record[1] == "started"):
            target_duration =  datetime.now() - datetime.strptime(record[2], DATE_FORMAT) 
        record[1] = target_status
        record[2] = current_timestamp
        if str(target_duration) != "":
            record[3] = str(target_duration)
        blnRecordFound = True
        break 

if not blnRecordFound:
    tblStatus.append([target_name,target_status, current_timestamp,"" ])


#4. save file
saveDatFile(tblStatus,dat_file_name)


#5. update web-dashboard
print_html(dashboard_file_name, tblStatus)