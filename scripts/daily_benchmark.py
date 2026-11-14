#!/usr/bin/env python3
"""
Daily Multi-Dialect Benchmark & Regression Test Runner
Author: Amitkumar Tiwari
Repository: https://github.com/Amit1092tiwari/Advancesqlpuzzle
Description: Executes daily in GitHub Actions to validate multi-dialect
             relational puzzle solutions against expected matrices.
"""

import os
import sys
import time

try:
    import duckdb
except ImportError:
    print("DuckDB not installed. Installing...")
    os.system(f"{sys.executable} -m pip install duckdb")
    import duckdb


def run_benchmark():
    con = duckdb.connect(database=":memory:")
    results = []
    print("================================================================")
    print("  STARTING DAILY MULTI-DIALECT PUZZLE BENCHMARK SUITE")
    print("================================================================\n")

    # ----------------------------------------------------------------
    # Benchmark 1: Puzzle #1 - Shopping Carts (FULL OUTER JOIN)
    # ----------------------------------------------------------------
    t0 = time.perf_counter()
    con.execute("""
        CREATE TABLE Cart1 AS SELECT * FROM (VALUES ('Sugar'), ('Bread'), ('Juice'), ('Soda'), ('Flour')) t(Item);
        CREATE TABLE Cart2 AS SELECT * FROM (VALUES ('Sugar'), ('Bread'), ('Butter'), ('Cheese'), ('Fruit')) t(Item);
    """)
    res1 = con.execute("""
        SELECT a.Item AS Cart1_Item, b.Item AS Cart2_Item
        FROM Cart1 a FULL OUTER JOIN Cart2 b ON a.Item = b.Item
        ORDER BY COALESCE(a.Item, b.Item);
    """).fetchall()
    dt1 = (time.perf_counter() - t0) * 1000
    assert len(res1) == 8, f"Expected 8 rows, got {len(res1)}"
    results.append(("Puzzle #1: Shopping Carts", "FULL OUTER JOIN / Set Division", len(res1), f"{dt1:.2f} ms", "PASS"))
    print(f"[PASS] Puzzle #1 (Shopping Carts) - {len(res1)} rows in {dt1:.2f} ms")

    # ----------------------------------------------------------------
    # Benchmark 2: Puzzle #2 - Managers and Employees (WITH RECURSIVE)
    # ----------------------------------------------------------------
    t0 = time.perf_counter()
    con.execute("""
        CREATE TABLE Employees AS SELECT * FROM (VALUES 
            (1001, NULL::INT, 'President', 185000),
            (2002, 1001, 'Director', 120000),
            (3003, 1001, 'Office Manager', 97000),
            (4004, 2002, 'Engineer', 110000),
            (5005, 2002, 'Engineer', 142000),
            (6006, 2002, 'Engineer', 160000)
        ) t(EmployeeID, ManagerID, JobTitle, Salary);
    """)
    res2 = con.execute("""
        WITH RECURSIVE EmployeeHierarchy AS (
            SELECT EmployeeID, ManagerID, JobTitle, Salary, 0 AS Depth, CAST(EmployeeID AS VARCHAR) AS OrgPath
            FROM Employees WHERE ManagerID IS NULL
            UNION ALL
            SELECT e.EmployeeID, e.ManagerID, e.JobTitle, e.Salary, h.Depth + 1, h.OrgPath || ' -> ' || CAST(e.EmployeeID AS VARCHAR)
            FROM Employees e INNER JOIN EmployeeHierarchy h ON e.ManagerID = h.EmployeeID
        )
        SELECT * FROM EmployeeHierarchy ORDER BY Depth, EmployeeID;
    """).fetchall()
    dt2 = (time.perf_counter() - t0) * 1000
    assert len(res2) == 6, f"Expected 6 rows, got {len(res2)}"
    assert res2[0][0] == 1001 and res2[0][4] == 0, "President must have depth 0"
    results.append(("Puzzle #2: Managers & Employees", "WITH RECURSIVE Hierarchy", len(res2), f"{dt2:.2f} ms", "PASS"))
    print(f"[PASS] Puzzle #2 (Managers & Employees) - {len(res2)} rows in {dt2:.2f} ms")

    # ----------------------------------------------------------------
    # Benchmark 3: Puzzle #4 - Two Predicates (FILTER Clause)
    # ----------------------------------------------------------------
    t0 = time.perf_counter()
    con.execute("""
        CREATE TABLE Orders AS SELECT * FROM (VALUES
            (1001, 'Ord936254', 'CA', 340.0),
            (1001, 'Ord143876', 'TX', 950.0),
            (1001, 'Ord654876', 'TX', 670.0),
            (1001, 'Ord814356', 'TX', 860.0),
            (2002, 'Ord342176', 'WA', 320.0),
            (3003, 'Ord265789', 'CA', 650.0),
            (3003, 'Ord387654', 'CA', 830.0),
            (4004, 'Ord476126', 'TX', 120.0)
        ) t(CustomerID, OrderID, DeliveryState, Amount);
    """)
    res3 = con.execute("""
        SELECT CustomerID
        FROM Orders
        GROUP BY CustomerID
        HAVING COUNT(*) FILTER (WHERE DeliveryState = 'CA') > 0
           AND COUNT(*) FILTER (WHERE DeliveryState = 'TX') > 0;
    """).fetchall()
    dt3 = (time.perf_counter() - t0) * 1000
    assert len(res3) == 1 and res3[0][0] == 1001, f"Expected CustomerID 1001 only, got {res3}"
    results.append(("Puzzle #4: Two Predicates", "COUNT(*) FILTER (WHERE ...)", len(res3), f"{dt3:.2f} ms", "PASS"))
    print(f"[PASS] Puzzle #4 (Two Predicates) - Customer {res3[0][0]} matched in {dt3:.2f} ms")

    # ----------------------------------------------------------------
    # Benchmark 4: Puzzle #6 - Workflow Steps (MATCH_RECOGNIZE)
    # ----------------------------------------------------------------
    t0 = time.perf_counter()
    con.execute("""
        CREATE TABLE WorkflowSteps AS SELECT * FROM (VALUES
            (1, 1, 'Complete'), (1, 2, 'Complete'), (1, 3, 'Error'), (1, 4, 'Complete'),
            (2, 1, 'Complete'), (2, 2, 'Complete'), (2, 3, 'Complete')
        ) t(WorkflowID, StepNumber, Status);
    """)
    res4 = con.execute("""
        SELECT WorkflowID, Status, StartStep, EndStep, StepCount
        FROM WorkflowSteps
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
    """).fetchall()
    dt4 = (time.perf_counter() - t0) * 1000
    assert len(res4) == 4, f"Expected 4 island groups, got {len(res4)}"
    results.append(("Puzzle #6: Workflow Steps", "MATCH_RECOGNIZE Gaps & Islands", len(res4), f"{dt4:.2f} ms", "PASS"))
    print(f"[PASS] Puzzle #6 (Workflow Steps) - {len(res4)} islands in {dt4:.2f} ms")

    # ----------------------------------------------------------------
    # Benchmark 5: Puzzle #25 - Top Vendors (QUALIFY Window Filter)
    # ----------------------------------------------------------------
    t0 = time.perf_counter()
    con.execute("""
        CREATE TABLE VendorOrders AS SELECT * FROM (VALUES
            ('Ord1', 101, 500.00), ('Ord2', 101, 750.00), ('Ord3', 101, 750.00),
            ('Ord4', 102, 300.00), ('Ord5', 102, 450.00)
        ) t(OrderID, VendorID, Amount);
    """)
    res5 = con.execute("""
        SELECT OrderID, VendorID, Amount
        FROM VendorOrders
        QUALIFY DENSE_RANK() OVER (PARTITION BY VendorID ORDER BY Amount DESC) = 1
        ORDER BY VendorID, OrderID;
    """).fetchall()
    dt5 = (time.perf_counter() - t0) * 1000
    assert len(res5) == 3, f"Expected 3 rows (with ties), got {len(res5)}"
    results.append(("Puzzle #25: Top Vendors", "QUALIFY DENSE_RANK Pushdown", len(res5), f"{dt5:.2f} ms", "PASS"))
    print(f"[PASS] Puzzle #25 (Top Vendors) - {len(res5)} rows in {dt5:.2f} ms")

    # ----------------------------------------------------------------
    # Benchmark 6: Puzzle #46 - Positive Balances (Aggregated MIN)
    # ----------------------------------------------------------------
    t0 = time.perf_counter()
    con.execute("""
        CREATE TABLE AccountBalances AS SELECT * FROM (VALUES
            (1001, DATE '2023-01-01', 100.0),
            (1001, DATE '2023-01-02', -50.0),
            (1001, DATE '2023-01-03', 200.0),
            (2002, DATE '2023-01-01', 500.0),
            (2002, DATE '2023-01-02', 400.0),
            (3003, DATE '2023-01-01', -10.0)
        ) t(AccountID, BalanceDate, Amount);
    """)
    res6 = con.execute("""
        SELECT AccountID
        FROM AccountBalances
        GROUP BY AccountID
        HAVING MIN(Amount) > 0;
    """).fetchall()
    dt6 = (time.perf_counter() - t0) * 1000
    assert len(res6) == 1 and res6[0][0] == 2002, f"Expected AccountID 2002 only, got {res6}"
    results.append(("Puzzle #46: Positive Balances", "GROUP BY / HAVING MIN(Amount) > 0", len(res6), f"{dt6:.2f} ms", "PASS"))
    print(f"[PASS] Puzzle #46 (Positive Balances) - Account {res6[0][0]} in {dt6:.2f} ms")

    print("\n================================================================")
    print("  DAILY BENCHMARK SUITE COMPLETED SUCCESSFULLY: 6 / 6 PASSED")
    print("================================================================\n")

    # ----------------------------------------------------------------
    # Write GitHub Actions Step Summary if running in CI
    # ----------------------------------------------------------------
    summary_path = os.getenv("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as f:
            f.write("## 🚀 Daily Multi-Dialect Benchmark Results\n\n")
            f.write("| Problem | Architecture / Paradigm | Result Rows | Execution Time | Status |\n")
            f.write("| :--- | :--- | :---: | :---: | :---: |\n")
            for name, pattern, rows, duration, status in results:
                f.write(f"| **{name}** | `{pattern}` | {rows} | {duration} | ✅ {status} |\n")
            f.write("\n> *All 6 landmark paradigms passed automated regression assertions.*\n")


if __name__ == "__main__":
    run_benchmark()
