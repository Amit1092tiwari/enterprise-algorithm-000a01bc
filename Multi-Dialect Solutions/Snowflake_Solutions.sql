/*--------------------------------------------------------------------
  ENTERPRISE SQL MASTERCLASS: SNOWFLAKE CLOUD DWH SOLUTIONS
  Author: Amitkumar Tiwari
  Repository: https://github.com/Amit1092tiwari/Advancesqlpuzzle
  Dialect: Snowflake SQL (ANSI:2016 + Cloud OLAP Extensions)
--------------------------------------------------------------------*/

-- ====================================================================
-- Puzzle #1: Shopping Carts (Array Construction & Set Comparison)
-- ====================================================================
CREATE OR REPLACE TEMPORARY TABLE Cart1 (Item VARCHAR(100));
CREATE OR REPLACE TEMPORARY TABLE Cart2 (Item VARCHAR(100));

INSERT INTO Cart1 (Item) VALUES ('Sugar'), ('Bread'), ('Juice'), ('Soda'), ('Flour');
INSERT INTO Cart2 (Item) VALUES ('Sugar'), ('Bread'), ('Butter'), ('Cheese'), ('Fruit');

-- Strategy 1: Classical FULL OUTER JOIN
SELECT  a.Item AS Cart1_Item,
        b.Item AS Cart2_Item
FROM    Cart1 a
FULL OUTER JOIN Cart2 b ON a.Item = b.Item
ORDER BY COALESCE(a.Item, b.Item);

-- Strategy 2: Snowflake Array Intersection & Difference
WITH c1 AS (
    SELECT ARRAY_AGG(Item) WITHIN GROUP (ORDER BY Item) AS Items FROM Cart1
),
c2 AS (
    SELECT ARRAY_AGG(Item) WITHIN GROUP (ORDER BY Item) AS Items FROM Cart2
)
SELECT  c1.Items AS Cart1_Set,
        c2.Items AS Cart2_Set,
        ARRAY_INTERSECTION(c1.Items, c2.Items) AS Matching_Items,
        IFF(c1.Items = c2.Items, TRUE, FALSE) AS IsExactMatch
FROM    c1 CROSS JOIN c2;


-- ====================================================================
-- Puzzle #2: Managers and Employees (Snowflake Native CONNECT BY)
-- ====================================================================
CREATE OR REPLACE TEMPORARY TABLE Employees (
    EmployeeID  INTEGER,
    ManagerID   INTEGER,
    JobTitle    VARCHAR(100),
    Salary      INTEGER
);

INSERT INTO Employees (EmployeeID, ManagerID, JobTitle, Salary) VALUES
(1001, NULL, 'President', 185000),
(2002, 1001, 'Director', 120000),
(3003, 1001, 'Office Manager', 97000),
(4004, 2002, 'Engineer', 110000),
(5005, 2002, 'Engineer', 142000),
(6006, 2002, 'Engineer', 160000);

-- Snowflake supports both WITH RECURSIVE and CONNECT BY
SELECT  EmployeeID,
        ManagerID,
        JobTitle,
        Salary,
        LEVEL - 1 AS Depth,
        SYS_CONNECT_BY_PATH(EmployeeID, ' -> ') AS OrgPath
FROM    Employees
START WITH ManagerID IS NULL
CONNECT BY PRIOR EmployeeID = ManagerID
ORDER BY Depth, EmployeeID;


-- ====================================================================
-- Puzzle #4: Two Predicates (Snowflake COUNT_IF)
-- ====================================================================
CREATE OR REPLACE TEMPORARY TABLE Orders (
    CustomerID      INTEGER,
    OrderID         VARCHAR(100),
    DeliveryState   VARCHAR(100),
    Amount          NUMBER(10,2)
);

INSERT INTO Orders (CustomerID, OrderID, DeliveryState, Amount) VALUES
(1001, 'Ord936254', 'CA', 340),
(1001, 'Ord143876', 'TX', 950),
(1001, 'Ord654876', 'TX', 670),
(1001, 'Ord814356', 'TX', 860),
(2002, 'Ord342176', 'WA', 320),
(3003, 'Ord265789', 'CA', 650),
(3003, 'Ord387654', 'CA', 830),
(4004, 'Ord476126', 'TX', 120);

-- Snowflake COUNT_IF Built-In
SELECT  CustomerID
FROM    Orders
GROUP BY CustomerID
HAVING  COUNT_IF(DeliveryState = 'CA') > 0
   AND  COUNT_IF(DeliveryState = 'TX') > 0;


-- ====================================================================
-- Puzzle #6: Workflow Steps (Snowflake Native MATCH_RECOGNIZE)
-- ====================================================================
CREATE OR REPLACE TEMPORARY TABLE WorkflowSteps (
    WorkflowID  INTEGER,
    StepNumber  INTEGER,
    Status      VARCHAR(100)
);

INSERT INTO WorkflowSteps (WorkflowID, StepNumber, Status) VALUES
(1, 1, 'Complete'),
(1, 2, 'Complete'),
(1, 3, 'Error'),
(1, 4, 'Complete'),
(2, 1, 'Complete'),
(2, 2, 'Complete'),
(2, 3, 'Complete');

-- Pure ANSI:2016 Streaming Row Pattern Recognition
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
-- Puzzle #25: Top Vendors (Snowflake QUALIFY Single-Pass Pushdown)
-- ====================================================================
CREATE OR REPLACE TEMPORARY TABLE VendorOrders (
    OrderID     VARCHAR(100),
    VendorID    INTEGER,
    Amount      NUMBER(10,2)
);

INSERT INTO VendorOrders (OrderID, VendorID, Amount) VALUES
('Ord1', 101, 500.00),
('Ord2', 101, 750.00),
('Ord3', 101, 750.00),
('Ord4', 102, 300.00),
('Ord5', 102, 450.00);

-- QUALIFY eliminates CTE wrapping and pushes filter to micro-partitions
SELECT  OrderID,
        VendorID,
        Amount
FROM    VendorOrders
QUALIFY DENSE_RANK() OVER (PARTITION BY VendorID ORDER BY Amount DESC) = 1;


-- ====================================================================
-- Puzzle #28: Fill the Gaps (Snowflake IGNORE NULLS Window Option)
-- ====================================================================
CREATE OR REPLACE TEMPORARY TABLE SensorLogs (
    LogID       INTEGER,
    Temperature NUMBER(5,2)
);

INSERT INTO SensorLogs (LogID, Temperature) VALUES
(1, 20.5), (2, NULL), (3, NULL), (4, 22.0), (5, NULL), (6, 25.1);

-- Snowflake LAST_VALUE with IGNORE NULLS (LOCF Pattern)
SELECT  LogID,
        Temperature AS OriginalTemp,
        LAST_VALUE(Temperature IGNORE NULLS) OVER (
            ORDER BY LogID 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS ImputedTemperature
FROM    SensorLogs
ORDER BY LogID;
