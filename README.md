[![NSF-1948997](https://img.shields.io/badge/NSF-1948997-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1948997) 
[![NSF-1948994](https://img.shields.io/badge/NSF-1948994-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1948994)
[![NSF-1948857](https://img.shields.io/badge/NSF-1948857-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1948857)

Vertical differencing in OpenTopography

Author: Chelsea Scott

At its core, vertical differencing utilizes gdal_calc. https://gdal.org/programs/gdal_calc.html

gdal_calc -A compare.tif -B reference.tif --outfile=diff.tif --calc="B-A" --NoDataValue=-9999

vertical_differencing.pl - script that generates vertical differencing products as available in OpenTopography (hillshade images, histograms, etc.)
