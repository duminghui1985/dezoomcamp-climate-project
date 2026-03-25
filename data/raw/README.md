# 🌍 Climate & Population Analysis: Raw Data Mirror

This repository serves as a static data storage center for the **Data Engineering Zoomcamp 2026** Capstone Project. 

The primary goal of this mirror is to ensure the reliability and robustness of the data pipeline by providing stable access to raw datasets, mitigating risks associated with upstream API changes or third-party platform restrictions (e.g., Kaggle authentication).

---

## 📊 Dataset Details

### 1. Global Land Temperature Data (Berkeley Earth)
*   **Filename**: `GlobalLandTemperaturesByCountry.csv`
*   **Temporal Coverage**: 1743 - 2013
*   **Granularity**: Monthly
*   **Description**: Contains monthly average land temperatures and uncertainty intervals for various countries and territories.
*   **Original Source**: [Berkeley Earth via Kaggle](https://www.kaggle.com/datasets/berkeleyearth/climate-change-earth-surface-temperature-data?select=GlobalLandTemperaturesByCountry.csv)
*   **License**: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

### 2. World Population Data (World Bank)
*   **Filename**: `API_SP.POP.TOTL_DS2_en_csv_v2_61.csv`
*   **Temporal Coverage**: 1960 - 2023
*   **Granularity**: Annual
*   **Description**: Annual time series of total population counts for countries and regions worldwide. This dataset is in a "wide" format (years as columns) and requires unpivoting during the transformation phase.
*   **Original Source**: [World Bank](https://data.worldbank.org/indicator/SP.POP.TOTL)
*   **License**: [CC BY-4.0](https://datacatalog.worldbank.org/public-licenses#cc-by)

---

## ⚖️ Compliance & Data Governance

1.  **Usage**: This repository is strictly for **educational purposes** and non-commercial research within the context of the Data Engineering Zoomcamp.
2.  **Intellectual Property**: This project fully respects the ownership and effort of the original data providers (Berkeley Earth and World Bank). All data is distributed according to their respective **Open Data Licenses**.
3.  **Data Provenance**: These files are mirrored in their original "Raw" state to maintain the integrity of the source data for the ETL/ELT pipeline.

---


