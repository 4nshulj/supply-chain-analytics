-- ============================================================================================================================
-- PROJECT      : End-to-End Supply Chain Data Cleaning Project
-- DESCRIPTION  : This project focuses on cleaning and standardizing raw supply chain data
--                covering warehouses, suppliers, orders, and shipments.
--
--                The dataset contains intentionally messy and inconsistent fields such as:
--                - Date columns stored as TEXT in multiple formats
--                - Inconsistent categorical values
--                - Potential missing or invalid operational metrics
--
--                The main objective of this file is to prepare the raw data for analysis by:
--                - Creating structured tables
--                - Defining relationships using primary and foreign keys
--                - Staging raw data for further transformation
--                - Supporting downstream ETL and analytics workflows
--
-- FOCUS AREAS :
--                - Data standardization
--                - Schema structuring
--                - Staging layer creation
--                - Data quality preparation
--
-- DATABASE     : PostgreSQL 18.3
-- AUTHOR       : Anshul
-- LAST UPDATED : 2026
-- ============================================================================================================================
-- ============================================================================================================================
-- SECTION 1 : WAREHOUSES TABLE
-- Purpose    : Stores master data for warehouse locations used in supply chain operations.
-- Notes      : Acts as the central reference table for warehouse-based analytics.
-- ============================================================================================================================
CREATE TABLE WAREHOUSES (
	WAREHOUSE_ID TEXT PRIMARY KEY,
	REGION VARCHAR(50),
	CITY VARCHAR(40)
);
-- ============================================================================================================================
-- SECTION 2 : WAREHOUSE OPERATIONS TABLE
-- Purpose    : Captures daily operational performance metrics for each warehouse.
-- Notes      : Used to analyze efficiency, workload, and operational bottlenecks.
--              Includes performance indicators such as processing time, utilization, and error rates.
-- ============================================================================================================================
CREATE TABLE WAREHOUSES_ORDERS (
	WAREHOUSE_ID TEXT,
	REGION VARCHAR(50),
	CITY VARCHAR(40),
	DATE TEXT,
	ORDERS_PROCESSED INT,
	AVG_PROCESSING_TIME_HOURS NUMERIC(5, 2),
	UTILIZATION_PERCENTAGE NUMERIC(5, 1),
	ERROR_RATE_PERCENTAGE NUMERIC(5, 2),
	LABOR_HOURS NUMERIC(10, 2),
	FOREIGN KEY (WAREHOUSE_ID) REFERENCES WAREHOUSES (WAREHOUSE_ID)
);
-- ============================================================================================================================
-- SECTION 3 : SUPPLIERS TABLE
-- Purpose    : Stores supplier details and performance metrics.
-- Notes      : Used to evaluate supplier reliability, quality, and delivery efficiency.
-- ============================================================================================================================

CREATE TABLE SUPPLIERS (
	SUPPLIER_ID TEXT PRIMARY KEY,
	SUPPLIER_NAME TEXT,
	COUNTRY VARCHAR(30),
	SUPPLIER_RATING NUMERIC(2, 1),
	LEAD_TIME_DAYS INT,
	DEFECT_RATE NUMERIC(5, 2),
	ON_TIME_DELIVERY_RATE NUMERIC(3, 1)
);
-- ============================================================================================================================
-- SECTION 4 : ORDERS TABLE
-- Purpose    : Tracks order lifecycle from placement to delivery status.
-- Notes      : Includes fulfillment details and delivery performance tracking.
-- ============================================================================================================================

CREATE TABLE ORDERS (
	ORDER_ID TEXT,
	CUSTOMER_ID TEXT,
	WAREHOUSE_ID TEXT,
	ORDER_DATE TEXT,
	PROMISED_DELIVERY_DATE TEXT,
	ACTUAL_DELIVERY_DATE TEXT,
	ORDER_PRIORITY VARCHAR(10),
	FULFILLMENT_TYPE VARCHAR(30),
	DELIVERY_STATUS VARCHAR(15),
	FOREIGN KEY (WAREHOUSE_ID) REFERENCES WAREHOUSES (WAREHOUSE_ID)
);

-- ============================================================================================================================
-- SECTION 5 : SHIPMENTS STAGING TABLE
-- Purpose    : Stores raw shipment-level data before cleaning and transformation.
-- Notes      : Used as a staging layer for logistics and delivery analysis.
-- ============================================================================================================================

CREATE TABLE SHIPMENTS_STAGGING (
	SHIPMENT_ID TEXT PRIMARY KEY,
	ORDER_ID TEXT,
	CARRIER_NAME VARCHAR(25),
	WAREHOUSE_ID TEXT,
	SHIPMENT_DATE TEXT,
	ESTIMATED_DELIVERY_DATE TEXT,
	ACTUAL_DELIVERY_DATE TEXT,
	SHIPPING_MODE VARCHAR(20),
	SHIPMENT_COST NUMERIC(10, 2),
	DELAY_REASON TEXT
);

SELECT
	*
FROM
	SHIPMENTS_STAGGING;

-- Standardize carrier names
UPDATE SHIPMENTS_STAGGING
SET
	CARRIER_NAME = UPPER(TRIM(CARRIER_NAME));

-- Standardize warehouse IDs
UPDATE SHIPMENTS_STAGGING
SET
	WAREHOUSE_ID = UPPER(TRIM(WAREHOUSE_ID));

-- Inspect distinct warehouse IDs for data quality issues
SELECT DISTINCT
	WAREHOUSE_ID
FROM
	SHIPMENTS_STAGGING;

-- Normalize warehouse ID format (WH-01, WH-02, etc.)
UPDATE SHIPMENTS_STAGGING
SET
	WAREHOUSE_ID = 'WH-' || LPAD(
		REGEXP_REPLACE(WAREHOUSE_ID, '\D', '', 'g'),
		2,
		'0'
	);

-- Inspect distinct carrier names for standardization
SELECT DISTINCT
	CARRIER_NAME
FROM
	SHIPMENTS_STAGGING;

-- Standardize carrier names
UPDATE SHIPMENTS_STAGGING
SET
	CARRIER_NAME = CASE
		WHEN CARRIER_NAME IN ('UPS', 'U.P.S.', 'USPS', 'U.S.P.S.') THEN 'UPS'
		WHEN CARRIER_NAME IN ('FEDEX', 'FED EX') THEN 'FedEx'
		WHEN CARRIER_NAME IN ('BLUE DART', 'BLUEDART') THEN 'Blue Dart'
		WHEN CARRIER_NAME IN ('DHL', 'DHL EXPRESS') THEN 'DHL'
		WHEN CARRIER_NAME IN ('MAERSK', 'MAERSK LINE') THEN 'Maersk'
		WHEN CARRIER_NAME IN ('XPO', 'XPO LOGISTICS') THEN 'XPO Logistics'
		WHEN CARRIER_NAME = 'ARAMEX' THEN 'Aramex'
		ELSE CARRIER_NAME
	END;

-- Standardize actual delivery date format
UPDATE SHIPMENTS_STAGGING
SET
	ACTUAL_DELIVERY_DATE = CASE
		WHEN ACTUAL_DELIVERY_DATE ~ '^\d{2}-[A-Za-z]{3,9}-\d{4}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'DD-Mon-YYYY')
		WHEN ACTUAL_DELIVERY_DATE ~ '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'YYYY/MM/DD')
		WHEN ACTUAL_DELIVERY_DATE ~ '^[A-Za-z]{3} \d{2} \d{4}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'Mon-DD-YYYY')
		WHEN ACTUAL_DELIVERY_DATE ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'YYYY-MM-DD')
		ELSE NULL::DATE
	END;

-- Standardize shipment date format
UPDATE SHIPMENTS_STAGGING
SET
	SHIPMENT_DATE = CASE
		WHEN SHIPMENT_DATE ~ '^\d{2}-[A-Za-z]{3,9}-\d{4}$' THEN TO_DATE(SHIPMENT_DATE, 'DD-Mon-YYYY')
		WHEN SHIPMENT_DATE ~ '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN TO_DATE(SHIPMENT_DATE, 'YYYY/MM/DD')
		WHEN SHIPMENT_DATE ~ '^[A-Za-z]{3} \d{2} \d{4}$' THEN TO_DATE(SHIPMENT_DATE, 'Mon-DD-YYYY')
		WHEN SHIPMENT_DATE ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN TO_DATE(SHIPMENT_DATE, 'YYYY-MM-DD')
		ELSE NULL::DATE
	END;

-- Standardize estimated delivery date format
UPDATE SHIPMENTS_STAGGING
SET
	ESTIMATED_DELIVERY_DATE = CASE
		WHEN ESTIMATED_DELIVERY_DATE ~ '^\d{2}-[A-Za-z]{3,9}-\d{4}$' THEN TO_DATE(ESTIMATED_DELIVERY_DATE, 'DD-Mon-YYYY')
		WHEN ESTIMATED_DELIVERY_DATE ~ '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN TO_DATE(ESTIMATED_DELIVERY_DATE, 'YYYY/MM/DD')
		WHEN ESTIMATED_DELIVERY_DATE ~ '^[A-Za-z]{3} \d{2} \d{4}$' THEN TO_DATE(ESTIMATED_DELIVERY_DATE, 'Mon-DD-YYYY')
		WHEN ESTIMATED_DELIVERY_DATE ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN TO_DATE(ESTIMATED_DELIVERY_DATE, 'YYYY-MM-DD')
		ELSE NULL::DATE
	END;

-- Standardize shipping mode values
UPDATE SHIPMENTS_STAGGING
SET
	SHIPPING_MODE = INITCAP(TRIM(SHIPPING_MODE));

-- Standardize delay reason and handle missing values
UPDATE SHIPMENTS_STAGGING
SET
	DELAY_REASON = INITCAP(TRIM(COALESCE(DELAY_REASON, 'N/A')));

-- Validate cleaned staging data
SELECT
	*
FROM
	SHIPMENTS_STAGGING;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Create normalized shipments table (final layer)
CREATE TABLE SHIPMENTS (
	SHIPMENT_ID TEXT PRIMARY KEY,
	ORDER_ID TEXT,
	CARRIER_NAME VARCHAR(20),
	WAREHOUSE_ID TEXT,
	SHIPMENT_DATE DATE,
	ESTIMATED_DELIVERY_DATE DATE,
	ACTUAL_DELIVERY_DATE DATE,
	SHIPPING_MODE VARCHAR(15),
	SHIPMENT_COST NUMERIC(10, 2),
	DELAY_REASON TEXT
);

-- Insert cleaned data into final table
INSERT INTO
	SHIPMENTS (
		SHIPMENT_ID,
		ORDER_ID,
		CARRIER_NAME,
		WAREHOUSE_ID,
		SHIPMENT_DATE,
		ESTIMATED_DELIVERY_DATE,
		ACTUAL_DELIVERY_DATE,
		SHIPPING_MODE,
		SHIPMENT_COST,
		DELAY_REASON
	)
SELECT
	SHIPMENT_ID,
	ORDER_ID,
	CARRIER_NAME,
	WAREHOUSE_ID,
	SHIPMENT_DATE::DATE,
	ESTIMATED_DELIVERY_DATE::DATE,
	ACTUAL_DELIVERY_DATE::DATE,
	SHIPPING_MODE,
	SHIPMENT_COST,
	DELAY_REASON
FROM
	SHIPMENTS_STAGGING;

-- Validate final cleaned table
SELECT
	*
FROM
	SHIPMENTS;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Add foreign key constraints
ALTER TABLE SHIPMENTS
ADD CONSTRAINT FK_SHIPMENTS_WAREHOUSE FOREIGN KEY (WAREHOUSE_ID) REFERENCES WAREHOUSES (WAREHOUSE_ID);

ALTER TABLE SHIPMENTS
ADD CONSTRAINT FK_SHIPMENTS_ORDERS FOREIGN KEY (ORDER_ID) REFERENCES ORDERS (ORDER_ID);
----------------------------------------------------------------------------------------------------------------------------------------------------

-- IDENTIFY DUPLICATE RECORDS IN SHIPMENTS
WITH
	CTE AS (
		SELECT
			*,
			ROW_NUMBER() OVER (
				PARTITION BY
					SHIPMENT_ID,
					ORDER_ID,
					CARRIER_NAME,
					WAREHOUSE_ID
			) AS ROW_NUM
		FROM
			SHIPMENTS
	)
SELECT
	*
FROM
	CTE
WHERE
	ROW_NUM > 1;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- Identify duplicate records in orders
WITH
	CTE AS (
		SELECT
			*,
			ROW_NUMBER() OVER (
				PARTITION BY
					ORDER_ID,
					CUSTOMER_ID,
					WAREHOUSE_ID,
					ORDER_DATE,
					PROMISED_DELIVERY_DATE,
					ACTUAL_DELIVERY_DATE,
					ORDER_PRIORITY,
					FULFILLMENT_TYPE,
					DELIVERY_STATUS
			) AS ROW_NUM
		FROM
			ORDERS
	)
SELECT
	*
FROM
	CTE
WHERE
	ROW_NUM > 1;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- Create deduplication staging table for orders
CREATE TABLE ORDERS1 (
	ORDER_ID TEXT,
	CUSTOMER_ID TEXT,
	WAREHOUSE_ID TEXT,
	ORDER_DATE TEXT,
	PROMISED_DELIVERY_DATE TEXT,
	ACTUAL_DELIVERY_DATE TEXT,
	ORDER_PRIORITY VARCHAR(10),
	FULFILLMENT_TYPE VARCHAR(30),
	DELIVERY_STATUS VARCHAR(15),
	ROW_NUM INT,
	FOREIGN KEY (WAREHOUSE_ID) REFERENCES WAREHOUSES (WAREHOUSE_ID)
);

-- Insert deduplicated records
INSERT INTO
	ORDERS1
SELECT
	*,
	ROW_NUMBER() OVER (
		PARTITION BY
			ORDER_ID,
			CUSTOMER_ID,
			WAREHOUSE_ID,
			ORDER_DATE,
			PROMISED_DELIVERY_DATE,
			ACTUAL_DELIVERY_DATE,
			ORDER_PRIORITY,
			FULFILLMENT_TYPE,
			DELIVERY_STATUS
	) AS ROW_NUM
FROM
	ORDERS;

-- Validate staging orders data
SELECT
	*
FROM
	ORDERS1;

-- Remove duplicate records
DELETE FROM ORDERS1
WHERE
	ROW_NUM > 1;
----------------------------------------------------------------------------------------------------------------------------------------------------
-- Create cleaned orders view
CREATE VIEW ORDERS_CLEAN AS
SELECT
	UPPER(TRIM(ORDER_ID)) AS ORDER_ID,
	UPPER(TRIM(CUSTOMER_ID)) AS CUSTOMER_ID,
	UPPER(TRIM(WAREHOUSE_ID)) AS WAREHOUSE_ID,
	CASE
		WHEN ORDER_DATE ~ '^\d{2}-[A-Za-z]{3,9}-\d{4}$' THEN TO_DATE(ORDER_DATE, 'DD-Mon-YYYY')
		WHEN ORDER_DATE ~ '^\d{2}-[A-Za-z]{3,9}-\d{2}$' THEN TO_DATE(ORDER_DATE, 'DD-Mon-YY')
		WHEN ORDER_DATE ~ '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN TO_DATE(ORDER_DATE, 'YYYY/MM/DD')
		WHEN ORDER_DATE ~ '^[A-Za-z]{3} \d{2} \d{4}$' THEN TO_DATE(ORDER_DATE, 'Mon-DD-YYYY')
		WHEN ORDER_DATE ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN TO_DATE(ORDER_DATE, 'YYYY-MM-DD')
		WHEN ORDER_DATE ~ '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN TO_DATE(ORDER_DATE, 'DD-MM-YYYY')
		ELSE NULL
	END AS ORDER_DATE,
	CASE
		WHEN PROMISED_DELIVERY_DATE ~ '^\d{2}-[A-Za-z]{3,9}-\d{4}$' THEN TO_DATE(PROMISED_DELIVERY_DATE, 'DD-Mon-YYYY')
		WHEN PROMISED_DELIVERY_DATE ~ '^\d{2}-[A-Za-z]{3,9}-\d{2}$' THEN TO_DATE(PROMISED_DELIVERY_DATE, 'DD-Mon-YY')
		WHEN PROMISED_DELIVERY_DATE ~ '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN TO_DATE(PROMISED_DELIVERY_DATE, 'YYYY/MM/DD')
		WHEN PROMISED_DELIVERY_DATE ~ '^[A-Za-z]{3} \d{2} \d{4}$' THEN TO_DATE(PROMISED_DELIVERY_DATE, 'Mon-DD-YYYY')
		WHEN PROMISED_DELIVERY_DATE ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN TO_DATE(PROMISED_DELIVERY_DATE, 'YYYY-MM-DD')
		WHEN PROMISED_DELIVERY_DATE ~ '^[0-9]{2}-[0-9]{2}-\d{4}$' THEN TO_DATE(PROMISED_DELIVERY_DATE, 'DD-MM-YYYY')
		ELSE NULL
	END AS PROMISED_DELIVERY_DATE,
	CASE
		WHEN ACTUAL_DELIVERY_DATE ~ '^\d{2}-[A-Za-z]{3,9}-\d{4}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'DD-Mon-YYYY')
		WHEN ACTUAL_DELIVERY_DATE ~ '^\d{2}-[A-Za-z]{3,9}-\d{2}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'DD-Mon-YY')
		WHEN ACTUAL_DELIVERY_DATE ~ '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'YYYY/MM/DD')
		WHEN ACTUAL_DELIVERY_DATE ~ '^[A-Za-z]{3} \d{2} \d{4}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'Mon-DD-YYYY')
		WHEN ACTUAL_DELIVERY_DATE ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'YYYY-MM-DD')
		WHEN ACTUAL_DELIVERY_DATE ~ '^[0-9]{2}-[0-9]{2}-\d{4}$' THEN TO_DATE(ACTUAL_DELIVERY_DATE, 'DD-MM-YYYY')
		ELSE NULL
	END AS ACTUAL_DELIVERY_DATE,
	INITCAP(TRIM(ORDER_PRIORITY)) AS ORDER_PRIORITY,
	INITCAP(TRIM(FULFILLMENT_TYPE)) AS FULFILLMENT_TYPE,
	INITCAP(TRIM(DELIVERY_STATUS)) AS DELIVERY_STATUS
FROM
	ORDERS1;

-- Validate cleaned orders view
SELECT
	*
FROM
	ORDERS_CLEAN;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Identify duplicate suppliers
WITH
	CTE AS (
		SELECT
			*,
			ROW_NUMBER() OVER (
				PARTITION BY
					SUPPLIER_ID,
					SUPPLIER_NAME,
					COUNTRY
			) AS ROW_NUM
		FROM
			SUPPLIERS
	)
SELECT
	*
FROM
	CTE
WHERE
	ROW_NUM > 1;

-- Create cleaned suppliers view
CREATE VIEW SUPPLIERS_CLEAN AS
SELECT
	UPPER(TRIM(SUPPLIER_ID)) AS SUPPLIER_ID,
	CASE
		WHEN SUPPLIER_NAME IS NULL THEN 'Unknown Supplier'
		ELSE INITCAP(TRIM(SUPPLIER_NAME))
	END AS SUPPLIER_NAME,
	INITCAP(TRIM(COUNTRY)) AS COUNTRY,
	SUPPLIER_RATING,
	LEAD_TIME_DAYS,
	DEFECT_RATE,
	ON_TIME_DELIVERY_RATE
FROM
	SUPPLIERS;

-- Validate cleaned suppliers view
SELECT
	*
FROM
	SUPPLIERS_CLEAN;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Identify duplicates in warehouse_orders
WITH
	CTE AS (
		SELECT
			*,
			ROW_NUMBER() OVER (
				PARTITION BY
					WAREHOUSE_ID,
					DATE
			) AS ROW_NUM
		FROM
			WAREHOUSES_ORDERS
	)
SELECT
	*
FROM
	CTE
WHERE
	ROW_NUM > 1;

-- Create cleaned warehouse orders view
CREATE VIEW WAREHOUSES_CLEAN AS
SELECT
	UPPER(TRIM(WAREHOUSE_ID)) AS WAREHOUSE_ID,
	INITCAP(TRIM(REGION)) AS REGION,
	INITCAP(TRIM(CITY)) AS CITY,
	CASE
		WHEN "date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN TO_DATE("date", 'YYYY-MM-DD')
		WHEN "date" ~ '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN TO_DATE("date", 'YYYY/MM/DD')
		WHEN "date" ~ '^\d{2}-[A-Za-z]{3,9}-\d{4}$' THEN TO_DATE("date", 'DD-Mon-YYYY')
		WHEN "date" ~ '^[A-Za-z]{3} \d{2} \d{4}$' THEN TO_DATE("date", 'Mon-DD-YYYY')
		ELSE NULL
	END AS "date",
	ORDERS_PROCESSED,
	AVG_PROCESSING_TIME_HOURS,
	UTILIZATION_PERCENTAGE,
	ERROR_RATE_PERCENTAGE,
	LABOR_HOURS
FROM
	WAREHOUSES_ORDERS;

-- Validate cleaned warehouse orders view
SELECT
	*
FROM
	WAREHOUSES_CLEAN;

----------------------------------------------------------------------------------------------------------------------------------------------------
-- Create cleaned warehouse master view
CREATE VIEW WAREHOUSE_CLEAN AS
SELECT
	UPPER(TRIM(WAREHOUSE_ID)) AS WAREHOUSE_ID,
	INITCAP(TRIM(REGION)) AS REGION,
	INITCAP(TRIM(CITY)) AS CITY
FROM
	WAREHOUSES;

-- Validate cleaned warehouse master view
SELECT
	*
FROM
	WAREHOUSE_CLEAN;
-- ============================================================================================================================
-- END OF DATA CLEANING PIPELINE
-- Purpose  : This marks the completion of the end-to-end supply chain data cleaning process.
--
-- Summary  : All raw datasets have been systematically processed through multiple stages including:
--            - Standardization of text and categorical fields
--            - Handling of inconsistent and messy date formats
--            - Deduplication of transactional and master data
--            - Creation of clean, analysis-ready views and final tables
--
-- Outcome  : The dataset is now structured, consistent, and ready for downstream use cases such as:
--            - Business Intelligence dashboards
--            - Operational performance analysis
--            - Supply chain optimization studies
--            - Advanced SQL analytics and reporting
--
-- NOTE     : This layer serves as the foundation for all future analytical modeling and insights generation.
-- ============================================================================================================================
