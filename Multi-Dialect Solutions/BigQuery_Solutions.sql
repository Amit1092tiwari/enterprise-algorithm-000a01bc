/*--------------------------------------------------------------------
  ENTERPRISE SQL MASTERCLASS: GOOGLE BIGQUERY ANALYTICAL SOLUTIONS
  Author: Amitkumar Tiwari
  Repository: https://github.com/Amit1092tiwari/Advancesqlpuzzle
  Dialect: Google BigQuery (GoogleSQL Standard)
--------------------------------------------------------------------*/

-- ====================================================================
-- Puzzle #1: Shopping Carts (BigQuery Array Transformations)
-- ====================================================================
WITH Cart1 AS (
    SELECT 'Sugar' AS Item UNION ALL
    SELECT 'Bread' UNION ALL
    SELECT 'Juice' UNION ALL
    SELECT 'Soda' UNION ALL
    SELECT 'Flour'
),
Cart2 AS (
    SELECT 'Sugar' AS Item UNION ALL
    SELECT 'Bread' UNION ALL
    SELECT 'Butter' UNION ALL
    SELECT 'Cheese' UNION ALL
    SELECT 'Fruit'
)
-- BigQuery FULL OUTER JOIN
SELECT  c1.Item AS Cart1_Item,
        c2.Item AS Cart2_Item
FROM    Cart1 c1
FULL OUTER JOIN Cart2 c2 ON c1.Item = c2.Item
ORDER BY COALESCE(c1.Item, c2.Item);


-- ====================================================================
-- Puzzle #2: Managers and Employees (BigQuery WITH RECURSIVE)
-- ====================================================================
WITH RECURSIVE Employees AS (
    SELECT 1001 AS EmployeeID, CAST(NULL AS INT64) AS ManagerID, 'President' AS JobTitle, 185000 AS Salary UNION ALL
    SELECT 2002, 1001, 'Director', 120000 UNION ALL
    SELECT 3003, 1001, 'Office Manager', 97000 UNION ALL
    SELECT 4004, 2002, 'Engineer', 110000 UNION ALL
    SELECT 5005, 2002, 'Engineer', 142000 UNION ALL
    SELECT 6006, 2002, 'Engineer', 160000
),
Hierarchy AS (
    SELECT  EmployeeID,
            ManagerID,
            JobTitle,
            Salary,
            0 AS Depth,
            CAST(EmployeeID AS STRING) AS OrgPath
    FROM    Employees
    WHERE   ManagerID IS NULL

    UNION ALL

    SELECT  e.EmployeeID,
            e.ManagerID,
            e.JobTitle,
            e.Salary,
            h.Depth + 1,
            CONCAT(h.OrgPath, ' -> ', CAST(e.EmployeeID AS STRING))
    FROM    Employees e
    INNER JOIN Hierarchy h ON e.ManagerID = h.EmployeeID
)
SELECT * FROM Hierarchy ORDER BY Depth, EmployeeID;


-- ====================================================================
-- Puzzle #4: Two Predicates (BigQuery COUNTIF)
-- ====================================================================
WITH Orders AS (
    SELECT 1001 AS CustomerID, 'Ord936254' AS OrderID, 'CA' AS DeliveryState, 340.0 AS Amount UNION ALL
    SELECT 1001, 'Ord143876', 'TX', 950.0 UNION ALL
    SELECT 1001, 'Ord654876', 'TX', 670.0 UNION ALL
    SELECT 1001, 'Ord814356', 'TX', 860.0 UNION ALL
    SELECT 2002, 'Ord342176', 'WA', 320.0 UNION ALL
    SELECT 3003, 'Ord265789', 'CA', 650.0 UNION ALL
    SELECT 3003, 'Ord387654', 'CA', 830.0 UNION ALL
    SELECT 4004, 'Ord476126', 'TX', 120.0
)
-- Native GoogleSQL COUNTIF syntax
SELECT  CustomerID
FROM    Orders
GROUP BY CustomerID
HAVING  COUNTIF(DeliveryState = 'CA') > 0
   AND  COUNTIF(DeliveryState = 'TX') > 0;


-- ====================================================================
-- Puzzle #6: Workflow Steps (BigQuery Double ROW_NUMBER Island Grouping)
-- ====================================================================
WITH WorkflowSteps AS (
    SELECT 1 AS WorkflowID, 1 AS StepNumber, 'Complete' AS Status UNION ALL
    SELECT 1, 2, 'Complete' UNION ALL
    SELECT 1, 3, 'Error' UNION ALL
    SELECT 1, 4, 'Complete' UNION ALL
    SELECT 2, 1, 'Complete' UNION ALL
    SELECT 2, 2, 'Complete' UNION ALL
    SELECT 2, 3, 'Complete'
),
RankedSteps AS (
    SELECT  WorkflowID,
            StepNumber,
            Status,
            StepNumber - ROW_NUMBER() OVER (
                PARTITION BY WorkflowID, Status 
                ORDER BY StepNumber
            ) AS IslandGroup
    FROM    WorkflowSteps
)
SELECT  WorkflowID,
        Status,
        MIN(StepNumber) AS StartStep,
        MAX(StepNumber) AS EndStep,
        COUNT(*) AS StepCount
FROM    RankedSteps
GROUP BY WorkflowID, Status, IslandGroup
ORDER BY WorkflowID, StartStep;


-- ====================================================================
-- Puzzle #25: Top Vendors (BigQuery QUALIFY Window Pushdown)
-- ====================================================================
WITH VendorOrders AS (
    SELECT 'Ord1' AS OrderID, 101 AS VendorID, 500.00 AS Amount UNION ALL
    SELECT 'Ord2', 101, 750.00 UNION ALL
    SELECT 'Ord3', 101, 750.00 UNION ALL
    SELECT 'Ord4', 102, 300.00 UNION ALL
    SELECT 'Ord5', 102, 450.00
)
-- BigQuery supports native QUALIFY clause without CTE wrapping
SELECT  OrderID,
        VendorID,
        Amount
FROM    VendorOrders
QUALIFY DENSE_RANK() OVER (PARTITION BY VendorID ORDER BY Amount DESC) = 1;


-- ====================================================================
-- Puzzle #46: Positive Balances (BigQuery MIN Aggregation)
-- ====================================================================
WITH AccountBalances AS (
    SELECT 1001 AS AccountID, DATE '2023-01-01' AS BalanceDate, 100.0 AS Amount UNION ALL
    SELECT 1001, DATE '2023-01-02', -50.0 UNION ALL
    SELECT 1001, DATE '2023-01-03', 200.0 UNION ALL
    SELECT 2002, DATE '2023-01-01', 500.0 UNION ALL
    SELECT 2002, DATE '2023-01-02', 400.0 UNION ALL
    SELECT 3003, DATE '2023-01-01', -10.0
)
SELECT  AccountID
FROM    AccountBalances
GROUP BY AccountID
HAVING  MIN(Amount) > 0;
