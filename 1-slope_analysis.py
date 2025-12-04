# -*- coding: utf-8 -*-
import arcpy
arcpy.CheckOutExtension("spatial")
from arcpy.sa import *
import math

# Allow overwriting existing outputs
arcpy.CheckOutExtension("spatial")
arcpy.env.overwriteOutput = True

# Input workspace with yearly rasters
workspace1 = r"H:\\year"
arcpy.env.workspace = unicode(workspace1, "utf8")

# List temperature rasters (e.g., tem2001.tif, tem2002.tif, ...)
ys = arcpy.ListRasters("tem*", "TIF")

# Build time-series index rasters
i = 0  # Initialize index

for y in ys:
    i = i + 1
    out = r"H:\\year/"
    if i < 10:
        out1 = unicode(out, "utf8") + "30" + str(i)
    else:
        out1 = unicode(out, "utf8") + "3" + str(i)
    outx = Con(y > -10, i, y)
    outx.save(out1)


# Read time index rasters and original rasters
arcpy.env.workspace = unicode(workspace1, "utf8")
xs = arcpy.ListRasters("3*", "GRID")

print ys
print len(ys)
print xs
print len(xs)

# Linear regression
x_ = CellStatistics(xs, "MEAN", "DATA")
y_ = CellStatistics(ys, "MEAN", "DATA")

n = len(xs)

xs_ys_sum = 0
xs_2_sum = 0

for i in range(0, len(xs)):
    xs_ys_sum = Raster(xs[i]) * Raster(ys[i]) + xs_ys_sum
    xs_2_sum = Raster(xs[i]) * Raster(xs[i]) + xs_2_sum

k = (xs_ys_sum - n * n * x_ * y_) / (n * xs_2_sum - (n * x_) ** 2)
b = y_ - k * x_

# Save slope raster (trend)
outpath1 = r"H:\\mk/"
sty1 = "temr"
out1 = outpath1 + sty1
k.save(out1)

# Correlation calculation
def calc_corr(a, b):
    E_a = CellStatistics(a, "MEAN", "DATA")
    E_b = CellStatistics(b, "MEAN", "DATA")

    a_i = [Raster(a[i]) - E_a for i in range(len(a))]
    b_i = [Raster(b[i]) - E_b for i in range(len(b))]

    ab = [a_i[i] * b_i[i] for i in range(len(a_i))]
    E_ab = CellStatistics(ab, "MEAN", "DATA")

    sq_a = [(Raster(a[i]) - E_a) ** 2 for i in range(len(a))]
    sq_b = [(Raster(b[i]) - E_b) ** 2 for i in range(len(b))]

    D_a = CellStatistics(sq_a, "MEAN", "DATA")
    D_b = CellStatistics(sq_b, "MEAN", "DATA")

    q_a = D_a ** 0.5
    q_b = D_b ** 0.5

    return E_ab / (q_a * q_b)


r = calc_corr(ys, xs)

out = r"H:\\slope/"
out1 = unicode(out, "utf8") + "temvir"
r.save(out1)
