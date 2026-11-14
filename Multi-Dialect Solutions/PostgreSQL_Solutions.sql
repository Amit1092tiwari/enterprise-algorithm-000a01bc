/*--------------------------------------------------------------------
  ENTERPRISE SQL MASTERCLASS: POSTGRESQL 16+ SOLUTIONS
  Author: Amitkumar Tiwari
  Repository: https://github.com/Amit1092tiwari/Advancesqlpuzzle
  Dialect: PostgreSQL (ANSI Standard Compliant)
--------------------------------------------------------------------*/

-- ====================================================================
-- Puzzle #1: Shopping Carts (Relational Division & Array Equality)
-- ====================================================================
DROP TABLE IF EXISTS Cart1 CASCADE;
DROP TABLE IF EXISTS Cart2 CASCADE;

CREATE TABLE Cart1 (Item VARCHAR(100) PRIMARY KEY);
CREATE TABLE Cart2 (Item VARCHAR(100) PRIMARY KEY);

INSERT INTO Cart1 (Item) VALUES ('Sugar'), ('Bread'), ('Juice'), ('Soda'), ('Flour');
INSERT INTO Cart2 (Item) VALUES ('Sugar'), ('Bread'), ('Butter'), ('Cheese'), ('Fruit');

-- Strategy 1: FULL OUTER JOIN with COALESCE (Classical ANSI)
SELECT  a.Item AS Cart1_Item,
        b.Item AS Cart2_Item
FROM    Cart1 a 
FULL OUTER JOIN Cart2 b ON a.Item = b.Item
ORDER BY COALESCE(a.Item, b.Item);

-- Strategy 2: PostgreSQL-Native Array Equality Set Check
WITH c1 AS (
    SELECT ARRAY_AGG(Item ORDER BY Item) AS Items FROM Cart1
),
c2 AS (
    SELECT ARRAY_AGG(Item ORDER BY Item) AS Items FROM Cart2
)
SELECT  c1.Items AS Cart1_Set,
        c2.Items AS Cart2_Set,
        (c1.Items = c2.Items) AS IsExactMatch,
        (c1.Items && c2.Items) AS HasOverlap
FROM    c1 CROSS JOIN c2;


-- ====================================================================
-- Puzzle #2: Managers and Employees (Hierarchical Trees with WITH RECURSIVE)
-- ====================================================================
DROP TABLE IF EXISTS Employees CASCADE;

CREATE TABLE Employees (
    EmployeeID  INTEGER PRIMARY KEY,
    ManagerID   INTEGER REFERENCES Employees(EmployeeID),
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

-- PostgreSQL requires explicit WITH RECURSIVE
WITH RECURSIVE EmployeeHierarchy AS (
    -- Anchor Member: Root CEO/President
    SELECT  EmployeeID,
            ManagerID,
            JobTitle,
            Salary,
            0 AS Depth,
            CAST(EmployeeID AS TEXT) AS OrgPath
    FROM    Employees
    WHERE   ManagerID IS NULL

    UNION ALL

    -- Recursive Member: Direct and indirect reports
    SELECT  e.EmployeeID,
            e.ManagerID,
            e.JobTitle,
            e.Salary,
            h.Depth + 1,
            h.OrgPath || ' -> ' || CAST(e.EmployeeID AS TEXT)
    FROM    Employees e
    INNER JOIN EmployeeHierarchy h ON e.ManagerID = h.EmployeeID
)
SELECT  EmployeeID, ManagerID, JobTitle, Salary, Depth, OrgPath
FROM    EmployeeHierarchy
ORDER BY Depth, EmployeeID;


-- ====================================================================
-- Puzzle #4: Two Predicates (PostgreSQL FILTER Clause vs. CASE WHEN)
-- ====================================================================
DROP TABLE IF EXISTS Orders CASCADE;

CREATE TABLE Orders (
    CustomerID      INTEGER,
    OrderID         VARCHAR(100),
    DeliveryState   VARCHAR(100),
    Amount          NUMERIC(10,2),
    PRIMARY KEY (CustomerID, OrderID)
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

-- Idiomatic PostgreSQL: Clean FILTER (WHERE ...) clause
SELECT  CustomerID
FROM    Orders
GROUP BY CustomerID
HAVING  COUNT(*) FILTER (WHERE DeliveryState = 'CA') > 0
   AND  COUNT(*) FILTER (WHERE DeliveryState = 'TX') > 0;


-- ====================================================================
-- Puzzle #6: Workflow Steps (Gaps and Islands / Sequence Grouping)
-- ====================================================================
DROP TABLE IF EXISTS WorkflowSteps CASCADE;

CREATE TABLE WorkflowSteps (
    WorkflowID  INTEGER,
    StepNumber  INTEGER,
    Status      VARCHAR(100),
    PRIMARY KEY (WorkflowID, StepNumber)
);

INSERT INTO WorkflowSteps (WorkflowID, StepNumber, Status) VALUES
(1, 1, 'Complete'),
(1, 2, 'Complete'),
(1, 3, 'Error'),
(1, 4, 'Complete'),
(2, 1, 'Complete'),
(2, 2, 'Complete'),
(2, 3, 'Complete');

-- Double ROW_NUMBER() Island Grouping
WITH RankedSteps AS (
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
-- Puzzle #10: Mean, Median, Mode & Range (Statistical Aggregations)
-- ====================================================================
DROP TABLE IF EXISTS SampleNumbers CASCADE;

CREATE TABLE SampleNumbers (
    Number INTEGER
);

INSERT INTO SampleNumbers (Number) VALUES
(5), (6), (10), (10), (13), (14), (17), (20), (81), (90), (76);

-- PostgreSQL Native Statistical Built-ins: PERCENTILE_CONT & MODE
SELECT  AVG(Number)::NUMERIC(10,2) AS Mean,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Number) AS Median,
        MODE() WITHIN GROUP (ORDER BY Number) AS Mode,
        MAX(Number) - MIN(Number) AS Range
FROM    SampleNumbers;


-- ====================================================================
-- Puzzle #25: Top Vendors (DISTINCT ON vs. DENSE_RANK)
-- ====================================================================
DROP TABLE IF EXISTS VendorOrders CASCADE;

CREATE TABLE VendorOrders (
    OrderID     VARCHAR(100) PRIMARY KEY,
    VendorID    INTEGER,
    Amount      NUMERIC(10,2)
);

INSERT INTO VendorOrders (OrderID, VendorID, Amount) VALUES
('Ord1', 101, 500.00),
('Ord2', 101, 750.00),
('Ord3', 101, 750.00),
('Ord4', 102, 300.00),
('Ord5', 102, 450.00);

-- Strategy 1: PostgreSQL-Exclusive DISTINCT ON
SELECT DISTINCT ON (VendorID)
        OrderID,
        VendorID,
        Amount
FROM    VendorOrders
ORDER BY VendorID, Amount DESC;

-- Strategy 2: Window DENSE_RANK (Handles ties)
WITH Ranked AS (
    SELECT  OrderID,
            VendorID,
            Amount,
            DENSE_RANK() OVER (PARTITION BY VendorID ORDER BY Amount DESC) AS Ranking
    FROM    VendorOrders
)
SELECT OrderID, VendorID, Amount
FROM   Ranked
WHERE  Ranking = 1;


-- ====================================================================
-- Puzzle #46: Positive Balances (Account Balance Filtering)
-- ====================================================================
DROP TABLE IF EXISTS AccountBalances CASCADE;

CREATE TABLE AccountBalances (
    AccountID   INTEGER,
    BalanceDate DATE,
    Amount      NUMERIC(10,2),
    PRIMARY KEY (AccountID, BalanceDate)
);

INSERT INTO AccountBalances (AccountID, BalanceDate, Amount) VALUES
(1001, '2023-01-01', 100),
(1001, '2023-01-02', -50),
(1001, '2023-01-03', 200),
(2002, '2023-01-01', 500),
(2002, '2023-01-02', 400),
(3003, '2023-01-01', -10);

-- Accounts where ALL balances are strictly positive (> 0)
SELECT  AccountID
FROM    AccountBalances
GROUP BY AccountID
HAVING  MIN(Amount) > 0;
