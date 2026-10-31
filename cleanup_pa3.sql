-- Optional PA3 object cleanup. DDL commits pending work; use a fresh session.
-- Drops only the 7 named views and 10 named triggers below.
-- Preserves AuditLog, seq_AuditLog, pkg_audit, helpers, PA2 objects and data.
-- Unexpected drop failures stop execution; only absent objects are ignored.
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
DECLARE
  PROCEDURE drop_named(p_type VARCHAR2,p_name VARCHAR2) IS
    n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO n FROM user_objects
    WHERE object_type=p_type AND object_name=UPPER(p_name);
    IF n=1 THEN
      EXECUTE IMMEDIATE 'DROP '||p_type||' '||p_name;
      DBMS_OUTPUT.PUT_LINE('Dropped '||p_type||' '||p_name);
    END IF;
  END;
BEGIN
  drop_named('TRIGGER','trg_vw_CustomerBills_IO');
  drop_named('TRIGGER','trg_Bill_Protect');
  drop_named('TRIGGER','trg_BillAdjustments_Apply');
  drop_named('TRIGGER','trg_PaymentDetails_Fee');
  drop_named('TRIGGER','trg_TaxRates_Validity');
  drop_named('TRIGGER','trg_Tariff_Validity');
  drop_named('TRIGGER','trg_audit_Subsidy');
  drop_named('TRIGGER','trg_audit_FixedCharges');
  drop_named('TRIGGER','trg_audit_TaxRates');
  drop_named('TRIGGER','trg_audit_Tariff');
  drop_named('VIEW','vw_CustomerBills');
  drop_named('VIEW','vw_ResidentialConnections');
  drop_named('VIEW','vw_DivisionMonthlyRevenue');
  drop_named('VIEW','vw_TariffRateHistory');
  drop_named('VIEW','vw_ChargeComponents');
  drop_named('VIEW','vw_BillPaymentStatus');
  drop_named('VIEW','vw_ConnectionDirectory');
END;
/
PROMPT Fixed PA3 views/triggers removed. Audit infrastructure/history preserved.
PROMPT Rebuild views.sql, then triggers.sql.
WHENEVER SQLERROR CONTINUE
