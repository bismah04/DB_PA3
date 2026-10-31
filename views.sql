-- CS340 PA3 - Views
-- Name:
-- Roll Number:
-- Section:
-- Unsolved scaffolding: replace every empty typed SELECT with your query.
-- Preserve names and column order. See PA3_questions.md for the full contract.
-- Run after setup_pa3.sql; run triggers.sql again whenever views are replaced.

-- 1.1 vw_ConnectionDirectory
CREATE OR REPLACE VIEW vw_ConnectionDirectory AS
SELECT CAST(NULL AS VARCHAR2(20)) AS ConnectionID,
       CAST(NULL AS VARCHAR2(20)) AS CustomerID,
       CAST(NULL AS VARCHAR2(101)) AS CustomerName,
       CAST(NULL AS VARCHAR2(150)) AS OrgName,
       CAST(NULL AS NUMBER) AS ConnectionTypeCode,
       CAST(NULL AS VARCHAR2(50)) AS TypeDescription,
       CAST(NULL AS VARCHAR2(50)) AS DivisionName,
       CAST(NULL AS VARCHAR2(50)) AS SubDivName,
       CAST(NULL AS VARCHAR2(50)) AS Status
FROM dual
WHERE 1 = 0;

-- 1.2 vw_BillPaymentStatus
CREATE OR REPLACE VIEW vw_BillPaymentStatus AS
SELECT CAST(NULL AS NUMBER) AS BillID,
       CAST(NULL AS VARCHAR2(20)) AS ConnectionID,
       CAST(NULL AS NUMBER) AS BillingMonth,
       CAST(NULL AS NUMBER) AS BillingYear,
       CAST(NULL AS DATE) AS DueDate,
       CAST(NULL AS NUMBER) AS TotalPaid,
       CAST(NULL AS NUMBER) AS PaymentCount,
       CAST(NULL AS DATE) AS LastPaymentDate,
       CAST(NULL AS NUMBER) AS AmountDue,
       CAST(NULL AS NUMBER) AS Outstanding,
       CAST(NULL AS VARCHAR2(7)) AS DerivedStatus
FROM dual
WHERE 1 = 0;

-- 1.3 vw_ChargeComponents
CREATE OR REPLACE VIEW vw_ChargeComponents AS
SELECT CAST(NULL AS VARCHAR2(7)) AS ComponentType,
       CAST(NULL AS NUMBER) AS ConnectionTypeCode,
       CAST(NULL AS VARCHAR2(50)) AS ComponentName,
       CAST(NULL AS VARCHAR2(50)) AS AuthorityOrProvider,
       CAST(NULL AS DATE) AS StartDate,
       CAST(NULL AS DATE) AS EndDate,
       CAST(NULL AS NUMBER) AS Value
FROM dual
WHERE 1 = 0;

-- 1.4 vw_TariffRateHistory
CREATE OR REPLACE VIEW vw_TariffRateHistory AS
SELECT CAST(NULL AS VARCHAR2(50)) AS TariffCode,
       CAST(NULL AS NUMBER) AS TariffType,
       CAST(NULL AS NUMBER) AS ConnectionTypeCode,
       CAST(NULL AS NUMBER) AS Slab,
       CAST(NULL AS DATE) AS StartDate,
       CAST(NULL AS DATE) AS EndDate,
       CAST(NULL AS NUMBER) AS ThresholdLow_perHour,
       CAST(NULL AS NUMBER) AS ThresholdHigh_perHour,
       CAST(NULL AS VARCHAR2(50)) AS TarrifDescription,
       CAST(NULL AS NUMBER) AS RatePerUnit,
       CAST(NULL AS NUMBER) AS MinAmount,
       CAST(NULL AS NUMBER) AS MinUnit,
       CAST(NULL AS NUMBER) AS PrevRatePerUnit,
       CAST(NULL AS NUMBER) AS ChangePct
FROM dual
WHERE 1 = 0;

-- 1.5 vw_DivisionMonthlyRevenue
CREATE OR REPLACE VIEW vw_DivisionMonthlyRevenue AS
SELECT CAST(NULL AS VARCHAR2(50)) AS DivisionName,
       CAST(NULL AS NUMBER) AS BillingYear,
       CAST(NULL AS NUMBER) AS BillingMonth,
       CAST(NULL AS NUMBER) AS NumBills,
       CAST(NULL AS NUMBER) AS TotalBilled,
       CAST(NULL AS NUMBER) AS TotalCollected,
       CAST(NULL AS NUMBER) AS CollectionRatePct
FROM dual
WHERE 1 = 0;

-- 1.6 vw_ResidentialConnections
-- ANSWER 1.6: TODO - explain rejection by WITH CHECK OPTION.
CREATE OR REPLACE VIEW vw_ResidentialConnections AS
SELECT CAST(NULL AS VARCHAR2(20)) AS ConnectionID,
       CAST(NULL AS VARCHAR2(20)) AS CustomerID,
       CAST(NULL AS NUMBER) AS DivisionID,
       CAST(NULL AS NUMBER) AS SubDivID,
       CAST(NULL AS NUMBER) AS ConnectionTypeCode,
       CAST(NULL AS DATE) AS InstallationDate,
       CAST(NULL AS VARCHAR2(50)) AS MeterType,
       CAST(NULL AS VARCHAR2(50)) AS Status
FROM dual
WHERE 1 = 0;

-- 1.7 vw_CustomerBills
CREATE OR REPLACE VIEW vw_CustomerBills AS
SELECT CAST(NULL AS NUMBER) AS BillID,
       CAST(NULL AS VARCHAR2(20)) AS ConnectionID,
       CAST(NULL AS NUMBER) AS BillingMonth,
       CAST(NULL AS NUMBER) AS BillingYear,
       CAST(NULL AS DATE) AS DueDate,
       CAST(NULL AS NUMBER) AS TotalAmount_BeforeDueDate,
       CAST(NULL AS NUMBER) AS TotalAmount_AfterDueDate,
       CAST(NULL AS VARCHAR2(20)) AS CustomerID,
       CAST(NULL AS VARCHAR2(50)) AS FirstName,
       CAST(NULL AS VARCHAR2(50)) AS LastName,
       CAST(NULL AS VARCHAR2(15)) AS PhoneNumber,
       CAST(NULL AS VARCHAR2(100)) AS Email
FROM dual
WHERE 1 = 0;
