# planet.pbf-->Country.o5m --> feature.osm --> feature.geojson --> feature.shp

# planet.pbf: osmupdate 
# planet.pbf--> Country.o5m : osmconvert
# Country.o5m --> feature.osm: osmfilter
# 

define generate_file
	echo $< $@ 
	tools\osmfilter.exe 01_countries\$< $(1) -o=02_Interim_osm\$@.osm
	zOsm2GeoJSON\zOsm2GeoJSON.py 02_Interim_osm\$@.osm 99_Output\$@.json --action=$(2) --filter="$(1)"
	c:\OSGeo4W\bin\ogr2ogr.exe -skipfailures 99_output\$@.shp 99_output\$@.json	
	echo $@
endef


full_build: belarus_roads_lines \
            belarus_buildings_poly \
            belarus_main_roads_lines \
            belarus_railroads_lines \
            belarus_urbanrail_lines \
            belarus_dam_poi \
            belarus_education_school_poi \
            belarus_education_high_poi \
            belarus_ferry_terminal_poi \
            belarus_ferry_route_lines \
            belarus_port_poi \
            belarus_banks_poi \
            belarus_atm_poi \
            belarus_health_facilities_poi \
            belarus_hospitals_poi \
            belarus_marketplace_poi \
            belarus_place_of_worship_poi \
            belarus_refugee_site_poi \
            belarus_border_control_poi \
            belarus_settlements_poi \
            belarus_townscities_poi \
            belarus_bridges_poi \
            belarus_pipeline_lines \
            belarus_powerline_lines \
            belarus_powerstation_poi \
            belarus_substation_poi \
            belarus_natural_water_poly \
            belarus_militaryinstallation_poly \
            belarus_railway_station_poi \
            belarus_emergency_poi \
            belarus_water_source_poi \
            belarus_toilets_poi\
            belarus_admin0_boundary_poly \
            belarus_admin1_boundary_poly \
            belarus_admin2_boundary_poly \
            belarus_admin3_boundary_poly 

	echo All targets completed OK

#roads	
belarus_roads_lines: belarus-latest.o5m
	$(call generate_file, --keep= --keep-ways="highway=motorway =trunk =primary =secondary =tertiary  =unclassified =residential =motorway_link =trunk_link =primary_link =secondary_link =tertiary_link =lining_street =service =track =road",write_lines)

#main roads	
belarus_main_roads_lines: belarus-latest.o5m
	$(call generate_file, --keep= --keep-ways="highway=motorway =trunk =primary =secondary =tertiary =motorway_link =trunk_link =primary_link =secondary_link =tertiary_link",write_lines)

#railroads
belarus_railroads_lines: belarus-latest.o5m
	$(call generate_file, --keep= --keep-ways="railway=rail",write_lines)


#urban rail
belarus_urbanrail_lines: belarus-latest.o5m
	$(call generate_file, --keep= --keep-ways="railway=subway =tram",write_lines)


#dam
belarus_dam_poi: belarus-latest.o5m
	$(call generate_file, --keep="waterway=dam",write_poi)


#education_school
belarus_education_school_poi: belarus-latest.o5m
	$(call generate_file, --keep="amenity=school",write_poi)


#education_high
belarus_education_high_poi: belarus-latest.o5m
	$(call generate_file, --keep="amenity=college =university",write_poi)


#ferry terminal
belarus_ferry_terminal_poi: belarus-latest.o5m
	$(call generate_file, --keep="amenity=ferry_terminal",write_poi)

#ferry route
belarus_ferry_route_lines: belarus-latest.o5m
	$(call generate_file, --keep="route=ferry",write_lines)

#port
belarus_port_poi: belarus-latest.o5m
	$(call generate_file, --keep="( landuse=harbour =port ) or ( industrial=port ) ",write_poi)


#banks
belarus_banks_poi: belarus-latest.o5m
	$(call generate_file, --keep="amenity=bank",write_poi)


#atm: amenity=atm or amenity=bank + atm=yes
belarus_atm_poi: belarus-latest.o5m
	$(call generate_file, --keep="amenity=atm or ( amenity=bank and atm=yes )",write_poi)

#health_facilities
belarus_health_facilities_poi: belarus-latest.o5m 
	$(call generate_file, --keep="amenity=clinic =doctors =health_post =pharmacy =hospital",write_poi)	

#hospitals 
belarus_hospitals_poi: belarus-latest.o5m 
	$(call generate_file, --keep="amenity=hospital",write_poi)	


#market_place
belarus_marketplace_poi: belarus-latest.o5m 
	$(call generate_file, --keep="amenity=marketplace",write_poi)	


#place_of_worship
belarus_place_of_worship_poi: belarus-latest.o5m
	$(call generate_file, --keep="amenity=place_of_worship",write_poi)


#refugee_site
belarus_refugee_site_poi: belarus-latest.o5m
	$(call generate_file, --keep="amenity=refugee_site",write_poi)


#border_control
belarus_border_control_poi: belarus-latest.o5m
	$(call generate_file, --keep="barrier=border_control",write_poi)

#Settlements
belarus_settlements_poi: belarus-latest.o5m
	$(call generate_file, --keep="place=city =borough =town =village =hamlet",write_poi)


#townscities
belarus_townscities_poi: belarus-latest.o5m
	$(call generate_file, --keep="place=city =town",write_poi)

#Buildings!
belarus_buildings_poly: belarus-latest.o5m
	$(call generate_file, --keep="building= ",write_poly)

#bridges
belarus_bridges_poi: belarus-latest.o5m
	$(call generate_file, --keep="man_made=bridge",write_poi)

#pipeline
belarus_pipeline_lines: belarus-latest.o5m
	$(call generate_file, --keep="man_made=pipeline",write_lines)

#powerline
belarus_powerline_lines: belarus-latest.o5m
	$(call generate_file, --keep="power=line",write_lines)

#powerstation
belarus_powerstation_poi: belarus-latest.o5m
	$(call generate_file, --keep="power=plant",write_poi)

#substation
belarus_substation_poi: belarus-latest.o5m
	$(call generate_file, --keep="power=substation",write_poi)


#natural=water
belarus_natural_water_poly: belarus-latest.o5m 
	$(call generate_file, --keep="natural=water",write_poly)	

belarus_militaryinstallation_poly: belarus-latest.o5m 
	$(call generate_file, --keep="landuse=military or military= ",write_poly)

belarus_railway_station_poi: belarus-latest.o5m 
	$(call generate_file, --keep="railway=station =halt ",write_poi)

#emergency 
belarus_emergency_poi: belarus-latest.o5m 
	$(call generate_file, --keep="emergency=assembly_point",write_poi)

#water source 
belarus_water_source_poi: belarus-latest.o5m 
	$(call generate_file, --keep="amenity=drinking_water or drinking_water=yes ",write_poi)

#toilets
belarus_toilets_poi: belarus-latest.o5m 
	$(call generate_file, --keep="amenity=toilets",write_poi)

belarus_admin0_boundary_poly: belarus-latest.o5m
	$(call generate_file, --keep="( boundary=administrative ) and ( admin_level=2 )",write_poly)

belarus_admin1_boundary_poly: belarus-latest.o5m
	$(call generate_file, --keep="boundary=administrative and admin_level=4",write_poly)

belarus_admin2_boundary_poly: belarus-latest.o5m
	$(call generate_file, --keep="boundary=administrative and admin_level=6",write_poly)

belarus_admin3_boundary_poly: belarus-latest.o5m
	$(call generate_file, --keep="boundary=administrative admin_level=7 =8 =9 =10",write_poly)



#==================Country ==================================================================

belarus-latest.o5m:
	echo just assume that the county file is present
  
