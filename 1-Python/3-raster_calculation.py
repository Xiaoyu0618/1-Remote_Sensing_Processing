import os
import arcpy
from arcpy.sa import *

arcpy.CheckOutExtension("ImageAnalyst")
arcpy.CheckOutExtension("spatial")

# Input workspace of raster files
inws = r"D:\DATA\04_T"
arcpy.env.workspace = inws

# Output table (text file)
OutputFile = open('D:/08_Mean_Value/Mean.txt'.decode('utf-8'), 'w')

# List all .tif rasters
rasters = arcpy.ListRasters("*", "tif")
print(rasters)

whereClause = "VALUE = 0"

for ras in rasters:
    # Remove invalid pixel values for mean calculation
    outSetNull = SetNull(ras, ras, whereClause)

    meanValueInfo = arcpy.GetRasterProperties_management(outSetNull, 'MEAN')
    # MINIMUM — The minimum pixel value within the raster.
    # MAXIMUM — The maximum pixel value within the raster.
    # MEAN — The mean (average) value of all pixels in the raster.
    # STD — The standard deviation of all pixel values in the raster.
    # TOP — The top boundary value of the extent (YMax).
    # LEFT — The left boundary value of the extent (XMin).
    # RIGHT — The right boundary value of the extent (XMax).
    meanValue = meanValueInfo.getOutput(0)
    print os.path.basename(ras).split('_')[0] + ',' + str(meanValue) + '\n'
    OutputFile.write(os.path.basename(ras).split('_')[0] + ',' + str(meanValue) + '\n')

OutputFile.close()
print("All completed successfully!")