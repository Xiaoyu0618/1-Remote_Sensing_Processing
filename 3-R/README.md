# R Scripts for LiDAR Data Processing

This folder focuses on **data extraction, transformation, cleaning, and metric computation** to support downstream modeling and visualization. All scripts are **independent** and designed with **modular step-by-step sections** for easy customization.

## Script Overview

| File | Function |
|------|----------|
| **1-lidar_canopy_structure.R** | Compute canopy structural metrics from LiDAR point clouds, combined with a vertical complexity index (VCI). It processes multiple plots/subplots, extracts height information from first and all returns, and outputs structure metrics for ecological and forest biomass modeling applications.|

> More R scripts will be added as methods evolve.

## Dependencies
Most scripts rely on: lidR, terra, raster, sf, data.table, dplyr, ggplot2

Exact packages are listed at the top of each script.

## Usage
### 1. Prepare Data
- Organize LiDAR / raster / shapefile data into folders
- Ensure spatial reference consistency (CRS, resolution, extent)
- Configure input paths in script header
### 2. Run a Script
### 3. Export Outputs
- CSV tables for statistical modeling or visualization in R / Python

## Applications
- Forest canopy structure quantification  
- Spatiotemporal ecological monitoring
- Geospatial data preprocessing
- Remote-sensing product evaluation and feature generation

## Authors
**Junliu Yang**: Responsible for LiDAR point cloud processing and Plant Area Density/Index generation.   
PhD Student, CIRAD (French Agricultural Research Centre for International Development)  
MSc, Beijing Forestry University  

**Xiaoyu Li**: Responsible for data visualization, quality control, and documentation.   
BSc, Beijing Forestry University  

## Contact
If you are interested in collaboration or research discussion:  
Email: *xiaoyu6936@gmail.com*  
Personal Website: *https://xiaoyu0618.github.io/*  

