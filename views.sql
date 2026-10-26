-- ============================================================================
-- CS340 PA3 - Part 1: Views            Name: ____________  Roll no: ________
-- Run with:  SQL> @views;      (after @setup_pa3)
-- Rules: keep every object name; keep column names/order from the manual;
--        use CREATE OR REPLACE VIEW; no DROP/ALTER/GRANT/COMMIT/SET here.
-- Each view below is a placeholder (SELECT 1 AS todo) so the file compiles.
-- Replace the placeholder with your real query.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 vw_ConnectionDirectory
-- Columns: ConnectionID, CustomerID, CustomerName, OrgName, ConnectionTypeCode,
--          TypeDescription, DivisionName, SubDivName, Status
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_ConnectionDirectory AS
SELECT 1 AS todo FROM dual;

-- ----------------------------------------------------------------------------
-- 1.2 vw_BillPaymentStatus
-- Columns: BillID, ConnectionID, BillingMonth, BillingYear, DueDate,
--          TotalPaid, PaymentCount, LastPaymentDate, AmountDue, Outstanding,
--          DerivedStatus
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_BillPaymentStatus AS
SELECT 1 AS todo FROM dual;

-- ----------------------------------------------------------------------------
-- 1.3 vw_ChargeComponents      (UNION ALL of TaxRates, FixedCharges, Subsidy)
-- Columns: ComponentType, ConnectionTypeCode, ComponentName,
--          AuthorityOrProvider, StartDate, EndDate, Value
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_ChargeComponents AS
SELECT 1 AS todo FROM dual;

-- ----------------------------------------------------------------------------
-- 1.4 vw_TariffRateHistory
-- Columns: all Tariff columns (table order), PrevRatePerUnit, ChangePct
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_TariffRateHistory AS
SELECT 1 AS todo FROM dual;

-- ----------------------------------------------------------------------------
-- 1.5 vw_DivisionMonthlyRevenue   (must be built on vw_BillPaymentStatus)
-- Columns: DivisionName, BillingYear, BillingMonth, NumBills, TotalBilled,
--          TotalCollected, CollectionRatePct
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_DivisionMonthlyRevenue AS
SELECT 1 AS todo FROM dual;

-- ----------------------------------------------------------------------------
-- 1.6 vw_ResidentialConnections   (updatable, WITH CHECK OPTION)
-- Columns: all Connections columns, table order. ConnectionTypeCode 1..4 only.
--
-- ANSWER 1.6: (write your answer here, as comment lines)
--
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_ResidentialConnections AS
SELECT 1 AS todo FROM dual;

-- ----------------------------------------------------------------------------
-- 1.7 vw_CustomerBills            (made writable by trigger 2.7)
-- Columns: BillID, ConnectionID, BillingMonth, BillingYear, DueDate,
--          TotalAmount_BeforeDueDate, TotalAmount_AfterDueDate,
--          CustomerID, FirstName, LastName, PhoneNumber, Email
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_CustomerBills AS
SELECT 1 AS todo FROM dual;

SHOW ERRORS
