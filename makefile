#===================================================================
# the main makefile for BlueBell [prototype] pipeline for MapAction
#===================================================================

# some tricks with folders 
vpath %.pbf data\in\mapaction\per_country_pbf data\in\planet.osm
vpath %.o5m data\in\mapaction\per_country_pbf data\in\planet.osm
vpath % data\vtargets  

# let's read definitions of operations, 
# how to produce datasets from different sources types, osm, csv, shp
include functions_make

#------------------------------------------------------------------------------------
# the main target. Do not forget to add country specific CMFs as pre-requisites here!
#------------------------------------------------------------------------------------
FINAL: tza_cmf blr_cmf
	echo That's all folks!


#------------------------------------------------------------------------------------
# Layer defintitions, they are included from country specific make files.
#------------------------------------------------------------------------------------

include tanzaina_make      
include belarus_make

#------------------------------------------------------------------------------------
# Global Data. OSM and other global sources. 
# Country specific datasest are created as extracts from those global data.
#------------------------------------------------------------------------------------

include globaldata_make

#the end!


