# nordsec

This repository contains the full pipeline and analysis of the dataset provided by NordSecurity. It includes:

### 1. Data Extraction & Transformation

**`json_to_sql.ipynb`**  
- Jupyter Notebook for extracting `.json` files from an S3 bucket.
- Reads and transforms JSON files into pandas DataFrames.
- Applies necessary data manipulations.
- Connects to a local MySQL server and writes the cleaned data into a new database.

### 2. Database & Table Setup

**`sql_table_creation.sql`**  
- SQL script for table creation and transformations in MySQL Workbench.
- Includes all logic to clean, join, and structure data.
- Produces a master table used in the final analysis dashboard.

### 3. Dashboard & Analysis

**`NordSecurity_SaulePribusauskaite.twb`**  
- Tableau workbook with visualizations and analysis based on the processed dataset.
- Provides insights and trends based on the final master table.
- **[View the interactive Tableau dashboard here](https://public.tableau.com/app/profile/saule.pribusauskaite/viz/NordSecurity_SaulePribusauskaite/Messageanalysis?publish=yes)**


---

## Project Flow

S3 JSON files → Jupyter Notebook → MySQL DB → SQL Transformations → Tableau Analysis


---

## Requirements

- Python 3.9+
- Jupyter Notebook
- pandas, sqlalchemy, boto3 (for S3 access)
- MySQL (local instance)
- Tableau (for `.twb` file)

---

## Folder Structure

```
├── json_to_sql.ipynb
├── sql_table_creation.sql
├── NordSecurity_SaulePribusauskaite.twb
└── README.md
```

