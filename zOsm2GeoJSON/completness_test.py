import os
from ma_dictionaries import Geoextent
#====================================================================================
# home-brew relational DB interface
# plain files pipe (|) separated
#====================================================================================
def loadDatFile(strInputFile, encoding="utf-8", separator="|",skipheaders=False ):
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
        if skipheaders:
            cells.pop(0)
    return cells


FLD_GROUP = 0
FLD_DESCR = 1
FLD_SOURCE = 2
FLD_CATEGORY = 3
FLD_THEME = 4
FLD_TYPE = 5


def get_datasets_filenames(geoextent, files_folder):
    filtered_files = []
    files = os.listdir(files_folder)
    for file in files:
        if (file[0:3] == geoextent) and (file.split('.')[-1] == 'zip'):
            filtered_files.append(file)

    return filtered_files

def get_datasets_filenames2(geoextent, files_folder):
    datasets = []
    for (root, dirs, files) in os.walk(files_folder, topdown=True):
        for file in files:
            if (file[0:3] == geoextent) or (file[0:3] == 'reg'):
                dataset_name = file.split('.')[0]
                if datasets.count(dataset_name) == 0:
                    print (dataset_name)
                    datasets.append(dataset_name)


    return datasets

def match_datsets(record, files,geoextent_all):
    matched_datasets = []
    for f in files:
        dataset_name = f.split('.',)[0]
        codes = dataset_name.split("_", 7)

        geoextent = codes[0]
        category = codes[1]
        theme = codes[2]
        geometry_type = codes[3]
        scale = codes[4]
        source = codes[5]
        permission = codes[6]
        if len(codes) >= 8:
            dataset_hum_name = codes[7]
        else:
            dataset_hum_name =''

        rec_geoextent = geoextent_all
        if (record[FLD_DESCR].lower().find('surrounding') != -1):
            rec_geoextent = 'reg'
        if geoextent==rec_geoextent \
                and category == record[FLD_CATEGORY] \
                and (record[FLD_THEME]=='*' or theme==record[FLD_THEME]) \
                and (record[FLD_SOURCE]=='*' or record[FLD_SOURCE]==source)\
                and geometry_type==record[FLD_TYPE]:
            #print (dataset_name)
            if matched_datasets.count(dataset_name) == 0:
                matched_datasets.append(dataset_name)
    return matched_datasets

def print_html(strOutputFile,geoextent,dat,files):

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
    fo.write('<h1>Completeness report for '+ Geoextent[geoextent]+' </h1>\n')

    fo.write('<h3>Available datasets</h3>\n')
    fo.write('<table class="sortable">\n')
    fo.write('    <tr>\n')
    fo.write('        <th>Dataset</th>\n')
    fo.write('        <th>Source</th>\n')
    fo.write('        <th>Category</th>\n')
    fo.write('        <th>Theme</th>\n')
    fo.write('        <th>Type</th>\n')
    fo.write('        <th>Acquired Datasets</th>\n')
    fo.write('        <th>Date</th>\n')
    fo.write('      </tr>\n')

    for record in dat:
        x = match_datsets(record, files, geoextent)
        if len(x) > 0:
            table_row_class = "ok"
        else:
            table_row_class = "failed"


        fo.write('      <tr class="' +table_row_class + '">\n')
        #fo.write('        <td>' + record[0] + '</td>\n')
        fo.write('        <td>' + record[1] + '</td>\n')
        fo.write('        <td>' + record[2] + '</td>\n')
        fo.write('        <td>' + record[3] + '</td>\n')
        fo.write('        <td>' + record[4] + '</td>\n')
        fo.write('        <td>' + record[5] + '</td>\n')
        fo.write('        <td>')
        for xx in x:
            fo.write(str(xx)+'<br />')
        fo.write('</td>\n')
        fo.write('        <td>' + '' + '</td>\n')
        fo.write('      </tr>\n')

    fo.write('</table>\n')
    fo.write('</body>\n')
    fo.write('</html>\n')

    fo.close()


def main():
    geoextent = "tza"
    strOutputFile = "c:/bluebell/99_WebUI/"+geoextent + "completeness.html"
    #files = get_datasets_filenames(geoextent,'c:/bluebell/91_Output_zipped')
    files = get_datasets_filenames2(geoextent, 'c:/bluebell/90_Output/tza')
    #files = get_datasets_filenames2(geoextent, 'c:/bluebell/96-Sample')


    dat = loadDatFile("c:/bluebell/completeness_test.csv", separator=',', skipheaders=True)
    print_html(strOutputFile,geoextent,dat,files)


if __name__ == '__main__':
    main()
