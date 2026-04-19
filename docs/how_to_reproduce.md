# 🛠️ Reproduction Guide: Step-by-Step Instructions

This document provides a comprehensive, step-by-step technical guide to reproducing the Global Climate & Population Analysis pipeline from scratch.

> [!NOTE]
> This project was developed and tested on **Ubuntu 24.04 LTS**. 


## 1. Prerequisites

Ensure you have the following tools installed on your system:
*   **Google Cloud Platform (GCP) Account**: A project with billing enabled.
*   **Terraform**: For infrastructure management.
*   **Docker & Docker Compose**: To run the Kestra orchestrator.
*   **Python 3.12+**: With `pipx` installed (recommended for Ubuntu 24.04 to handle isolated environments).
*   **Git**: To clone the repository.  


## 2. Google Cloud Setup

1.  **Create a New Project**: Go to the [GCP Console](https://console.cloud.google.com/) and create a new project. Take note of your **Project ID**.
2.  **Create a Service Account**:
    *   Navigate to **IAM & Admin > Service Accounts**. Click **Create service account** at the top.
    *   Enter a name (e.g., `de-zoomcamp-runner`).
    *   Assign the following roles: `Storage Admin`, `BigQuery Admin`
3.  **Generate a Service Account Key**: 
    *   In the Service Accounts list, find the account you just created. Click the three dots under the **Actions** column and select **Manage keys**.
    *   Click **ADD KEY** > **Create new key**.
    *   Select **JSON** as the key type and click **Create**.
    *   The key will be downloaded automatically. Save it as `google_credentials.json` on your local machine.
    *   **⚠️ Important: Never Upload this file to Github**

## 3. Infrastructure Deployment (Terraform)

1.  Navigate to the `terraform` directory:
    ```bash
    cd terraform
    ```
2.  Update `variables.tf` with your specific environment details:  
    *   `credentials`: The local file path to your `google_credentials.json`.
    *   `project`: Your unique GCP project ID.
    *   `region` and `location`: Your preferred deployment region (e.g., `us-central1`) and data location (e.g., `US`).
    *   `bq_dataset_name`: The ID of your BigQuery dataset. 
    *   `gcs_bucket_name`: The name of your Storage Bucket. **Note: This must be globally unique.**
3.  Initialize and deploy the infrastructure:
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```
    *Review the execution plan and type `yes` when prompted. This will provision the Google Cloud Storage Bucket (Data Lake) and the BigQuery dataset (Data Warehouse).*


## 4. Data Orchestration (Kestra)

1.  **Configure Credentials**:  
    Kestra requires the GCP Service Account key to be Base64 encoded if passed via environment variables.
    ```bash
    cd kestra
    echo "SECRET_GCP_SERVICE_ACCOUNT=$(cat ../google_credentials.json | base64 -w 0)" > .env
    ```
    *Note: Ensure the path to `google_credentials.json` is correct.*  
    **⚠️ Important: Never Upload .env file to Github**

2.  **Update Docker Compose**:  
    Navigate to the orchestration directory:
    ```bash
    cd kestra
    ```
    In the `docker-compose.yml`, ensure the `kestra` service points to the `.env` file to load the credentials:
    ```yaml
    services:
      kestra:
        env_file:
          - path/to/.env
    ```

3.  **Start Kestra**:  
    Launch the Kestra containers using Docker Compose:
    ```bash
    docker-compose up -d
    ```
    Access the Kestra UI at `http://localhost:8080`.  
    
    **Default Credentials**:  
    *   **Username**: `admin@kestra.io`  
    *   **Password**: `Admin1234`  
    *(You can modify these credentials in the `docker-compose.yml` file if needed).*

4.  **Configure Key-Value (KV) Store**:  
    In the Kestra UI, navigate to the **KV Store** and add the following keys with your specific GCP project details:
    *   `GCP_PROJECT_ID`
    *   `GCP_LOCATION` (e.g., `US`)
    *   `GCP_DATASET` (e.g., `raw_climate`)
    *   `GCP_BUCKET_NAME`

5.  **Run the Pipeline**:  
    Go to the **Flows** tab and import the `climate_data_ingestion.yaml` file. Click **Execute**.  
    This flow automates the data download from the GitHub mirror, uploads the raw files to GCS (Data Lake), and creates external tables in BigQuery.

## 5. Data Transformation (dbt)

1.  Navigate to the dbt project directory:
    ```bash
    cd dbt/climate_transformation
    ```
2.  **Install dbt-bigquery** (using pipx for environment isolation):
    ```bash
    pipx install dbt-core
    pipx inject dbt-core dbt-bigquery
    ```
3.  **Configure the dbt profile**:  
    Initialize your connection profile by running:
    ```bash
    dbt init
    ```
    Follow the interactive prompts to set up your credentials:
    * Database: bigquery
    * Authentication method: service_account
    * Keyfile: Path to your google-credentials.json
    * Project: Your GCP Project ID
    * Dataset: prod_climate (where dbt will create the final tables)
    * Threads: 4
    * Job_execution_timeout_seconds: 300
    * Location: The region of your BigQuery dataset (e.g., US)
    
    After initialization, verify the settings in `~/.dbt/profiles.yml` and test the connection:
    ```bash
    dbt debug
    ```
4.  **Update Data Sources**:  
    Modify `models/staging/sources.yml` to point to the raw data created during the Ingestion stage:
    * database: Your unique GCP Project ID.
    * schema: The BigQuery dataset name where Kestra created the external tables (e.g., raw_climate_dataset).
    ```yml
    version: 2

    sources:
    - name: raw_climate_source
        database: dezoomcamp-test-project # Replace with your actual Project ID
        schema: raw_climate_dataset # Replace with your actual raw dataset name
        tables:
        - name: ext_temperature
        - name: ext_population
    ```

4.  **Install Dependencies & Build**:
    ```bash
    dbt deps
    dbt build
    ```
    *This command executes all seeds, models (Staging, Intermediate, Marts), and runs the automated data quality tests.*


## 6. Visualization (Looker Studio)

1.  **Access Looker Studio**: Open [Looker Studio](https://lookerstudio.google.com/).
2.  **Connect Data**: Click **Create a report** and select the **BigQuery** connector.
3.  **Select Table**: Choose your GCP project, the `prod_climate` dataset, and the `fact_climate_population` table.
4.  **Global Trends: Average Temperature & Population Growth (1960-2013)**
    *   **Chart Type**: Time series chart.
    *   **Dimension**: `record_date` (Ensure type is set to Year).
    *   **Metric**: `annual_avg_temp` (Average) and `population` (Sum).
    *   **Dual Axis Setup**: In the **Style** tab, set **Series #1** (Temperature) to the **Left Axis** and **Series #2** (Population) to the **Right Axis** to view both trends clearly.
5.  **Global Heat Map: Average Surface Temperature by Country (1960-2013)**
    *   **Chart Type**: Geo chart.
    *   **Dimension**: `country`.
    *   **Metric**: `annual_avg_temp`.
    *   **Style**: Set the Max color value to **Red** and the Min color value to **Blue** to represent temperature intensity.
6.  **Comparative Population Growth: Selected Nations (1960-2013)**
    *   **Chart Type**: Vertival Bar chart.
    *   **Dimension**: `record_date`.
    *   **Breakdown Dimension**: `country`.
    *   **Metric**: `population`.
    *   **Sorting**: Sort by `record_date` (Ascending) and secondary sort by `population` (Descending).
    *   **Customization**: In the **Style** tab, set bars to **54** (to cover the 1960-2013 range) and select **Color by: Dimension values**.
    *   **Interactivity**: Add a **Drop-down list** control for `country` and another **Drop-down list** for `record_date` to allow dynamic filtering.
7.  **Add Ranking Data**: Click **Add data** and select the `temp_increase_ranking` table from your `prod_climate` dataset.
8.  **Top 10 Countries with the Highest Temperature Rise (1960-2013)**
    *   **Chart Type**: Bar chart (Horizontal).
    *   **Dimension**: `country`.
    *   **Metric**: `total_increase`.
    *   **Sorting**: Sort by `total_increase` (Descending).
    *   **Rows**: Limit to **10** bars to display the top warming nations.

---
*Developed and maintained on Ubuntu 24.04 LTS for the Data Engineering Zoomcamp 2026 Capstone.*