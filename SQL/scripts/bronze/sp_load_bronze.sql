/*
===============================================================================
Stored Procedure: bronze.load_bronze
===============================================================================

Purpose:
    Performs a full load of all HSE source CSV files into the bronze schema.

Process:
    1. Records the start time of the complete loading process.
    2. Truncates each bronze table to remove previously loaded data.
    3. Loads the latest source data using BULK INSERT.
    4. Records and displays the loading duration for each table.
    5. Displays the total duration of the complete bronze-layer load.
    6. Captures and displays SQL Server error details if the load fails.

Important Notes:
    - This procedure uses a full-load approach.
    - Existing data in each bronze table is removed before reloading.
    - CSV files must be accessible from inside the SQL Server Docker container
      at /var/opt/mssql/import/.
    - CSV files contain header rows, so loading begins from row 2.

Parameters:
    None.

Return Value:
    None.

Usage:
    EXEC bronze.load_bronze;

===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'LOADING BRONZE LAYER';
        PRINT '================================================';


        -- =====================================================================
        -- 1. EVENT RECORDS
        -- =====================================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.event_records';
        TRUNCATE TABLE bronze.event_records;

        PRINT '>> Inserting Data Into: bronze.event_records';

        BULK INSERT bronze.event_records
        FROM '/var/opt/mssql/import/event_records.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\r\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------------------------------------------';


        -- =====================================================================
        -- 2. CALENDAR
        -- =====================================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.calendar';
        TRUNCATE TABLE bronze.calendar;

        PRINT '>> Inserting Data Into: bronze.calendar';

        BULK INSERT bronze.calendar
        FROM '/var/opt/mssql/import/calendar.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\r\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------------------------------------------';


        -- =====================================================================
        -- 3. CAUSE REFERENCE
        -- =====================================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.cause_reference';
        TRUNCATE TABLE bronze.cause_reference;

        PRINT '>> Inserting Data Into: bronze.cause_reference';

        BULK INSERT bronze.cause_reference
        FROM '/var/opt/mssql/import/cause_reference.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\r\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------------------------------------------';


        -- =====================================================================
        -- 4. EQUIPMENT
        -- =====================================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.equipment';
        TRUNCATE TABLE bronze.equipment;

        PRINT '>> Inserting Data Into: bronze.equipment';

        BULK INSERT bronze.equipment
        FROM '/var/opt/mssql/import/equipment.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\r\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------------------------------------------';


        -- =====================================================================
        -- 5. PERSONNEL
        -- =====================================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.personnel';
        TRUNCATE TABLE bronze.personnel;

        PRINT '>> Inserting Data Into: bronze.personnel';

        BULK INSERT bronze.personnel
        FROM '/var/opt/mssql/import/personnel.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\r\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------------------------------------------';


        -- =====================================================================
        -- 6. SITES
        -- =====================================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.sites';
        TRUNCATE TABLE bronze.sites;

        PRINT '>> Inserting Data Into: bronze.sites';

        BULK INSERT bronze.sites
        FROM '/var/opt/mssql/import/sites.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\r\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------------------------------------------';


        -- =====================================================================
        -- 7. WORK ACTIVITIES
        -- =====================================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.work_activities';
        TRUNCATE TABLE bronze.work_activities;

        PRINT '>> Inserting Data Into: bronze.work_activities';

        BULK INSERT bronze.work_activities
        FROM '/var/opt/mssql/import/work_activities.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\r\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> --------------------------------------------------------------';


        -- Complete batch load.

        SET @batch_end_time = GETDATE();

        PRINT '================================================';
        PRINT 'BRONZE LAYER LOAD COMPLETED';

        PRINT '>> Total Load Duration: ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';

    END TRY

    BEGIN CATCH

        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE-LAYER LOADING';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '================================================';

    END CATCH

END;
GO