# ==============================================================================
# Script: 03_world_bank_energy_fertilizers_crops_pipeline.R
# Author: Ariq Haidar
# Description: Cleans the World Bank Pink Sheet commodity prices and plots the 
#              correlation matrix.
# ==============================================================================

# --- 1. Load Raw Pink Sheet Dataset ---
message("Loading raw World Bank Pink Sheet data...")
raw_file <- "CMO-Historical-Data-Monthly-Jul-26 - Monthly Prices.csv"

# Ingest, keeping the original headers exactly as they are
wb_raw <- read.csv(raw_file, header = TRUE, check.names = FALSE)

# --- 2. Extract and Rename Key Columns ---
message("Selecting and standardizing columns...")

# We map raw columns to standard, clean short names
cols_mapping <- c(
  "year_month" = "Year-Month",
  "Brent Crude" = "Crude oil, Brent ($/bbl)",
  "WTI Crude"   = "Crude oil, WTI ($/bbl)",
  "Dubai Crude" = "Crude oil, Dubai ($/bbl)",  
  "US Natural Gas"  = "Natural gas, US ($/mmbtu)",
  "EU Natural Gas"  = "Natural gas, Europe ($/mmbtu)",
  "Japan LNG"  = "Liquefied natural gas, Japan ($/mmbtu)",
  "Urea (Nitrogen)" = "Urea ($/mt)",
  "DAP (Phosphor)" = "DAP ($/mt)",
  "Kalium (Potassium)" = "Potassium chloride ($/mt)",
  "Maize" = "Maize ($/mt)",
  "Sorghum" = "Sorghum ($/mt)",
  "Rice" = "Rice, Thai 5% ($/mt)",
  "SRW Wheat"  = "Wheat, US SRW ($/mt)",
  "HRW Wheat"  = "Wheat, US HRW ($/mt)"
)

# Subset and rename using standard column matching
wb_selected <- wb_raw[, cols_mapping]
colnames(wb_selected) <- names(cols_mapping)

# --- 3. Clean & Sanitise Numeric Columns ---
message("Sanitizing numeric values...")

clean_numeric <- function(x) {
  x[x == "..." | x == "…" | x == "" | is.na(x)] <- NA
  x_clean <- gsub("[^0-9.-]", "", as.character(x))
  x_clean[x_clean == "" | x_clean == "."] <- NA
  return(as.numeric(x_clean))
}

# Clean all columns EXCEPT the date string
commodity_cols <- setdiff(colnames(wb_selected), "year_month")

for (col in commodity_cols) {
  wb_selected[[col]] <- clean_numeric(wb_selected[[col]])
}

# --- 4. Keep the date column as a clean character string --- 
wb_selected$year_month <- as.character(wb_selected$year_month)
write.csv(wb_selected, "CMO-Historical-Data-Monthly-Jul-26 - Cleaned Monthly Prices.csv", row.names = FALSE)
message("Clean dataset saved.")

# --- 5. Calculate Correlation Matrix ---
message("Calculating correlation coefficients...")

# Calculate Pearson correlations using only our numeric commodity columns
cor_matrix_wb <- cor(wb_selected[, commodity_cols], use = "complete.obs")

# Save Correlation Matrix CSV ---
write.csv(cor_matrix_wb, "energy price, fertilizer price, crop price pink sheet matrix.csv")

# --- 6. Plot Interactive Heatmap ---
message("Plotting interactive heatmap...")

# Extract dimensions and ranges for plotting
n_vars    <- ncol(cor_matrix_wb)
col_names <- colnames(cor_matrix_wb)
row_names <- rownames(cor_matrix_wb)
min_val   <- min(cor_matrix_wb)
max_val   <- max(cor_matrix_wb)

# Set safe plotting margins (generous margins to fit rotated text and the legend)
par(mfrow=c(1,1))

# MATCHED COLOR PALETTE: Steel Blue (#4575b4) to Pale Yellow (#ffffbf) to Crimson Red (#d73027)
color_palette <- colorRampPalette(c("#4575b4", "#ffffbf", "#d73027"))(100)

# Flip and transpose the matrix so it reads naturally from top-to-bottom
plot_matrix <- t(cor_matrix_wb)[, n_vars:1]

# Draw the core heatmap tiles
image(1:n_vars, 1:n_vars, plot_matrix, col = color_palette, axes = FALSE, xlab = "", ylab = "")

# Add X and Y Axis labels (Clean, customized labels!)
text(1:n_vars, par("usr")[3] - 0.25, labels = col_names, srt = 45, adj = 1, xpd = TRUE, cex = 0.75)
text(par("usr")[1] - 0.25, 1:n_vars, labels = rev(row_names), adj = 1, xpd = TRUE, cex = 0.75)

# Overlay correlation numbers inside the tiles using unified red text
for (x in 1:n_vars) {
  for (y in 1:n_vars) {
    val <- cor_matrix_wb[n_vars - y + 1, x]
    text_color <- "black"
    text(x, y, sprintf("%.2f", val), col = text_color, font = 2, cex = 0.75)
  }
}

# Draw the Legend (Color Bar) on the Right Side
bar_x_left  <- n_vars + 0.8
bar_x_right <- n_vars + 1.2
y_steps     <- seq(1, n_vars, length.out = 101)

# Draw the color bar blocks using the new color scheme
for (i in 1:100) {
  rect(bar_x_left, y_steps[i], bar_x_right, y_steps[i+1], 
       col = color_palette[i], border = NA, xpd = TRUE)
}
# Draw a neat border outline around the bar
rect(bar_x_left, 1, bar_x_right, n_vars, border = "black", lwd = 1, xpd = TRUE)

# Add numeric ticks next to the legend
tick_vals <- seq(min_val, max_val, length.out = 5)
tick_y    <- seq(1, n_vars, length.out = 5)
text(bar_x_right + 0.15, tick_y, labels = sprintf("%.2f", tick_vals), adj = 0, xpd = TRUE, cex = 0.8)

# Legend title
text(bar_x_right + 0.8, n_vars / 2, labels = "Correlation Value", srt = 270, xpd = TRUE, cex = 0.9, font = 2)

# Add Main Title 
title(main = "Correlation Between Energy Prices, Fertilizer Prices, and Crop Prices", 
      line = 1.5, cex.main = 1.0, font.main = 2)

# --- 7. Historical Shock Analysis (ft. tidyverse and ggplot2) ---
message("Processing historical baseline shock data panel...")
install.packages(c("tidyverse", "ggplot2"))
library(tidyverse)
library(ggplot2)

# Create fake Date index from your clean year_month column for alignment plotting
wb_selected$Date <- as.Date(paste0(gsub("M", "-", wb_selected$year_month), "-01"), format = "%Y-%m-%d")

# Filter for pre and peak window baseline periods
shocks2 <- wb_selected %>%
  filter(year_month %in% c("2007M08", "2008M07", "2022M02", "2022M03")) %>%
  mutate(
    Shock = c("2008 Pre", "2008 Peak", "2022 Pre", "2022 Peak")
  ) %>%
  select(year_month, Date, Shock, `Brent Crude`, `Japan LNG`, `Urea (Nitrogen)`, `Maize`, `SRW Wheat`, `HRW Wheat`)

# Pivot longer for facet grouping layout
shocks_long2 <- shocks2 %>% 
  pivot_longer(-c(year_month, Date, Shock), names_to = "Commodity")

# Generate the multi-panel facet line chart
# Using Base R's native gsub and grepl to bypass any missing stringr library constraints
ggplot(shocks_long2, aes(x = Date, y = value, 
                         color = gsub(" Peak| Pre", "", Shock), 
                         group = interaction(Commodity, gsub(" Peak| Pre", "", Shock)))) + 
  geom_line(linewidth = 1.2) + 
  geom_point(size = 4, aes(shape = if_else(grepl("Peak", Shock), "Peak", "Pre"))) + 
  facet_wrap(~Commodity, scales = "free_y") + 
  scale_shape_manual(values = c("Pre" = 1, "Peak" = 16)) + 
  labs(title = "Commodity Shock Comparison: Pre vs. Peak Baseline Prices",
       subtitle = "2008 Financial Crisis Scenario vs. 2022 Russia-Ukraine Corridor Disruptions",
       color = "Crisis Event",
       shape = "Market State") + 
  theme_minimal()
