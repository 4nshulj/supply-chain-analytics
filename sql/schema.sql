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