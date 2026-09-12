/* ============================================================
   02a_add_imageurl_column.sql
   Adds the missing ImageURL column to the Product table.
   Run this script if you're updating an existing database.
   ============================================================ */

USE FootballIndustryDB;
GO

-- Check if the column already exists before adding it
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Product' AND COLUMN_NAME = 'ImageURL'
)
BEGIN
    ALTER TABLE Product
    ADD ImageURL NVARCHAR(500) NULL;
    PRINT 'ImageURL column added successfully to Product table.';
END
ELSE
BEGIN
    PRINT 'ImageURL column already exists in Product table.';
END
GO
