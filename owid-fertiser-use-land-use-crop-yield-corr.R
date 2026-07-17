# ==============================================================================
# Script: 01_owid_yield_analysis.R
# Author: Ariq Haidar
# Description: Analyzes global crop yields, fertilizer inputs, and land use.
#              Built entirely using native Base R.
# ==============================================================================

# --- 1. Fetch Datasets (OWID JSON APIs) ---
# Crop Yields
library(jsonlite)
# Fetch the data
yields <- read.csv("https://ourworldindata.org/grapher/yields-of-important-staple-crops.csv?v=1&csvType=full&useColumnShortNames=true")
# Fetch the metadata
yields_metadata <- fromJSON("https://ourworldindata.org/grapher/yields-of-important-staple-crops.metadata.json?v=1&csvType=full&useColumnShortNames=true")
# Fertilzer Use
# Fetch the data
fert <- read.csv("https://ourworldindata.org/grapher/fertilizer-use-nutrient.csv?v=1&csvType=full&useColumnShortNames=true")
# Fetch the metadata
fert_metadata <- fromJSON("https://ourworldindata.org/grapher/fertilizer-use-nutrient.metadata.json?v=1&csvType=full&useColumnShortNames=true")
# Land Use Requirements
# Fetch the data
land <- read.csv("https://ourworldindata.org/grapher/land-area-per-crop-type.csv?v=1&csvType=full&useColumnShortNames=true")
# Fetch the metadata
land_metadata <- fromJSON("https://ourworldindata.org/grapher/land-area-per-crop-type.metadata.json?v=1&csvType=full&useColumnShortNames=true")

# --- 2. Filter & Subset World Aggregates ---
# Subsetting observations (case-insensitive filter)
yields_world <- yields[grepl("^world$", yields$entity, ignore.case = TRUE), ]
fert_world   <- fert[grepl("^world$", fert$entity, ignore.case = TRUE), ]
land_world   <- land[grepl("^world$", land$entity, ignore.case = TRUE), ]
# Selecting and renaming columns cleanly in one step using basic subsetting
yields_clean <- data.frame(
  year     = as.numeric(yields_world$year),
  wheat_yield    = yields_world$wheat_yield,
  rice_yield     = yields_world$rice_yield,
  barley_yield   = yields_world$barley_yield,
  maize_yield    = yields_world$maize_yield,
  rye_yield      = yields_world$rye_yield,
  potatoes_yield = yields_world$potatoes_yield
)
fert_clean <- data.frame(
  year      = as.numeric(fert_world$year),
  nitrogen_use  = fert_world$nutrient_nitrogen_n__total__00003102__agricultural_use__005157__tonnes,
  phosphate_use = fert_world$nutrient_phosphate_p2o5__total__00003103__agricultural_use__005157__tonnes,
  potassium_use = fert_world$nutrient_potash_k2o__total__00003104__agricultural_use__005157__tonnes
)
land_clean <- data.frame(
  year          = as.numeric(land_world$year),
  wheat_land    = land_world$wheat__00000015__area_harvested__005312__hectares,
  rice_land     = land_world$rice__00000027__area_harvested__005312__hectares,
  barley_land   = land_world$barley__00000044__area_harvested__005312__hectares,
  maize_land    = land_world$maize__00000056__area_harvested__005312__hectares,
  rye_land      = land_world$rye__00000071__area_harvested__005312__hectares,
  potatoes_land = land_world$potatoes__00000116__area_harvested__005312__hectares
)
# Sequential Base R inner merge (all = FALSE)
merged_data <- merge(fert_clean, yields_clean, by = "year", all = FALSE)
merged_data <- merge(merged_data, land_clean, by = "year", all = FALSE)

# --- 4. Correlation Analysis ---
# Isolate columns of interest (excluding Year)
numeric_cols_owid <- c(
  "nitrogen_use", "phosphate_use", "potassium_use",
  "wheat_yield", "rice_yield", "barley_yield", "maize_yield", "rye_yield", "potatoes_yield",
  "wheat_land", "rice_land", "barley_land", "maize_land", "rye_land", "potatoes_land")
# Extract correlation matrix, handling missing data cleanly
cor_matrix_owid <- cor(merged_data[, numeric_cols_owid], use = "complete.obs")
cor_matrix_owid <- round(cor_matrix_owid, 3)
# Export correlation table
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)
write.csv(cor_matrix_owid, "fertilizer_crops_correlation_matrix.csv", row.names = TRUE)

# ==============================================================================
# Script: 02_plot_heatmap_simple.R
# Description: Plots correlation matrix CSV exactly as it is. 
#              Zero external packages required.
# ==============================================================================

# 1. Read the CSV exactly as it is
cor_data_owid <- read.csv("fertilizer_crops_correlation_matrix.csv", row.names = 1, check.names = FALSE)
cor_matrix_owid <- as.matrix(cor_data_owid)

# 2. Extract dimensions and clean up the labels (REMOVING UNDERSCORES)
n_vars_owid <- ncol(cor_matrix_owid)

# Replace all underscores with spaces globally in one clean step
clean_names_owid <- gsub("_", " ", colnames(cor_matrix_owid))
clean_names_owid <- gsub("land", "land use", clean_names_owid)

# Re-apply the clean names to both columns and rows
colnames(cor_matrix_owid) <- clean_names_owid
rownames(cor_matrix_owid) <- clean_names_owid

# Get the updated names and data ranges
col_names_owid <- colnames(cor_matrix_owid)
row_names_owid <- rownames(cor_matrix_owid)
min_val_owid   <- min(cor_matrix_owid)
max_val_owid   <- max(cor_matrix_owid)
max_val_owid <- max(cor_matrix_owid)

# 3. Set up interactive window margins (generous right margin for the legend)
# (We do NOT run png() here—it goes straight to your screen)
par(mar = c(8, 9, 4, 8))

# 4. Define the color palette (Yellow to Dark Blue)
color_palette_owid <- colorRampPalette(c("#FFFFE5", "#D9F0A3", "#41B6C4", "#225EA8", "#081D58"))(100)

# 5. Flip and transpose the matrix for top-to-bottom reading
plot_matrix_owid <- t(cor_matrix_owid)[, n_vars_owid:1]

# 6. Draw the heatmap tiles
image(1:n_vars_owid, 1:n_vars_owid, plot_matrix_owid, col = color_palette_owid, axes = FALSE, xlab = "", ylab = "")

# 7. Add X and Y Axis Labels
text(1:n_vars_owid, par("usr")[3] - 0.2, labels = col_names_owid, srt = 45, adj = 1, xpd = TRUE, cex = 0.8)
text(par("usr")[1] - 0.2, 1:n_vars_owid, labels = rev(row_names_owid), adj = 1, xpd = TRUE, cex = 0.8)

# 8. Overlay correlation numbers inside the tiles
for (x_owid in 1:n_vars_owid) {
  for (y_owid in 1:n_vars_owid) {
    val_owid <- cor_matrix_owid[n_vars_owid - y_owid + 1, x_owid]
    text(x_owid, y_owid, sprintf("%.2f", val_owid), col = "gray", cex = 0.8, font = 2)
  }
}

# 9. Draw the Legend (Color Bar) on the Right Side
bar_x_left_owid  <- n_vars_owid + 0.8
bar_x_right_owid <- n_vars_owid + 1.2
y_steps_owid     <- seq(1, n_vars_owid, length.out = 101)

for (i in 1:100) {
  rect(bar_x_left_owid, y_steps_owid[i], bar_x_right_owid, y_steps_owid[i+1], 
       col = color_palette_owid[i], border = NA, xpd = TRUE)
}
rect(bar_x_left_owid, 1, bar_x_right_owid, n_vars_owid, border = "black", lwd = 1, xpd = TRUE)

# 10. Add Value Labels (Ticks) next to the Color Bar
tick_vals_owid <- seq(min_val_owid, max_val_owid, length.out = 5)
tick_y_owid    <- seq(1, n_vars_owid, length.out = 5)

text(bar_x_right_owid + 0.15, tick_y_owid, labels = sprintf("%.2f", tick_vals_owid), 
     adj = 0, xpd = TRUE, cex = 0.8)

text(bar_x_right_owid + 0.8, n_vars_owid / 2, labels = "Correlation Value", 
     srt = 270, xpd = TRUE, cex = 0.9, font = 2)

# 11. Add Main Title
title(main = "Correlation Betwen Fertilizer Use, Land Use, and Crop Yield", line = 1.5, cex.main = 1.2, font.main = 2)

