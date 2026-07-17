# ==============================================================================
# Title: World Bank Pink Sheet Energy, Industries, and Commodities Price Analysis
# Author: Ariq Haidar
# Description: Chapter 2 - Unifies and filters the World Bank "Pink Sheet" Industry 
#              and Commodity datasets to map and visualize the Cross-Asset 
#              Energy Nexus (Metals, Softs, Meats, Timber, and Rubber).
# Requirements: dplyr, ggplot2, readr, reshape2, extrafont
# ==============================================================================

# ------------------------------------------------------------------------------
# [1] ENVIRONMENT SETUP & DEPENDENCIES
# ------------------------------------------------------------------------------
message("Initializing environments and dependencies...")
library(dplyr)
library(ggplot2)
library(readr)
library(reshape2)
library(extrafont)

# Font environment initialization safeguard
tryCatch({
  loadfonts(device = "win", quiet = TRUE)
}, error = function(e) {
  message("Font loading skipped or environment is non-Windows.")
})

# ------------------------------------------------------------------------------
# [2] MACRO ASSET CATEGORIZATION & DATA SCHEMA SCHEDULING
# ------------------------------------------------------------------------------
message("Configuring cross-asset schema definitions...")

# --- Group A: CMO-commodities.csv Schema Mapping ---
oil_comm <- c("Average crude oil ($/bbl)", "Brent Crude ($/bbl)",
              "Dubai Crude ($/bbl)", "WTI Crude ($/bbl)")

veg_oils <- c("Groundnut oil ($/mt)", "Palm oil ($/mt)", 
              "Palm kernel oil ($/mt)", "Soybean oil ($/mt)",
              "Rapeseed oil ($/mt)", "Sunflower oil ($/mt)")

meat     <- c("Beef ($/kg)", "Chicken ($/kg)", 
              "Lamb ($/kg)", "Shrimps, Mexican ($/kg)")

timber   <- c("Cameroon Logs ($/cubic meter)", "Malaysian Logs ($/cubic meter)",
              "Cameroon Sawnwood ($/cubic meter)", "Malaysian Sawnwood ($/cubic meter)",
              "Plywood (cents/sheet)")

all_comm_vars <- c(oil_comm, veg_oils, meat, timber)
comm_vars <- c(veg_oils, meat, timber)

# --- Group B: CMO-industries.csv Schema Mapping ---
energy_ind <- c("Average Crude oil ($/bbl)", "Brent Crude ($/bbl)",
                "Dubai Crude ($/bbl)", "WTI Crude ($/bbl)")

rubber     <- c("TSR20 Rubber ($/kg)", "RSS3 Rubber ($/kg)")

metals     <- c("Aluminum ($/mt)", "Copper ($/mt)", "Lead ($/mt)", 
                "Tin ($/mt)", "Nickel ($/mt)", "Zinc ($/mt)", 
                "CFR Spot Iron ore ($/dmtu)")

precious   <- c("Gold ($/troy oz)", "Platinum ($/troy oz)", "Silver ($/troy oz)")

all_ind_vars <- c(energy_ind, rubber, metals, precious)
ind_vars <- c(rubber, metals, precious)

# ------------------------------------------------------------------------------
# [3] DATA INGESTION & ROBUST NUMERIC CLEANING PIPELINE
# ------------------------------------------------------------------------------

# --- Process Chapter 2 Commodities ---
message("Ingesting and processing Commodities dataset...")
commodities <- read_csv("CMO-commodities.csv")

commodities_num <- commodities %>%
  select(all_of(all_comm_vars)) %>%
  mutate(across(everything(), ~ {
    char_vec <- as.character(.)
    char_vec <- gsub("\x85", "", char_vec, useBytes = TRUE)
    char_vec[char_vec == "..." | char_vec == "…" | char_vec == ""] <- NA
    clean_vec <- gsub("[^0-9.-]", "", char_vec)
    as.numeric(clean_vec)
  })) %>%
  na.omit()

cor_mat_comm <- cor(commodities_num)

# --- Process Chapter 2 Industries ---
message("Ingesting and processing Industries dataset...")
industries <- read_csv("CMO-industries.csv")

industries_num <- industries %>%
  select(all_of(all_ind_vars)) %>%
  mutate(across(everything(), ~ {
    char_vec <- as.character(.)
    char_vec <- gsub("\x85", "", char_vec, useBytes = TRUE)
    char_vec[char_vec == "..." | char_vec == "…" | char_vec == ""] <- NA
    clean_vec <- gsub("[^0-9.-]", "", char_vec)
    as.numeric(clean_vec)
  })) %>%
  na.omit()

cor_mat_ind <- cor(industries_num)

# ------------------------------------------------------------------------------
# [4] UNIFIED GRAPHICS VISUALIZATION ENGINE
# ------------------------------------------------------------------------------
plot_category <- function(matrix_source, cat_vars, energy_vars, cat_title) {
  
  # Structural subset array isolation
  cor_sub  <- matrix_source[cat_vars, energy_vars, drop = FALSE]
  cor_long <- melt(cor_sub)
  colnames(cor_long) <- c("Commodity", "Energy", "Correlation")
  
  cor_long$Commodity <- factor(cor_long$Commodity, levels = cat_vars)
  cor_long$Energy    <- factor(cor_long$Energy, levels = energy_vars)
  
  # Standardize font-family fallback options
  font_family <- if ("Outfit" %in% fonts()) "Outfit" else "sans"
  
  ggplot(cor_long, aes(x = Energy, y = Commodity, fill = Correlation)) +
    geom_tile(color = "white", linewidth = 0.5) +
    geom_text(aes(label = round(Correlation, 2)), size = 3, color = "black", family = font_family) +
    scale_fill_gradient2(
      low = "steelblue", mid = "white", high = "firebrick",
      midpoint = 0, limits = c(-1, 1), name = "Correlation"
    ) +
    labs(title = cat_title, x = NULL, y = NULL) +
    theme_minimal(base_size = 11, base_family = font_family) +
    theme(
      axis.text.x  = element_text(angle = 45, hjust = 1),
      plot.title   = element_text(hjust = 0.5, face = "bold"),
      panel.grid   = element_blank()
    )
}

# ------------------------------------------------------------------------------
# [5] MATRIX RE-RENDERING & VISUALIZATION EXECUTION
# ------------------------------------------------------------------------------
message("Generating cross-asset transmission heatmaps...")

# --- Group A Visual Assets (CMO-commodities) ---
# --- A1 Overall ---
library(corrplot)
corrplot(
  cor_mat_comm[oil_comm, comm_vars],
  method = "color",
  addCoef.col = "black",
  number.cex  = 0.6,
  tl.cex      = 0.7, 
  mar         = c(0, 0, 2, 0) # <-- Adds space at the top so the title fits
)
title(
  main = "Correlation Heatmap: Crude Oil Prices vs Commodities Prices", 
  line = 1.0,       # <-- Adjust this number lower to bring it down, higher to push up
  cex.main = 1.2,   # Font size of title
  font.main = 2     # Bold font
)
# --- A2 Per Commodity ---
print(plot_category(cor_mat_comm, veg_oils, oil_comm, "Crude Oil Prices vs Vegetable Oil Prices"))
print(plot_category(cor_mat_comm, meat,     oil_comm, "Crude Oil Prices vs Meat & Poultry Prices"))
print(plot_category(cor_mat_comm, timber,   oil_comm, "Crude Oil Prices vs Timber Prices"))

# --- Group B Visual Assets (CMO-industries) ---
# --- B1 Overall ---
library(corrplot)
corrplot(
  cor_mat_ind[energy_ind, ind_vars],
  method = "color",
  addCoef.col = "black",
  number.cex  = 0.6,
  tl.cex      = 0.7,
  mar         = c(0, 0, 2, 0) # <-- Adds space at the top so the title fits
)
title(
  main = "Correlation Heatmap: Crude Oil Prices vs Industries Prices", 
  line = 1.0,       # <-- Adjust this number lower to bring it down, higher to push up
  cex.main = 1.2,   # Font size of title
  font.main = 2     # Bold font
)
# --- B2 Per Industries ---
print(plot_category(cor_mat_ind,  metals,   energy_ind, "Crude Oil Prices vs Metal Prices"))
print(plot_category(cor_mat_ind,  precious, energy_ind, "Crude Oil Prices vs Prices of Precious Metals"))
print(plot_category(cor_mat_ind,  rubber,   energy_ind, "Crude Oil Prices vs Rubber Prices"))

message("✓ All Chapter 2 cross-asset matrices generated smoothly.")
