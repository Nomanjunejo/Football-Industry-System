/* ============================================================
   01_create_database.sql
   Football Manufacturing, Export, Industry Intelligence &
   E-Commerce Management System (FMEIEMS)
   ------------------------------------------------------------
   Run this first in SSMS, connected to your local SQL Server
   instance (Windows Authentication or SQL login).
   ============================================================ */

USE master;
GO

IF DB_ID('FootballIndustryDB') IS NOT NULL
BEGIN
    ALTER DATABASE FootballIndustryDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FootballIndustryDB;
END
GO

CREATE DATABASE FootballIndustryDB;
GO

ALTER DATABASE FootballIndustryDB SET RECOVERY SIMPLE;
GO

USE FootballIndustryDB;
GO

PRINT 'Database FootballIndustryDB created successfully.';
GO
