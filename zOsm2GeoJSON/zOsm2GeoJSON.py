import time
import sys
from datetime import datetime
import os

from mdlOsmParser import readOsmXml, encodeXmlString
from mdlFilterParser import parse_filter
from mdlFilterParser import evaluate_tree


def escapeJsonString(s):
    s = s.replace("\"","" )
    s = s.replace("'","")
    s = s.replace("\\","\\\\") # single \ to double \\
    return s
    
#most uncertain part, we need to create parcer for osmfilter filter!     
def evaluateFilter(object_filter, osmtags):
    blnResult = evaluate_tree(object_filter, osmtags)
    return blnResult

def writeGeoJson(Objects, objOsmGeom, strOutputFile, strAction, allowed_tags):
    
    fo = open(strOutputFile, 'w', encoding="utf-8")
    fname = os.path.basename(strOutputFile)

    fo.write('{ \n') 
    fo.write('    "type": "FeatureCollection",\n')
    #fo.write('    "generator" : "bluebell-zOsm2GeoJSON",\n')
    #fo.write('    "generation_date" : "' + escapeJsonString(datetime.now().strftime("%Y-%m-%dT%H:%M:%S"))+'", \n')
    #fo.write('    "last_known_edit_date": "YYYY-MM-DD",\n')
    #fo.write('    "geoextent": "'+escapeJsonString(fname[0:3])+'",\n')
    #fo.write('    "category": "'+escapeJsonString(fname[4:8])+'",\n')
    #fo.write('    "theme": "'+escapeJsonString(fname[9:12])+'",\n')
    #fo.write('    "geometry_type": "'+escapeJsonString(fname[13:15])+'",\n')
    #fo.write('    "scale": "'+escapeJsonString(fname[16:18])+'",\n')
    #fo.write('    "source": "OpenStreetMap",\n')
    #fo.write('    "permission": "'+escapeJsonString(fname[23:25])+'",\n')
    fo.write('    "features": [\n')

    j=0
    for osmObject in Objects:
        if j!=0:
            fo.write(',\n')
        j=j+1  
        fo.write('        { \n') 
        fo.write('            "type": "Feature",\n')
        fo.write('            "properties": { \n') 
        fo.write('                "@id": "osm/'+osmObject.type +"/"+osmObject.id +'",\n')

        i=0
        for tag in osmObject.osmtags:
            
            if tag in allowed_tags:
                if i!=0:
                    fo.write(',\n')
                i=i+1
                key = tag
                value = osmObject.getTag(tag)  
                fo.write('                "'+escapeJsonString(key)+'": "'+ escapeJsonString(value) +'"')
        fo.write('\n')
        fo.write('            },\n') 
        if strAction == "write_poi":
            centroid_lon = (osmObject.bbox.minLon + osmObject.bbox.maxLon )/2
            centroid_lat = (osmObject.bbox.minLat + osmObject.bbox.maxLat )/2

            fo.write('            "geometry": {\n')
            fo.write('                "type": "Point",\n')
            fo.write('                "coordinates": [\n')
            fo.write('                    '+str(centroid_lon)+',\n')
            fo.write('                    '+str(centroid_lat)+'\n')
            fo.write('                ]\n')
            fo.write('            }\n')

        if (strAction == "write_lines") :
            if osmObject.type == 'way':
                fo.write('            "geometry": {\n')
                fo.write('                "type": "LineString",\n')
                fo.write('                "coordinates": [\n')              
                i=0
                for noderef in osmObject.NodeRefs:
                    if i!=0:
                        fo.write(',\n')
                    i=i+1  
                    fo.write('                    [' + str(objOsmGeom.GetNodeLon(noderef)) + ', ' + str(objOsmGeom.GetNodeLat(noderef)) + ']')
                fo.write('\n')
                fo.write('                ]\n')
                fo.write('            }\n')

            else:
               print ("Object " + osmObject.id + " skipped: only ways are supported for action write_lines")

        if (strAction == "write_poly"):
            if osmObject.type == 'way':
                fo.write('            "geometry": {\n')
                fo.write('                "type": "Polygon",\n')
                fo.write('                "coordinates": [\n')              
                i=0
                fo.write('                    [\n')                 
                for noderef in osmObject.NodeRefs:
                    if i!=0:
                        fo.write(',\n')
                    i=i+1 
                    fo.write('                        [' + str(objOsmGeom.GetNodeLon(noderef)) + ', ' + str(objOsmGeom.GetNodeLat(noderef)) + ']')
                fo.write('\n')
                fo.write('                    ]\n')
                fo.write('                ]\n')
                fo.write('            }\n')

            else:
                Outlines=objOsmGeom.ExtractCloseNodeChainFromRelation(osmObject.WayRefs)
                fo.write('            "geometry": {\n')
                fo.write('                "type": "Polygon",\n')
                fo.write('                "coordinates": [\n') 
                   
                for i in range(len(Outlines)):
                    if i!=0:
                            fo.write(',\n')
                    fo.write('                    [\n') 
                    for k in range(len(Outlines[i])):
                        if k!=0:
                            fo.write(',\n')
                        fo.write('                        [' + str(objOsmGeom.nodes[Outlines[i][k]].lon) + ', ' + str(objOsmGeom.nodes[Outlines[i][k]].lat) + ']')                    
                    fo.write('\n')
                    fo.write('                    ]')
                fo.write('\n')
                fo.write('                ]\n')
                fo.write('            }\n')
               



        fo.write('        }') 

    fo.write('\n')
    fo.write('    ]\n') 
    fo.write('}\n') 
    fo.close()
    print ("Completed: "+str(j)+" objects written")


# lets's filter out something, we are interested only in particular objects
def filterObjects(Objects, object_filter, strAction):
    SelectedObjects = []
    print(str(object_filter) + '\n')
    for osmObject in Objects:
        #print (str(osmObject.type)+str(osmObject.id))    
        #filter out objects without tabs. they cannot make any "features"
        blnFilter = len(osmObject.osmtags)>0 
        blnFilter = blnFilter and evaluateFilter(object_filter, osmObject.osmtags )
        #funny enough, filter depends on action too
        if (strAction == "write_lines") or (strAction == "write_poly"):

            #if target object type is line or polygon, nodes cannot be used.
            blnFilter = blnFilter and (osmObject.type !="node")

        if  (strAction == "write_poly"):
            if (osmObject.type =="way") :
                blnFilter = blnFilter and (osmObject.NodeRefs[0] == osmObject.NodeRefs[-1])


        if blnFilter:
            SelectedObjects.append(osmObject)
 
    return SelectedObjects

def writeTagStatistics(strOutputFileName, Objects):
    tags_stat = {}
    tags_stat_filtered = {}
    for osmObject in Objects:
       for tag in osmObject.osmtags:
           if tag in tags_stat:
               tags_stat[tag] = tags_stat[tag] + 1
           else:
               tags_stat[tag] = 1 
               
    
    if (len(tags_stat)>0):
        #сортировка
        tag_stat_sorted_as_list = sorted(tags_stat.items(), key=lambda item: item[1],reverse = True) #Сортировка словаря Python по значению
        
        tags_stat_sorted=dict(tag_stat_sorted_as_list)
        
        max_tag = list(tags_stat_sorted.keys())[0]
        max_count=tags_stat_sorted[max_tag] 
        
        #Фильтрация 1% персентиль 
        for tag in tags_stat_sorted.keys():
            if tags_stat[tag]/max_count >0.01:
                tags_stat_filtered[tag] = tags_stat_sorted[tag]
        
        #вывод 
        fo = open(strOutputFileName, 'w', encoding="utf-8")
        fo.write(str(len(tags_stat_sorted)) + " different tags totally \n" ) 
        
        print   ("1% tag filtering applied. " + str(len(tags_stat_filtered)) + " different tags retained out of " + str(len(tags_stat_sorted)))
        fo.write("1% tag filtering applied. " + str(len(tags_stat_filtered)) + " different tags retained out of " + str(len(tags_stat_sorted)) +'\n\n')
       
        i=0
        blnSeparatorPrinted = False 
        for tag in tags_stat_sorted.keys():
            i = i + 1
            if (tags_stat[tag]/max_count < 0.01) and (not blnSeparatorPrinted) :
                fo.write ('-------------------------------------------------------------- \n')
                blnSeparatorPrinted = True 
                
            fo.write('{:4d}.'.format(i)+' '+'{:25s}'.format(tag) + ': ' + '{:10s}'.format(str(tags_stat_sorted[tag])) +'      (' +  "{:.1f}".format(tags_stat_sorted[tag]/max_count*100)   + ' %)\n' )
                       

        fo.close()
    else: 
        print ("WARNING: no objects or no tags")
    return tags_stat_filtered

    
def createJson(strInputOsmFile, strOutputFileName,strAction,strFilter):
    print("input file: "+ strInputOsmFile)
    print("target file: "+ strOutputFileName)
    print ("action: " + strAction)
    print ("filter: " + strFilter)

    t1 = time.time()
    object_filter = parse_filter(strFilter)

    objOsmGeom, Objects = readOsmXml(strInputOsmFile)
    SelectedObjects = filterObjects(Objects, object_filter, strAction)

    allowed_tags = writeTagStatistics(strOutputFileName+'.stat.txt',SelectedObjects)
    
    writeGeoJson(SelectedObjects, objOsmGeom, strOutputFileName, strAction, allowed_tags)  #see former   processBuildings()


    t2 = time.time()
    print("File " + strInputOsmFile + " processed in "+str(t2-t1)+" seconds")

def main():
    
    if len(sys.argv)>1:
        strInputFileName = sys.argv[1]
        strOutputFileName = sys.argv[2]
        strAction = sys.argv[3]
        if strAction == "--action=write_lines":
            strAction="write_lines"
        elif strAction == "--action=write_poly":
            strAction="write_poly"
        elif strAction == "--action=write_poi":
            strAction="write_poi"
        else:
            raise Exception('Unknown action type: '+strAction+'  Availble actions are "write_poi", "write_lines", "write_poly"')

        strFilter=""
        for i in range(4, len(sys.argv)) :       
            strFilter = strFilter + ' ' + sys.argv[i]
            
        createJson(strInputFileName, strOutputFileName, strAction, strFilter)
        print('Thats all, folks!')
    else:
        print ('usage: zOsm2JSON input.osm [output.json]')


main()