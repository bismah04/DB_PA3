-- ============================================================================
-- CS340 PA3 - Part 2: Triggers
-- Name:
-- Roll Number:
-- Section:
-- Run with:  SQL> @triggers;   (after @setup_pa3 and @views)
-- Each trigger below is an unsolved skeleton with the REQUIRED header
-- (timing, events, level). Fill in the bodies. Do not change the headers.
-- Full requirements and edge cases: PA3_questions.md.
-- Helpers, if needed, use prefix h_pa3_ and must appear before use.
-- Remember: no COMMIT / ROLLBACK / autonomous transactions inside triggers.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 Audit triggers.  One AuditLog row per affected row; format in the manual.
-- ANSWER 2.1: (why do the audit rows roll back with the failed statement?)
--
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_audit_Tariff
AFTER INSERT OR UPDATE OR DELETE ON Tariff
FOR EACH ROW
BEGIN
  NULL;  -- TODO
END;
/

CREATE OR REPLACE TRIGGER trg_audit_TaxRates
AFTER INSERT OR UPDATE OR DELETE ON TaxRates
FOR EACH ROW
BEGIN
  NULL;  -- TODO
END;
/

CREATE OR REPLACE TRIGGER trg_audit_FixedCharges
AFTER INSERT OR UPDATE OR DELETE ON FixedCharges
FOR EACH ROW
BEGIN
  NULL;  -- TODO
END;
/

CREATE OR REPLACE TRIGGER trg_audit_Subsidy
AFTER INSERT OR UPDATE OR DELETE ON Subsidy
FOR EACH ROW
BEGIN
  NULL;  -- TODO
END;
/

-- ----------------------------------------------------------------------------
-- 2.2 trg_Tariff_Validity  (COMPOUND trigger; errors -20010, -20011)
-- ANSWER 2.2: (why does a plain row-level trigger hit ORA-04091, and how does
--              the compound trigger avoid it?)
--
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_Tariff_Validity
FOR INSERT OR UPDATE ON Tariff
COMPOUND TRIGGER
  -- TODO: shared declarations if needed for your statement-level checks

  BEFORE EACH ROW IS
  BEGIN
    NULL;  -- TODO: StartDate <= EndDate, else -20010
  END BEFORE EACH ROW;

  AFTER EACH ROW IS
  BEGIN
    NULL;  -- TODO: collect relevant keys if needed by your approach
  END AFTER EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    NULL;  -- TODO: look for overlaps in the remembered groups, else -20011
  END AFTER STATEMENT;
END trg_Tariff_Validity;
/

-- ----------------------------------------------------------------------------
-- 2.3 trg_TaxRates_Validity  (COMPOUND trigger; errors -20012, -20013)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_TaxRates_Validity
FOR INSERT OR UPDATE ON TaxRates
COMPOUND TRIGGER
  BEFORE EACH ROW IS
  BEGIN
    NULL;  -- TODO
  END BEFORE EACH ROW;

  AFTER EACH ROW IS
  BEGIN
    NULL;  -- TODO
  END AFTER EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    NULL;  -- TODO
  END AFTER STATEMENT;
END trg_TaxRates_Validity;
/

-- ----------------------------------------------------------------------------
-- 2.4 trg_PaymentDetails_Fee  (JazzCash = PaymentMethodID 4, fee Rs. 50)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_PaymentDetails_Fee
BEFORE INSERT OR UPDATE OF AmountPaid, PaymentMethodID ON PaymentDetails
FOR EACH ROW
BEGIN
  NULL;  -- TODO
END;
/

-- ----------------------------------------------------------------------------
-- 2.5 trg_BillAdjustments_Apply  (errors -20020, -20021)
-- Hint: you need work BEFORE the row is stored and AFTER it is stored.
--       One compound trigger does both.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_BillAdjustments_Apply
FOR INSERT ON BillAdjustments
COMPOUND TRIGGER
  BEFORE EACH ROW IS
  BEGIN
    NULL;  -- TODO: bill must exist (-20020); default OriginalBillAmount, AdjustmentDate
  END BEFORE EACH ROW;

  AFTER EACH ROW IS
  BEGIN
    NULL;  -- TODO: apply cumulative adjustment atomically; negative total -> -20021
  END AFTER EACH ROW;
END trg_BillAdjustments_Apply;
/

-- ----------------------------------------------------------------------------
-- 2.6 trg_Bill_Protect  (errors -20030, -20031)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_Bill_Protect
BEFORE UPDATE OR DELETE ON Bill
FOR EACH ROW
BEGIN
  NULL;  -- TODO
END;
/

-- ----------------------------------------------------------------------------
-- 2.7 trg_vw_CustomerBills_IO  (errors -20040, -20041)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_vw_CustomerBills_IO
INSTEAD OF INSERT OR UPDATE OR DELETE ON vw_CustomerBills
FOR EACH ROW
BEGIN
  NULL;  -- TODO
END;
/
