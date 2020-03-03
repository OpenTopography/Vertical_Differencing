Author: Chelsea Scott

This is the code for the vertical differencing.

gdal_calc -A compare.tif -B reference.tif --outfile=diff.tif --calc="B-A" --NoDataValue=-9999
