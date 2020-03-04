Vertical differencing in OpenTopography

Author: Chelsea Scott

At its core, vertical differencing utilizes gdal_calc. https://gdal.org/programs/gdal_calc.html

gdal_calc -A compare.tif -B reference.tif --outfile=diff.tif --calc="B-A" --NoDataValue=-9999

vertical_differencing.pl - script that generates vertical differencing products as available in OpenTopography (hillshade images, histograms, etc.)
