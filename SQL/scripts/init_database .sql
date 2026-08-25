/*

==========================================================
 Create Database and Schemas
 ==========================================================

 Script Purpose:
    This script creates a new database after checking if it already exists.
    If it already exists, it is dropped and recreated. 
    Additionally, the script create 3 schemas from the medallion data management approach
    bronze, silver, and gold

NOTE: Running this script will drop the entire 'AionicsDataWarehouse' if it exists.
All data within it will be permanently deleted.
*/



-- Create Database for Aionics HSE Data Warehouse Project

USE master;
GO

-- Drop and recreate the AionicsDataWarehouse database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'AionicsDataWarehouse')
BEGIN
    ALTER DATABASE AionicsDataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AionicsDataWarehouse;
END;
GO

-- Create database
CREATE DATABASE AionicsDataWarehouse
COLLATE Latin1_General_100_CS_AS -- to enable users to see case insensitivities
GO

USE AionicsDataWarehouse;
GO

-- Create the medallion schema for the project
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
