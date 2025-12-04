# Python Scripts for Raster Data Processing

## Overview
This repository contains **Python scripts for raster-based analysis** in ecological and remote-sensing studies.  
Each script is fully independent and can be directly applied or adapted to your own datasets.


## Script Overview

| File | Function |
|------|----------|
| **1-slope_analysis.py** | Calculate pixel-wise linear regression slope for long-term raster time series |
| **2-correlation_analysis.py** | Calculate correlation (e.g., Pearson) between two rasters and export results |
| **3-raster_calculation.py** | Perform pixel-wise raster math (e.g., subtraction, averaging, normalization) |

## Dependencies
**Typical Python environment**:
python >= 3.8

**Required libraries**:
numpy
rasterio
osgeo (GDAL)
matplotlib
scipy

**Install example**:
pip install numpy rasterio matplotlib scipy

## Usage
1. **Prepare Input Data** 
   - Organize rasters into folders 
   - Check spatial reference (projection, resolution, extent)
2. **Run Thematic Scripts**
3. **Export Outputs**
   - GeoTIFFs for mapping / further GIS analysis 
   - CSV tables for statistical modeling or visualization in R / Python
  
## Applications
- Remote sensing raster processing
- Environmental & ecological spatial analysis
- Pre-processing for mapping & machine-learning models

## Author
Xiaoyu Li, 2025

## Contact
If you are interested in collaboration or research discussion:  
Email: *xiaoyu6936@gmail.com*  
Personal Website: *https://xiaoyu0618.github.io/*  
