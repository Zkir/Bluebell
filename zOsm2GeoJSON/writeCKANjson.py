import sys
import os
from ma_dictionaries import Geoextent
from ma_dictionaries import FeatureCategory
from ma_dictionaries import FeatureSource

def escapeJsonString(s):
    s = s.replace("\"", "")
    s = s.replace("'","")
    s = s.replace("\\","\\\\") # single \ to double \\
    return s

# format CKAN tags. Limited set of chars is allowed
def format_tag(s):
    s = s.replace(" ", "_")
    s = s.replace("/", "_")
    return s.lower()

# we need to create file with metadate, to create dataset on CKAN, with metadata, tags and so forth.
def writeCKANJson(strOutputFileName, number_of_objects, strFilter, last_known_edit):
    path, fname = os.path.split(strOutputFileName)
    dataset_name = fname.split('.')[0]  # this file name without extention
    codes = dataset_name.split("_",7)

    geoextent = codes[0]
    category = codes[1]
    theme = codes[2]
    geometry_type = codes[3]
    scale = codes[4]
    source = codes[5]
    permission = codes[6]
    dataset_hum_name = codes[7]

    short_geoextent = Geoextent[geoextent]
    # dataset_title = geoextent.upper() + ' ' + dataset_hum_name.upper()
    dataset_title = dataset_hum_name.upper() + ' -- ' + short_geoextent
    dataset_description = 'This dataset contains ' + dataset_hum_name.upper() + \
                          ', extracted from '+ FeatureSource[source] +' data for ' + short_geoextent + '. '

    if str(number_of_objects) != "Unknown":
        dataset_description = dataset_description +  \
                             ' There are ' + str(number_of_objects) + ' objects. '
    if strFilter != "":
        dataset_description = dataset_description +  \
                              ' Original filter is ' + strFilter +  '.'

    if last_known_edit != "Unknown":
        dataset_description = dataset_description + \
                              ' Last known edit timestamp: ' + last_known_edit

    #it's not a json escaping, but  a particularly perverted bug of curl, it does not undertand equal sign
    dataset_description = dataset_description.replace("=", '%3D')

    strOutputFileName = os.path.join(path, dataset_name + '.CKAN.json')
    fo = open(strOutputFileName, 'w', encoding="utf-8")

    fo.write('{ \n')
    fo.write('    "name": "' + escapeJsonString(dataset_name) + '",\n')
    fo.write('    "title": "' + escapeJsonString(dataset_title) + '",\n')
    fo.write('    "notes": "' + escapeJsonString(dataset_description) + '",\n')
    fo.write('    "owner_org": "kontur",\n')
    if source == "osm":
        fo.write('    "url": "http://Openstreetmap.org",\n')
        fo.write('    "license_id": "odc-odbl",\n')
    elif source == "worldports":
        fo.write('    "url": "https://msi.nga.mil/Publications/WPI",\n')
        #fo.write('    "license_id": "odc-odbl",\n')
    elif source == "naturalearth":
        fo.write('    "url": "https://www.naturalearthdata.com",\n')
        fo.write('    "license_id": "other-pd",\n')
    elif source == "gppd":
        fo.write('    "url": "https://datasets.wri.org/dataset/globalpowerplantdatabase",\n')
        fo.write('    "license_id": "cc-by",\n')
    elif source == "wfp":
        fo.write('    "url": "https://geonode.wfp.org/layers",\n')
        # fo.write('    "license_id": "odc-odbl",\n')
    elif source == "ourairports":
        fo.write('    "url": "https://ourairports.com/data",\n')
        # fo.write('    "license_id": "odc-odbl",\n')

    fo.write('    "tags": [ \n')
    fo.write('             {"vocabulary_id": null,  "display_name": "'+escapeJsonString(FeatureCategory[category])+'",  "name": "' + escapeJsonString(format_tag(FeatureCategory[category]))+'"},\n')
    fo.write('             {"vocabulary_id": null,  "display_name": "'+ escapeJsonString(source) +'",  "name": "'+ escapeJsonString(format_tag(source)) +'"}], \n')

    fo.write('    "groups": [{"name": "' + escapeJsonString(geoextent)+'"}\n')
    fo.write('              ], \n')

    fo.write('    "extras": [ \n')
    fo.write('             {"key": "last_known_edit",      "value": "' + escapeJsonString(last_known_edit) + '"},\n')
    fo.write('             {"key": "geoextent",            "value": "' + escapeJsonString(geoextent) + '"},\n')
    fo.write('             {"key": "category",             "value": "' + escapeJsonString(category) + '"},\n')
    fo.write('             {"key": "theme",                "value": "' + escapeJsonString(theme) + '"}, \n')
    fo.write('             {"key": "geometry_type",        "value": "' + escapeJsonString(geometry_type) + '"},\n')
    fo.write('             {"key": "scale",                "value": "' + escapeJsonString(scale) + '"},\n')
    fo.write('             {"key": "source",               "value": "' + escapeJsonString(source) + '"},\n')
    fo.write('             {"key": "permission",           "value": "' + escapeJsonString(permission) + '"} ],\n')

    fo.write('    "resources": [\n')
    if geometry_type in ['pt','py','ln']:
        fo.write('        {"name":"'+escapeJsonString(dataset_title)+' in GeoJson format",\n')
        fo.write('         "url":"https://mekillot-backet.website.yandexcloud.net/datasets/'+escapeJsonString(dataset_name)+'.json.zip",\n')
        fo.write('         "format": "GeoJson"\n')
        fo.write('        },\n')
        fo.write('        {"name":"'+escapeJsonString(dataset_title)+' as ESRI shape",\n')
        fo.write('         "url":"https://mekillot-backet.website.yandexcloud.net/datasets/'+escapeJsonString(dataset_name)+'.shp.zip",\n')
        fo.write('         "format": "ESRI shape"\n')
        fo.write('        }\n')
    elif geometry_type == 'ras':
        fo.write('        {"name":"' + escapeJsonString(dataset_title) + ' in TIFF format",\n')
        fo.write('         "url":"https://mekillot-backet.website.yandexcloud.net/datasets/' + escapeJsonString(
            dataset_name) + '.tif.zip",\n')
        fo.write('         "format": "TIFF"\n')
        fo.write('        },\n')
    elif geometry_type == 'tab':
        fo.write('        {"name":"' + escapeJsonString(dataset_title) + ' in CSV format",\n')
        fo.write('         "url":"https://mekillot-backet.website.yandexcloud.net/datasets/' + escapeJsonString(
            dataset_name) + '.csv.zip",\n')
        fo.write('         "format": "CSV"\n')
        fo.write('        },\n')
    else:
        raise Exception ('Unknown geometry type: '+str(geometry_type))
    fo.write('        ]\n')

    fo.write('} \n')
    fo.close()


def writeCKANJsonCMF(strOutputFileName):
    path, fname = os.path.split(strOutputFileName)
    dataset_name = fname.split('.')[0]  # this file name without extention
    codes = dataset_name.split("_", 7)

    geoextent = codes[0]

    short_geoextent = Geoextent[geoextent]


    strOutputFileName = os.path.join(path, dataset_name + '.CKAN.json')
    fo = open(strOutputFileName, 'w', encoding="utf-8")
    fo.write('{ \n')
    fo.write('    "name": "'+dataset_name+'",\n')
    fo.write('    "title": "'+short_geoextent+' Crash Move Folder",\n')
    fo.write('    "notes": "This dataset contains '+ short_geoextent+' Crash Move Folder. Various layers are combined. This dataset is intended to be used for map making",\n')
    fo.write('    "url": "mapaction.org",\n')
    fo.write('    "owner_org": "kontur",\n')
    fo.write('    "tags": [\n')
    fo.write('             {"vocabulary_id": null,  "display_name": "cmf",  "name": "cmf"}\n')
    fo.write('            ], \n')
    fo.write('    "groups": [{"name": "'+geoextent+'"}\n')
    fo.write('              ], \n')
    fo.write('    "extras": [ \n')
    fo.write('             {"key": "last_known_edit", "value": "unknown"},\n')
    fo.write('             {"key": "geoextent",            "value": "'+ geoextent +'"},\n')
    fo.write('             {"key": "source",               "value": "osm"},\n')
    fo.write('             {"key": "permission",           "value": "pp"} ],\n')
    fo.write('    "resources": [\n')
    fo.write('        {"name":"'+short_geoextent+' Crash Move Folder in GeoJson format",\n')
    fo.write('         "url":"https://mekillot-backet.website.yandexcloud.net/cmfs/'+geoextent+'_cmf_json.zip",\n')
    fo.write('         "format": "GeoJson"\n')
    fo.write('        },\n')
    fo.write('        {"name":"'+short_geoextent+' Crash Move Folder as ESRI shape",\n')
    fo.write('         "url":"https://mekillot-backet.website.yandexcloud.net/cmfs/'+geoextent+'_cmf_shp.zip",\n')
    fo.write('         "format": "ESRI shape"\n')
    fo.write('        }]\n')
    fo.write('}\n')

    fo.close()
    return None


def main():
    strInputFileName = sys.argv[1]
    path, fname = os.path.split(strInputFileName)
    
    if len(fname.split("_")) == 2:
        command = 'cmf'
    else:
        command = 'dataset'


    if command == 'dataset':
        writeCKANJson(strInputFileName, "Unknown", "", "Unknown")
    elif command =='cmf':
        writeCKANJsonCMF(strInputFileName)
    else:
        raise Exception('Unknown command "' + command + '". Allowed commands are "dataset" and "cmf"')

if __name__ == '__main__':
    main()