# Step 0. Bouvier Metrics + VCI (Complete Version)

library(lidR)
library(sf)
library(data.table)
library(dplyr)
library(ggplot2)
library(terra)

# Step 1. Parameters
k <- 0.5
dz <- 1
z0 <- 2

# Step 2. File Paths
plot_data <- st_read("H:/data/plots/Plot4ha4-4_0.25ha.gpkg")
dtmParacou <- rast("H:/data/rasters/DTM_Paracou_2019_50cm.tif")
laz_folder <- "H:/data/ALS/Paracou_2019"
laz_files <- list.files(laz_folder, pattern = "^Par2019Plot.*\\.laz$", full.names = TRUE)
output_dir <- "H:/output/AGB_metrics_0.25ha/"
output_metrics <- file.path(output_dir, "Metrics_Bouvier_VCI_PC_0.25ha.csv")

# Step 3. Calculate Global zmax (99th Percentile)
all_heights <- c()

for (laz_file in laz_files) {
  plot_name <- gsub("Par2019Plot|\\.laz", "", basename(laz_file))
  cat("Scanning heights in Plot:", plot_name, "\n")
  
  las <- readLAS(laz_file, filter = "-drop_class 7")
  las_norm <- normalize_height(las, dtmParacou)
  
  all_heights <- c(all_heights, las_norm$Z[las_norm$Z > 0])
  
  rm(las, las_norm)
  gc()
}

zmax_global <- quantile(all_heights, 0.99, na.rm = TRUE)
cat("\n>>> Global zmax (99th percentile):", round(zmax_global, 2), "m <<<\n")
cat(">>> Total height samples:", length(all_heights), "<<<\n\n")
range(all_heights)

zmax_global <- 41

# Step 4. Main Calculation Loop
bouvier_metrics <- data.frame()

for (laz_file in laz_files) {
  
  plot_name <- gsub("Par2019Plot|\\.laz", "", basename(laz_file))
  target_plot <- plot_name

  cat("Processing Plot:", target_plot, "\n")
  
  plot_subplots <- plot_data[plot_data$Plot == target_plot, ]
  
  if (nrow(plot_subplots) == 0) {
    cat("Warning: No subplot boundaries for Plot", target_plot, "\n")
    next
  }
  
  las <- readLAS(laz_file, filter = "-drop_class 7")
  las_norm <- normalize_height(las, dtmParacou)
  projection(las_norm) <- st_crs(plot_data)$wkt
  
  unique_subplots <- unique(plot_subplots$SubPlot)
  
  for (subplot in unique_subplots) {
    
    cat("\n--- SubPlot:", subplot, "---\n")
    
    subplot_poly <- plot_subplots[plot_subplots$SubPlot == subplot, ]
    las_subplot <- clip_roi(las_norm, subplot_poly)
    
    if (is.null(las_subplot) || length(las_subplot$Z) == 0) {
      cat("  Warning: No points in SubPlot", subplot, "\n")
      next
    }
    
    # Extract returns
    z_first <- las_subplot$Z[las_subplot$ReturnNumber == 1]
    z_all <- las_subplot$Z
    
    if (length(z_first) == 0) {
      cat("  Warning: No first returns in SubPlot", subplot, "\n")
      next
    }
    
    # Metric 1: μ_CH (Mean Canopy Height)
    # Bouvier p.325: "mean height of FIRST RETURNS above 2m"
    z_canopy <- z_first[z_first > z0]
    
    # ALL returns for CV_LAD and VCI
    if (length(z_canopy) > 0) {
      MCH_PC <- mean(z_canopy)
    } else {
      MCH_PC <- NA
    }

    # Metric 2: σ²_CH (Canopy Height Variance)
    # Bouvier p.325: "standard deviation of FIRST RETURN heights above 2m"
    if (length(z_canopy) > 1) {
      sigma2_CH_PC <- var(z_canopy)
    } else {
      sigma2_CH_PC <- NA
    }

    # Metric 3: Pf (Gap Fraction)
    # Bouvier p.325: "ratio of FIRST RETURNS ≤ threshold to total FIRST RETURNS"
    # THIS IS A SIMPLE CUMULATIVE RATIO - NOT gap_fraction_profile!
    Pf_2m_PC <- sum(z_first <= 2) / length(z_first)
    Pf_5m_PC <- sum(z_first <= 5) / length(z_first)
    Pf_10m_PC <- sum(z_first <= 10) / length(z_first)
    
    # Metric 4: CV_LAD (Coefficient of Variation of LAD)
    # Bouvier p.326: Uses gap_fraction_profile internally via LAD()
    # LAD() uses ALL returns
    lad_profile <- LAD(z_all, dz = dz, k = k, z0 = z0)
    lad_valid <- lad_profile$lad[lad_profile$lad > 0 & !is.na(lad_profile$lad)]
    
    if (length(lad_valid) >= 2) {
      CV_LAD_PC <- sd(lad_valid) / mean(lad_valid)
    } else {
      CV_LAD_PC <- NA
    }
    
    # Metric 5: VCI (Vertical Complexity Index)
    # van Ewijk et al. (2011): Normalized Shannon entropy
    # Uses ALL returns above z0, normalized to global zmax
    z_all_above2m <- z_all[z_all > z0]
    
    if (length(z_all_above2m) >= 2) {
      VCI_PC <- VCI(z_all_above2m, zmax = zmax_global, by = 1)
    } else {
      VCI_PC <- NA
    }

    # Additional metrics
    PAI_above2m_PC <- sum(lad_profile$lad, na.rm = TRUE)
    PAI_above10m_PC <- sum(lad_profile$lad[lad_profile$z >= 10], na.rm = TRUE)
    
    height_quantiles <- quantile(
      z_first, 
      probs = c(0.05, 0.10, 0.20, 0.30, 0.40, 
                0.50, 0.60, 0.70, 0.80, 0.90), 
      na.rm = TRUE
    )

    # Quality control
    n_first_returns_PC <- length(z_first)
    n_all_returns_PC <- length(z_all)
    n_canopy_points_PC <- length(z_canopy)
    pct_canopy_PC <- length(z_canopy) / length(z_first) * 100
    return_ratio_PC <- n_all_returns_PC / n_first_returns_PC

    # Store results
    bouvier_metrics <- rbind(bouvier_metrics, data.frame(
      Plot = target_plot,
      SubPlot = subplot,
      MCH_PC = MCH_PC,
      sigma2_CH_PC = sigma2_CH_PC,
      Pf_2m_PC = Pf_2m_PC,
      CV_LAD_PC = CV_LAD_PC,
      VCI_PC = VCI_PC,
      Pf_5m_PC = Pf_5m_PC,
      Pf_10m_PC = Pf_10m_PC,
      PAI_above2m_PC = PAI_above2m_PC,
      PAI_above10m_PC = PAI_above10m_PC,
      H_p05_PC = height_quantiles[1],
      H_p10_PC = height_quantiles[2],
      H_p20_PC = height_quantiles[3],
      H_p30_PC = height_quantiles[4],
      H_p40_PC = height_quantiles[5],
      H_p50_PC = height_quantiles[6],
      H_p60_PC = height_quantiles[7],
      H_p70_PC = height_quantiles[8],
      H_p80_PC = height_quantiles[9],
      H_p90_PC = height_quantiles[10],
      H_max_PC = max(z_first, na.rm = TRUE),
      n_first_returns_PC = n_first_returns_PC,
      n_all_returns_PC = n_all_returns_PC,
      n_canopy_points_PC = n_canopy_points_PC,
      pct_canopy_PC = pct_canopy_PC,
      return_ratio_PC = return_ratio_PC
    ))
    
    cat(sprintf(
      "  MCH=%.2f | σ²=%.2f | Pf=%.3f%% | CV_LAD=%.3f | VCI=%.3f\n",
      MCH_PC, sigma2_CH_PC, Pf_2m_PC*100, CV_LAD_PC, VCI_PC
    ))
  }
  
  rm(las, las_norm)
  gc()
  
  cat("\nFinished Plot", target_plot, "\n")
}

# Step 5. Save Metrics
fwrite(bouvier_metrics, output_metrics)

cat("\n========================================\n")
cat("Metrics saved to:", output_metrics, "\n")
cat("========================================\n")

# Step 6. Summary Statistics
cat("\n========== Summary Statistics ==========\n")
cat("Total subplots:", nrow(bouvier_metrics), "\n")
cat("Global zmax used for VCI:", round(zmax_global, 2), "m\n\n")

cat("FIVE CORE METRICS:\n\n")
summary_core <- summary(bouvier_metrics[, c("MCH_PC", "sigma2_CH_PC", "Pf_2m_PC", "CV_LAD_PC", "VCI_PC")])
print(summary_core)

cat("\n\nCORRELATION MATRIX:\n")
cor_matrix <- cor(
  bouvier_metrics[, c("MCH_PC", "sigma2_CH_PC", "Pf_2m_PC", "CV_LAD_PC", "VCI_PC")], 
  use = "complete.obs"
)
print(round(cor_matrix, 3))

# Step 7. Visualization
cat("\n========== Creating Visualizations ==========\n")

# Plot 1: Five core metrics
par(mfrow = c(2, 3))
hist(
  bouvier_metrics$MCH_PC, 
  main = "μ_CH (First Returns > 2m)", 
  xlab = "MCH_PC (m)", col = "steelblue", breaks = 20
)
hist(
  bouvier_metrics$sigma2_CH_PC, 
  main = "σ²_CH (First Returns > 2m)", 
  xlab = "sigma2_CH_PC (m²)", col = "forestgreen", breaks = 20
)
hist(
  bouvier_metrics$Pf_2m_PC * 100, 
  main = "Pf (Simple Ratio Method)", 
  xlab = "Pf_2m_PC (%)", col = "coral", breaks = 20
)
hist(
  bouvier_metrics$CV_LAD_PC, 
  main = "CV_LAD (All Returns)", 
  xlab = "CV_LAD_PC", col = "purple", breaks = 20
)
hist(
  bouvier_metrics$VCI_PC, 
  main = "VCI (All Returns > 2m)", 
  xlab = "VCI_PC", col = "darkred", breaks = 20
)
plot.new()
text(
  0.5, 0.5, paste0("Global zmax = ", round(zmax_global, 2), " m"), 
  cex = 1.5, font = 2
)
par(mfrow = c(1, 1))

# Plot 2: Height percentiles
percentile_cols <- c(
  "H_p05_PC", "H_p10_PC", "H_p20_PC", "H_p30_PC", "H_p40_PC",
  "H_p50_PC", "H_p60_PC", "H_p70_PC", "H_p80_PC", "H_p90_PC"
)
percentile_labels <- c(
  "5%", "10%", "20%", "30%", "40%", 
  "50%", "60%", "70%", "80%", "90%"
)

# Plot 3: Correlation scatter plots (5 metrics)
boxplot(
  bouvier_metrics[, percentile_cols],
  main = "Height Distribution (First Returns)",
  ylab = "Height (m)",
  col = colorRampPalette(c("lightblue", "darkblue"))(10),
  names = percentile_labels,
  las = 2
)

pairs(
  bouvier_metrics[, c("MCH_PC", "sigma2_CH_PC", "Pf_2m_PC", "CV_LAD_PC", "VCI_PC")],
  main = "Bouvier Metrics + VCI Correlation",
  pch = 19, col = rgb(0, 0, 0, 0.3)
)

# Plot 4: VCI vs other complexity metrics
par(mfrow = c(1, 2))
plot(
  bouvier_metrics$CV_LAD_PC, bouvier_metrics$VCI_PC,
  xlab = "CV_LAD", ylab = "VCI",
  main = "VCI vs CV_LAD",
  pch = 19, col = rgb(0, 0, 1, 0.5)
)
abline(lm(VCI_PC ~ CV_LAD_PC, data = bouvier_metrics), col = "red", lwd = 2)

plot(
  bouvier_metrics$sigma2_CH_PC, bouvier_metrics$VCI_PC,
  xlab = "σ²_CH", ylab = "VCI",
  main = "VCI vs Height Variance",
  pch = 19, col = rgb(0, 0.5, 0, 0.5)
)
abline(lm(VCI_PC ~ sigma2_CH_PC, data = bouvier_metrics), col = "red", lwd = 2)
par(mfrow = c(1, 1))

cat("\n========== Processing Complete ==========\n")
