-- ============================================================================
-- CS340 PA3 - sample tests.   SQL> @test_pa3_sample;
-- These show the PATTERN used by the (larger, hidden) grading tests:
--   1. run some DML,   2. check the outcome,   3. ROLLBACK so nothing is left.
-- Copy a block and adapt it to test your own edge cases.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET FEEDBACK OFF

PROMPT --- Part 1: views exist and have rows -----------------------------------
DECLARE
  v NUMBER;
BEGIN
  SELECT COUNT(*) INTO v FROM vw_ConnectionDirectory;
  DBMS_OUTPUT.PUT_LINE('vw_ConnectionDirectory rows (expect 75): ' || v);
  SELECT COUNT(*) INTO v FROM vw_BillPaymentStatus;
  DBMS_OUTPUT.PUT_LINE('vw_BillPaymentStatus rows (expect 900):  ' || v);
  SELECT COUNT(*) INTO v FROM vw_BillPaymentStatus WHERE DerivedStatus = 'UNPAID';
  DBMS_OUTPUT.PUT_LINE('  of which UNPAID (expect 11):           ' || v);
END;
/

PROMPT --- 2.1: an audit row is written for an INSERT ---------------------------
DECLARE
  v_before NUMBER; v_after NUMBER; v_new VARCHAR2(4000);
BEGIN
  SELECT COUNT(*) INTO v_before FROM AuditLog;
  pkg_audit.set_reason('sample test');

  INSERT INTO TaxRates (ConnectionTypeCode, TaxType, TaxAuthorityID, StartDate, EndDate, Rate)
  VALUES (1, 'SAMPLE', 'FBR', DATE '2030-01-01', DATE '2030-12-31', 0.05);

  SELECT COUNT(*) INTO v_after FROM AuditLog;
  DBMS_OUTPUT.PUT_LINE('audit rows added (expect 1): ' || (v_after - v_before));

  SELECT new_value INTO v_new FROM AuditLog WHERE id = (SELECT MAX(id) FROM AuditLog);
  DBMS_OUTPUT.PUT_LINE('new_value: ' || v_new);

  pkg_audit.clear_reason;
  ROLLBACK;                                   -- leave the database untouched
END;
/

PROMPT --- 2.2: an invalid tariff period must be rejected (-20010) --------------
DECLARE
  r Tariff%ROWTYPE;
BEGIN
  SELECT * INTO r FROM Tariff WHERE TariffCode = 'T-Res-0001';
  r.TariffCode := 'T-SAMPLE-1';
  r.StartDate  := DATE '2031-06-30';
  r.EndDate    := DATE '2031-01-01';          -- ends before it starts
  BEGIN
    INSERT INTO Tariff VALUES r;
    DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('error code (expect -20010): ' || SQLCODE);
  END;
  ROLLBACK;
END;
/

PROMPT --- 1.6: WITH CHECK OPTION in action ------------------------------------
DECLARE
  v_code NUMBER := 0;
BEGIN
  BEGIN
    UPDATE vw_ResidentialConnections SET ConnectionTypeCode = 11 WHERE ROWNUM = 1;
  EXCEPTION WHEN OTHERS THEN v_code := SQLCODE;
  END;
  DBMS_OUTPUT.PUT_LINE('moving a connection out of the range gives (expect -1402): ' || v_code);
  ROLLBACK;
END;
/

SET FEEDBACK ON
PROMPT Done. Remember: the hidden tests cover many more cases than these.
