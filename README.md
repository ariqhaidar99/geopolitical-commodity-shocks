# macro-commodity-transmission

An empirical, multi-stage quantitative model analyzing price transmission elasticities across the global energy-fertilizer-food value chain using 60+ years of World Bank "Pink Sheet" and Our World in Data (OWID) historical records. 

*Read the full published analysis on [Impakter](https://impakter.com/hormuz-strait-blockade-how-energy-shocks-feed-into-fertilizer-and-food-prices/).*

---

## 📌 Analytical Framework
Modern agricultural yields rely heavily on energy-intensive chemical synthesis (the Haber-Bosch process for nitrogenous fertilizers). This repository hosts an end-to-end pipeline constructed entirely in native Base R to prove two key structural theses:
1. **The Cost Transmission Channel:** Upstream energy shocks (Crude Oil & Natural Gas) pass directly into intermediate fertilizers (Urea, DAP), dictating final grain staple prices (Maize, Wheat, Rice).
2. **The Intensification Dilemma:** Agricultural expansion (extensification via land use) has historically remained flat and shows a near-zero correlation with actual global food security, which remains bound to fertilizer-driven crop yields (intensification).

---

## 📊 Empirical Visualizations

### 1. The Global Price Transmission Network
By calculating Pearson correlation coefficients across 13 distinct asset classes, the macro network illustrates a powerful relationship running from upstream inputs to retail commodities. High-density connections ($r > 0.85$) bind European Natural Gas directly to Urea synthesis and Maize pricing.

![Price Transmission Heatmap]([energy price fertilizer price crop price.png])

### 2. Historical Shock Comparison: Pre vs. Peak Prices
To ground this framework in historical precedents, this panel benchmarks baseline pricing environments against peak crisis metrics across core commodity layers during the **2008 Financial Crisis** and the **2022 Russia-Ukraine War**. The visualization illustrates exactly how downstream crop assets and intermediate inputs mirror major upstream energy disruptions during a systemic supply shock.

![Historical Shock Comparison](figures/hormuz_core_shocks.png)

### 3. Crop Yields vs. Fertilizer Intensification
Using raw global agricultural data from 1961 to the present, our visualization confirms that staple yields closely track raw chemical nutrient applications, while showing independent movements relative to changes in land boundaries.

![Fertilizer and Crop Yield Correlation](crop_yield_vs_fertilizer.png)

---
