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

To ensure pipeline stability and reproducibility, all raw CSV files are mirrored in this repository. This approach bypasses third-party API authentication hurdles (e.g., Kaggle API) and prevents failures due to upstream path changes.

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

### 6.1 Data Modeling Layers

#### **1. Staging Layer (`models/staging/`)**
The staging layer focuses on data type conversion and initial cleanup:
*   **`stg_temperature`** 
    * **Granularity Alignment:** The raw Berkeley Earth data provides monthly observations. Since population data is annual, this model parses raw date strings and aggregates monthly records into **annual averages** (`AVG()`). This ensures temporal alignment between the two datasets.
*   **`stg_population`** 
     * **Wide-to-Long Normalization:** The World Bank provides population data in a "Wide Format" (years as columns). I implemented the `UNPIVOT` function to transform 60+ yearly columns into a relational **Long Format**, making the data suitable for time-series analysis and joining.
     * **Dynamic Column Cleanup:**: Since BigQuery does not allow column names to start with numbers, a year_ prefix was added during the ingestion phase.

#### **2. Intermediate Layer (`models/intermediate/`)**
This layer handles standardization:
*   **`int_temperature_standardized`** 
    1. **ISO Standard Mapping:**
    It performs an INNER JOIN between the staging temperature data and a dbt seed (country_mapping). This replaces inconsistent country names with standardized 3-letter **ISO-3166 Alpha-3 codes** (e.g., mapping "United States" to USA).Note: Using standardized codes ensures 100% join integrity when merging with the population dataset later.
    2. **Deduplication:** I implemented a re-aggregation logic to handle "many-to-one" mappings (e.g., merging "Denmark" and "Denmark (Europe)" into a single `DNK` entity) to ensure a unique record for every country-year combination.

#### **3. Marts Layer (`models/marts/`)**
The final "Single Source of Truth":
*   **`fact_climate_population`:** This is the core table that performs an `INNER JOIN` between the standardized climate and population datasets. It is materialized as a table and utilizes the **BigQuery optimizations** (Partitioning/Clustering) detailed in Section 5.


### 6.2 Data Quality & Automated Testing
To guarantee the reliability of the dashboard, I implemented a robust testing framework:
*   **Schema Tests (`schema.yml`):**
    *   Standard `not_null` and `unique` tests.
    *   `unique_combination_of_columns` test on `country_code` and `record_date` to prevent join-induced duplicates.
*   **Singular Tests (Custom SQL in `tests/`):**
    *   **`assert_data_range_is_valid`**: A parameterized test using dbt variables to ensure the dataset covers the full expected period (1960–2013).
    *   **`assert_no_year_gaps`**: A mathematical continuity test that ensures no years were lost during the aggregation or join process.

### 6.3 dbt Lineage
![dbt Lineage](./images/dbt_lineage.png)





