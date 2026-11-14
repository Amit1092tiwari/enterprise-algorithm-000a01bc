/*--------------------------------------------------------------------
  ENTERPRISE SQL UTILITIES: DAILY CALENDAR ROLLING HORIZON MAINTENANCE
  Author: Amitkumar Tiwari
  Repository: https://github.com/Amit1092tiwari/Advancesqlpuzzle
  Target Engine: Microsoft SQL Server 2016+ / Azure SQL Database
  Schedule: Designed to execute daily via SQL Server Agent or Azure Elastic Jobs at 00:01 AM
--------------------------------------------------------------------*/

CREATE OR ALTER PROCEDURE dbo.SpDailyCalendarRollingUpdate
    @TargetTableName SYSNAME = N'dbo.DimDate'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @CurrentYear INT = YEAR(@Today);
    DECLARE @CurrentMonth INT = MONTH(@Today);
    DECLARE @CurrentWeek INT = DATEPART(ISO_WEEK, @Today);

    DECLARE @Rolling7Start DATE = DATEADD(DAY, -6, @Today);
    DECLARE @Rolling30Start DATE = DATEADD(DAY, -29, @Today);
    DECLARE @Rolling90Start DATE = DATEADD(DAY, -89, @Today);
    DECLARE @Rolling12MonthsStart DATE = DATEADD(MONTH, -12, @Today);

    PRINT CONCAT('Executing Daily Calendar Rolling Horizon Update for Reference Date: ', @Today);

    /* Dynamic SQL Execution against Target Calendar Table */
    DECLARE @Sql NVARCHAR(MAX) = N'
    UPDATE ' + QUOTENAME(@TargetTableName) + N'
    SET 
        IsCurrentDay = CASE WHEN CalendarDate = @Today THEN 1 ELSE 0 END,
        IsCurrentWeek = CASE WHEN CalendarYear = @CurrentYear AND WeekOfYear = @CurrentWeek THEN 1 ELSE 0 END,
        IsCurrentMonth = CASE WHEN CalendarYear = @CurrentYear AND MonthNumber = @CurrentMonth THEN 1 ELSE 0 END,
        IsCurrentYear = CASE WHEN CalendarYear = @CurrentYear THEN 1 ELSE 0 END,
        
        DaysFromToday = DATEDIFF(DAY, @Today, CalendarDate),
        WeeksFromToday = DATEDIFF(WEEK, @Today, CalendarDate),
        MonthsFromToday = DATEDIFF(MONTH, @Today, CalendarDate),
        
        IsRolling7Days = CASE WHEN CalendarDate BETWEEN @Rolling7Start AND @Today THEN 1 ELSE 0 END,
        IsRolling30Days = CASE WHEN CalendarDate BETWEEN @Rolling30Start AND @Today THEN 1 ELSE 0 END,
        IsRolling90Days = CASE WHEN CalendarDate BETWEEN @Rolling90Start AND @Today THEN 1 ELSE 0 END,
        IsRolling12Months = CASE WHEN CalendarDate BETWEEN @Rolling12MonthsStart AND @Today THEN 1 ELSE 0 END;
    ';

    BEGIN TRY
        EXEC sp_executesql 
            @stmt = @Sql,
            @params = N'@Today DATE, @CurrentYear INT, @CurrentMonth INT, @CurrentWeek INT, @Rolling7Start DATE, @Rolling30Start DATE, @Rolling90Start DATE, @Rolling12MonthsStart DATE',
            @Today = @Today,
            @CurrentYear = @CurrentYear,
            @CurrentMonth = @CurrentMonth,
            @CurrentWeek = @CurrentWeek,
            @Rolling7Start = @Rolling7Start,
            @Rolling30Start = @Rolling30Start,
            @Rolling90Start = @Rolling90Start,
            @Rolling12MonthsStart = @Rolling12MonthsStart;

        PRINT CONCAT('Successfully updated rolling horizon attributes for ', @@ROWCOUNT, ' calendar rows.');
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
