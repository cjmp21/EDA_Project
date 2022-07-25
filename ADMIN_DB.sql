-- DB ADMIN
-- SHRINK DATABASE
USE [Retention_Rappi]
GO
DBCC SHRINKDATABASE(N'Retention_Rappi' )
GO

-- SHRINK FILE
USE [Retention_Rappi]
GO
DBCC SHRINKFILE (N'Retention_Rappi' , 0, TRUNCATEONLY)
GO
