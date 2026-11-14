/*--------------------------------------------------------------------
  ENTERPRISE SQL MASTERCLASS: DUCKDB FAST IN-MEMORY OLAP SOLUTIONS
  Author: Amitkumar Tiwari
  Repository: https://github.com/Amit1092tiwari/Advancesqlpuzzle
  Dialect: DuckDB (Modern Analytical In-Memory SQL)
--------------------------------------------------------------------*/

-- ====================================================================
-- Puzzle #1: Shopping Carts (DuckDB List Functions & FULL JOIN)
-- ====================================================================
CREATE OR REPLACE TABLE Cart1 AS SELECT * FROM (VALUES ('Sugar'), ('Bread'), ('Juice'), ('Soda'), ('Flour')) t(Item);
CREATE OR REPLACE TABLE Cart2 AS SELECT * FROM (VALUES ('Sugar'), ('Bread'), ('Butter'), ('Cheese'), ('Fruit')) t(Item);

-- FULL OUTER JOIN with COALESCE
SELECT  a.Item AS Cart1_Item,
        b.Item AS Cart2_Item
FROM    Cart1 a
FULL OUTER JOIN Cart2 b ON a.Item = b.Item
ORDER BY COALESCE(a.Item, b.Item);


-- ====================================================================
-- Puzzle #2: Managers and Employees (DuckDB WITH RECURSIVE)
-- ====================================================================
CREATE OR REPLACE TABLE Employees AS 
SELECT * FROM (VALUES 
    (1001, NULL::INT, 'President', 185000),
    (2002, 1001, 'Director', 120000),
    (3003, 1001, 'Office Manager', 97000),
    (4004, 2002, 'Engineer', 110000),
    (5005, 2002, 'Engineer', 142000),
    (6006, 2002, 'Engineer', 160000)
) t(EmployeeID, ManagerID, JobTitle, Salary);

WITH RECURSIVE EmployeeHierarchy AS (
    SELECT  EmployeeID,
            ManagerID,
            JobTitle,
            Salary,
            0 AS Depth,
            CAST(EmployeeID AS VARCHAR) AS OrgPath
    FROM    Employees
    WHERE   ManagerID IS NULL

    UNION ALL

    SELECT  e.EmployeeID,
            e.ManagerID,
            e.JobTitle,
            e.Salary,
            h.Depth + 1,
            h.OrgPath || ' -> ' || CAST(e.EmployeeID AS VARCHAR)
    FROM    Employees e
    INNER JOIN EmployeeHierarchy h ON e.ManagerID = h.EmployeeID
)
SELECT * FROM EmployeeHierarchy ORDER BY Depth, EmployeeID;


-- ====================================================================
-- Puzzle #4: Two Predicates (DuckDB FILTER Clause)
-- ====================================================================
CREATE OR REPLACE TABLE Orders AS
SELECT * FROM (VALUES
    (1001, 'Ord936254', 'CA', 340.0),
    (1001, 'Ord143876', 'TX', 950.0),
    (1001, 'Ord654876', 'TX', 670.0),
    (1001, 'Ord814356', 'TX', 860.0),
    (2002, 'Ord342176', 'WA', 320.0),
    (3003, 'Ord265789', 'CA', 650.0),
    (3003, 'Ord387654', 'CA', 830.0),
    (4004, 'Ord476126', 'TX', 120.0)
) t(CustomerID, OrderID, DeliveryState, Amount);

SELECT  CustomerID
FROM    Orders
GROUP BY CustomerID
HAVING  COUNT(*) FILTER (WHERE DeliveryState = 'CA') > 0
   AND  COUNT(*) FILTER (WHERE DeliveryState = 'TX') > 0;


-- ====================================================================
-- Puzzle #6: Workflow Steps (DuckDB Native MATCH_RECOGNIZE)
-- ====================================================================
CREATE OR REPLACE TABLE WorkflowSteps AS
SELECT * FROM (VALUES
    (1, 1, 'Complete'),
    (1, 2, 'Complete'),
    (1, 3, 'Error'),
    (1, 4, 'Complete'),
    (2, 1, 'Complete'),
    (2, 2, 'Complete'),
    (2, 3, 'Complete')
) t(WorkflowID, StepNumber, Status);

SELECT  WorkflowID,
        Status,
        StartStep,
        EndStep,
        StepCount
FROM    WorkflowSteps
MATCH_RECOGNIZE (
    PARTITION BY WorkflowID
    ORDER BY StepNumber
    MEASURES
        FIRST(Status) AS Status,
        FIRST(StepNumber) AS StartStep,
        LAST(StepNumber) AS EndStep,
        COUNT(*) AS StepCount
    ONE ROW PER MATCH
    PATTERN (SAME_STATUS+)
    DEFINE
        SAME_STATUS AS Status = PREV(Status) OR PREV(Status) IS NULL
)
ORDER BY WorkflowID, StartStep;


-- ====================================================================
-- Puzzle #25: Top Vendors (DuckDB QUALIFY)
-- ====================================================================
CREATE OR REPLACE TABLE VendorOrders AS
SELECT * FROM (VALUES
    ('Ord1', 101, 500.00),
    ('Ord2', 101, 750.00),
    ('Ord3', 101, 750.00),
    ('Ord4', 102, 300.00),
    ('Ord5', 102, 450.00)
) t(OrderID, VendorID, Amount);

SELECT  OrderID,
        VendorID,
        Amount
FROM    VendorOrders
QUALIFY DENSE_RANK() OVER (PARTITION BY VendorID ORDER BY Amount DESC) = 1;
