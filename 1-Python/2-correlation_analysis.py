# -*- coding: utf-8 -*-
import arcpy
arcpy.CheckOutExtension("spatial")
from arcpy.sa import *

# Set workspace
workspace1 = r"D:\tem80\cor"
arcpy.env.workspace = unicode(workspace1, "utf8")

# List raster time-series (example: vegetation vs. temperature)
evi = arcpy.ListRasters("npp*", "TIF")
tem = arcpy.ListRasters("tem*", "TIF")

print len(evi), evi
print len(tem), tem


def calc_corr(a, b):
    E_a = CellStatistics(a, "MEAN", "DATA")
    E_b = CellStatistics(b, "MEAN", "DATA")

    ab = [Raster(a[i]) * Raster(b[i]) for i in range(len(a))]
    E_ab = CellStatistics(ab, "MEAN", "DATA")
    cov_ab = E_ab - E_a * E_b

    sq_a = [(Raster(a[i])) ** 2 for i in range(len(a))]
    sq_b = [(Raster(b[i])) ** 2 for i in range(len(b))]

    D_a = CellStatistics(sq_a, "MEAN", "DATA") - E_a ** 2
    D_b = CellStatistics(sq_b, "MEAN", "DATA") - E_b ** 2

    q_a = D_a ** 0.5
    q_b = D_b ** 0.5

    corr_factor = cov_ab / (q_a * q_b)
    return corr_factor

r = calc_corr(evi, tem)

# Save output
out = r"D:\tem80\cor\test/"
out1 = unicode(out, "utf8") + "cor"
r.save(out1)
