# 🌍 Global Climate & Population Analysis (1960-2013)

## 1. Problem Description

### **Overview**
Since the 1950s and 1960s, the global population has experienced unprecedented growth. Simultaneously, the issues of rising global temperatures and deteriorating climate conditions have increasingly entered the public consciousness, becoming some of the most critical challenges of our time. 

This project aims to analyze global population data and land temperature records between **1960 and 2013**. By integrating these two distinct datasets, the pipeline seeks to uncover the historical correlation between human population surges and climate shifts, while providing a granular view of how these trends vary across different nations and regions.

### **The Challenges**
To perform a meaningful global analysis, several data engineering obstacles had to be overcome:

1.  **Data Fragmentation & Instability:** Historical climate records (Berkeley Earth) and socio-economic indicators (World Bank) reside in separate repositories. Relying on live third-party platforms for large-scale analysis is often unstable and prone to authentication or path changes.
2.  **Structural Heterogeneity:** 
    *   **Wide vs. Long Format:** The raw population data is provided in a "Wide Format" (where each year is a separate column), which is unsuitable for relational joins or time-series visualization.
    *   **Temporal Granularity:** Temperature records are provided as monthly observations, while population data is recorded annually.
3.  **Entity Resolution (Naming Inconsistency):** Different data sources use varying naming conventions for countries (e.g., *"Russia"* vs. *"Russian Federation"* or *"Vietnam"* vs. *"Viet Nam"*). Without a mapping strategy, a standard join would result in significant data loss.
4.  **Analytical Performance at Scale:** Processing over 50 years of global records across 200+ countries requires an optimized storage strategy. Without physical optimization, interactive dashboarding on raw tables would be slow and cost-inefficient.

### **The Solution**
This project implements an end-to-end **Cloud Data Pipeline** to transform raw, siloed data into a highly optimized "Single Source of Truth."

**Key technical solutions provided by this pipeline:**
*   **Orchestrated Ingestion:** Using **Kestra** to automate the retrieval of data from a reliable GitHub mirror and ingest it into a **Google Cloud Storage (Data Lake)**.
*   **Advanced Transformation:** Utilizing **dbt** to execute complex SQL logic:
    *   **Unpivoting** the population wide-table into a normalized long-table format.
    *   **Aggregating** monthly temperature records into annual averages.
*   **Standardization via Seeds:** Implementing a robust **ISO-3166 mapping strategy** using dbt seeds to ensure 100% data integrity across heterogeneous sources.
*   **Data Warehouse Optimization:** Delivering a **BigQuery Data Mart** specifically optimized with **Yearly Partitioning** and **Country-level Clustering**. This ensures sub-second query performance for the final **Looker Studio** dashboard while minimizing cloud processing costs.  


## 2. Dataset Description

The analysis focuses on the **1960–2013** window, the period with the highest data density where both population and climate records overlap.

*   **Global Land Temp (Berkeley Earth):** Monthly average temperatures by country (1743–2013).
*   **World Population (World Bank):** Annual total population counts (1960–2023). This data was originally provided in **wide-format** (years as columns).

To ensure pipeline stability and reproducibility, all raw CSV files are mirrored in this repository. This approach bypasses third-party API authentication hurdles and prevents failures due to upstream path changes.

👉 **[View Full Metadata & Mirror Links](./data/raw/README.md)**  


## 3. Technologies Used

*   **Cloud Platform:** Google Cloud Platform (GCP)
*   **Infrastructure as Code:** Terraform
*   **Workflow Orchestration:** Kestra (Docker-based)
*   **Data Lake:** Google Cloud Storage (GCS)
*   **Data Warehouse:** BigQuery
*   **Data Transformation:** dbt (Core/CLI)
*   **Visualization:** Looker Studio


## 4. Project Architecture

### **4.1 Architecture Diagram**
 GitHub Mirror -> Kestra -> GCS (Data Lake) -> BigQuery External Tables -> dbt (Transformations/Tests) -> BigQuery Optimized Fact Table -> Looker Studio.

### 4.2 Pipeline Workflow
1.  **Infrastructure as Code (IaC):** **Terraform** is used to provision the Google Cloud Storage (GCS) bucket and BigQuery datasets, ensuring a reproducible and version-controlled cloud environment.
2.  **Orchestration:** **Kestra** (running on Docker) manages the end-to-end workflow:
    *   Downloads raw CSV files from the GitHub mirror.
    *   Uploads raw data to **GCS (Data Lake)**.
    *   Creates **External Tables** in BigQuery to reference the GCS objects, allowing SQL analysis without moving data into BigQuery storage at this stage.
3.  **Data Transformation (dbt):** The transformation logic follows a **Medallion Architecture**:
    *   **Staging:** Standardizes data types and aggregates high-frequency monthly temperatures into annual averages.
    *   **Intermediate:** Executes the complex **Unpivot** logic to normalize population data and standardizes country names using **ISO-3166 seeds** to ensure join integrity.
    *   **Marts:** Joins the processed climate and demographic datasets into a single, comprehensive fact table.
4.  **Optimization:** The final table is materialized as a native BigQuery table, specifically optimized with **Partitioning** and **Clustering** to enhance performance and reduce cost.
5.  **Visualization:** **Looker Studio** connects to the optimized BigQuery table, providing an interactive dashboard to explore global climate-population correlations.


## 5. Data Warehouse Optimization

To ensure high performance and cost-efficiency for the analytical queries, the final `fact_climate_population` table is materialized as a native BigQuery table with the following optimizations:

### **5.1 Partitioning by `record_date` (Yearly)**
*   **Logic:** Climate and demographic analysis are inherently time-series driven. Dashboard users typically filter data by specific decades or year ranges (e.g., "Show trends from 1990 to 2010").
*   **Reasoning:** By partitioning the table by year, BigQuery can perform **partition pruning**, skipping data from irrelevant years. This significantly reduces the total bytes scanned, lowering costs and increasing query speed.

### **5.2 Clustering by `country_code`**
*   **Logic:** A primary use case for this project is comparing specific nations or analyzing a single country's history (e.g., "Compare China vs. USA" or "Analyze Brazil's population impact").
*   **Reasoning:** Clustering physically organizes the data by `country_code` within each yearly partition. This ensures that when a user filters the dashboard by a specific country, BigQuery can locate and retrieve those specific rows much faster than scanning an unsorted table.


## 6. Transformations & Data Modeling (dbt)

This project uses **dbt** to transform raw data into clean, analysis-ready tables. The process follows a three-layer "Medallion" architecture.

### 6.1 Data Modeling Layers

#### **1. Staging Layer: Initial Cleanup**
This layer cleans the raw data and fixes formats to ensure consistency.
*   **`stg_temperature`**: Converts monthly temperature records into **annual averages**. This aligns the timeframe with the annual population data.
*   **`stg_population`**: Uses the `UNPIVOT` function to convert the "Wide Format" (years as columns) into a **Long Format** (years as rows). It also removes technical prefixes (like `year_`) added during the ingestion phase.

#### **2. Intermediate Layer: Standardization**
This layer ensures that data from different sources can be joined correctly.
*   **Standardization**: Uses a lookup table (seed) to map various country names (e.g., "United States" vs "USA") to standardized **ISO-3166 Alpha-3 codes**.
*   **Deduplication**: Merges duplicate records (e.g., combining "Denmark" and "Denmark (Europe)") by averaging their values. This ensures there is only one unique record per country per year.

#### **3. Marts Layer: Final Tables**
These are the optimized tables used directly by the dashboard.
*   **`fact_climate_population`**: The core table that joins climate and population data. It is materialized as a table and optimized with BigQuery **partitioning** (by year) and **clustering** (by country).
*   **`temp_increase_ranking`**: A summary table that calculates the total temperature rise for each country.

### 6.2 Data Quality & Testing
To ensure the data is accurate, several automated tests run during the build process:
*   **Integrity Tests**: Generic tests verify that IDs are unique and no critical data is missing (`not_null`).
*   **Join Verification**: Ensures that joining tables did not create unexpected duplicate rows.
*   **Logic Tests**: Custom SQL tests verify that the data covers the correct timeframe (1960–2013) and that there are no missing years (continuity check).

### 6.3 dbt Lineage Graph
![dbt Lineage](./images/dbt_lineage.png)


## 7. Visualization
![dashboard](./images/dashboard.png)

## 8. How to Reproduce
For a detailed, step-by-step technical guide on how to reproduce this entire pipeline on Ubuntu 24.04, please refer to the documentation below:

👉 **[Detailed Reproduction Guide](./docs/reproduce.md)**





