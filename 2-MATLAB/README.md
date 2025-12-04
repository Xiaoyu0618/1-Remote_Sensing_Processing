# MATLAB Scripts for Raster Data Analysis

This repository includes lightweight MATLAB scripts for **trend detection** and **NetCDF raster export**, frequently used in ecological and climate remote-sensing analysis. All scripts are self-contained and easy to adapt to any similar dataset.

## Script Overview

| File | Purpose |
|------|---------|
| **1-mk_sen_trend.m** | Perform Mann–Kendall statistical test and Sen’s slope calculation to detect trend direction and significance for raster time series |
| **2-NC_TIF_12m.m** | Convert multi-year NetCDF data into monthly GeoTIFF images |

## Usage
### 1. Prepare Data
   - Organize rasters into folders 
   - Confirm the data has correct: spatial reference (projection), resolution, extent alignment
### 2. Run a Script
### 3. Export Outputs
   - Ready for mapping / further GIS processing in ArcGIS/QGIS

## Applications

- Long-term change trend detection and significance test
- NetCDF batch export for further GIS analysis

## Author
Xiaoyu Li, 2025

## Contact
If you are interested in collaboration or research discussion:  
Email: *xiaoyu6936@gmail.com*  
Personal Website: *https://xiaoyu0618.github.io/*  

