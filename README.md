This is Bluebell, a pipeline which produce GeoJSON and SHP files ("Datasets") from OSM according to definitions. It is some kind of a competior to Geofabrik. 


/tools folder should be in %path%

The main tool is GNU make. Please install it. 
https://sourceforge.net/projects/gnuwin32/
https://gnuwin32.sourceforge.net/packages/make.htm


ogr2ogr.exe is from OSGeo4W package.

osmconvert, osmupdate and osmfilter are OSM opensource tools


aria2
https://github.com/aria2/aria2/releases/tag/release-1.36.0

osmium
conda install -c conda-forge osmium-tool

ogr2org
conda install -c conda-forge gdal


Dependancies linux

#make
sudo apt install make

#aria2:
sudo apt install -y aria2

#osmium
sudo apt install -y osmium-tool

#osmupdate, osmconvert
sudo apt install osmctools

#curl
sudo apt install -y curl 

#aws
sudo apt install -y awscli 

#ogr2org/gdal
sudo apt install -y gdal-bin
