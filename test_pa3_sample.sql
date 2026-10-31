-- Public examples, not the complete grader. Requires completed views/triggers.
-- No DDL or COMMIT; each case rolls back to its own savepoint on success/failure.
-- Reserved fixture identities are checked before use. Sequence gaps are normal.
-- The final exception signals test failures; this script does not exit SQL*Plus.
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR CONTINUE

DECLARE
  failures PLS_INTEGER := 0;
  saved_reason VARCHAR2(255) := pkg_audit.g_change_reason;
  PROCEDURE equal_num(actual NUMBER, expected NUMBER, label VARCHAR2) IS
  BEGIN
    IF actual IS NULL OR expected IS NULL OR actual<>expected THEN
      RAISE_APPLICATION_ERROR(-20990,label||': expected '||expected||', got '||NVL(TO_CHAR(actual),'NULL'));
    END IF;
  END;
  PROCEDURE equal_text(actual VARCHAR2, expected VARCHAR2, label VARCHAR2) IS
  BEGIN
    IF (actual IS NULL AND expected IS NOT NULL) OR
       (actual IS NOT NULL AND expected IS NULL) OR actual<>expected THEN
      RAISE_APPLICATION_ERROR(-20990,label||': text mismatch');
    END IF;
  END;
  PROCEDURE new_bill IS
    n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO n FROM Bill WHERE BillID IN (-934000001,-934000002);
    equal_num(n,0,'reserved bill identities must be unused');
    INSERT INTO Bill (BillID,ConnectionID,BillingMonth,BillingYear,BillIssueDate,
                      DueDate,TotalAmount_BeforeDueDate,TotalAmount_AfterDueDate,AdjustmentAmount)
    SELECT -934000001,MIN(ConnectionID),1,2037,DATE '2037-01-01',
           DATE '2037-01-20',1000,1100,0 FROM Connections;
    SELECT COUNT(*) INTO n FROM Bill b JOIN Connections c ON c.ConnectionID=b.ConnectionID
    WHERE b.BillID=-934000001;
    equal_num(n,1,'bill fixture needs a connection');
  END;
  PROCEDURE run_case(id VARCHAR2) IS
    n NUMBER; m NUMBER; a NUMBER; b NUMBER; c NUMBER; code NUMBER;
    txt VARCHAR2(4000); old_txt VARCHAR2(4000); reason VARCHAR2(255);
    who VARCHAR2(128); op VARCHAR2(6); tab VARCHAR2(30); ts TIMESTAMP;
    d DATE; r Tariff%ROWTYPE; conn Connections%ROWTYPE;
    customer VARCHAR2(20);
  BEGIN
    SAVEPOINT pa3_sample_case;
    BEGIN
      IF id='V_DIRECTORY' THEN
        SELECT COUNT(*) INTO n FROM Connections;
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM vw_ConnectionDirectory' INTO m;
        equal_num(m,n,'directory row count');
        SELECT COUNT(*) INTO n FROM Bill;
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM vw_BillPaymentStatus' INTO m;
        equal_num(m,n,'payment status row count');
      ELSIF id='V_PAYMENTS' THEN
        new_bill;
        EXECUTE IMMEDIATE 'SELECT TotalPaid,PaymentCount,AmountDue,Outstanding,DerivedStatus
                          FROM vw_BillPaymentStatus WHERE BillID=-934000001'
        INTO a,b,c,n,txt;
        equal_num(a,0,'unpaid total'); equal_num(b,0,'unpaid count');
        equal_num(c,1100,'unpaid after-due amount'); equal_num(n,1100,'unpaid outstanding');
        equal_text(txt,'UNPAID','unpaid status');
        INSERT INTO PaymentDetails VALUES (-934000001,DATE '2037-01-10','Paid',1,600);
        EXECUTE IMMEDIATE 'SELECT AmountDue,Outstanding,DerivedStatus FROM vw_BillPaymentStatus
                          WHERE BillID=-934000001' INTO a,b,txt;
        equal_num(a,1000,'on-time amount'); equal_num(b,400,'partial outstanding');
        equal_text(txt,'PARTIAL','partial status');
        INSERT INTO PaymentDetails VALUES (-934000001,DATE '2037-02-10','Paid',1,600);
        EXECUTE IMMEDIATE 'SELECT TotalPaid,PaymentCount,AmountDue,Outstanding,DerivedStatus
                          FROM vw_BillPaymentStatus WHERE BillID=-934000001' INTO a,b,c,n,txt;
        equal_num(a,1200,'payment sum'); equal_num(b,2,'payment count');
        equal_num(c,1100,'last payment determines lateness'); equal_num(n,0,'overpaid outstanding');
        equal_text(txt,'PAID','overpaid status');
      ELSIF id='T_AUDIT' THEN
        SELECT COUNT(*) INTO n FROM TaxRates WHERE TaxType='PA3_SAMPLE_AUDIT';
        equal_num(n,0,'reserved tax group unused');
        SELECT COUNT(*) INTO a FROM AuditLog;
        pkg_audit.set_reason('public sample reason');
        INSERT INTO TaxRates VALUES (1,'PA3_SAMPLE_AUDIT','FBR',DATE '2037-01-01',DATE '2037-12-31',0.05);
        SELECT COUNT(*) INTO b FROM AuditLog;
        equal_num(b-a,1,'insert audit count');
        SELECT table_name,operation,changed_by,changed_at,old_value,new_value,change_reason
        INTO tab,op,who,ts,old_txt,txt,reason FROM AuditLog
        WHERE id=(SELECT MAX(id) FROM AuditLog);
        equal_text(tab,'TaxRates','audit table'); equal_text(op,'INSERT','audit operation');
        equal_text(who,USER,'audit user'); equal_text(reason,'public sample reason','audit reason');
        equal_text(old_txt,NULL,'insert old snapshot');
        IF ts IS NULL THEN RAISE_APPLICATION_ERROR(-20990,'audit timestamp is NULL'); END IF;
        equal_text(txt,'ConnectionTypeCode='||TO_CHAR(1)||';TaxType=PA3_SAMPLE_AUDIT;TaxAuthorityID=FBR;StartDate=2037-01-01;EndDate=2037-12-31;Rate='||TO_CHAR(0.05),'insert snapshot');
        UPDATE TaxRates SET Rate=Rate WHERE TaxType='PA3_SAMPLE_AUDIT';
        SELECT COUNT(*) INTO b FROM AuditLog;
        equal_num(b-a,1,'no-op update produces no audit');
      ELSIF id='T_TARIFF_DATES' THEN
        SELECT * INTO r FROM Tariff WHERE TariffCode=(SELECT MIN(TariffCode) FROM Tariff);
        SELECT COUNT(*) INTO n FROM Tariff WHERE TariffCode='PA3_SAMPLE_TARIFF';
        equal_num(n,0,'reserved tariff key unused');
        r.TariffCode:='PA3_SAMPLE_TARIFF'; r.StartDate:=DATE '2037-12-31'; r.EndDate:=DATE '2037-01-01';
        SELECT COUNT(*) INTO a FROM AuditLog;
        code:=0;
        BEGIN INSERT INTO Tariff VALUES r;
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20010,'invalid tariff period code');
        SELECT COUNT(*) INTO b FROM AuditLog;
        equal_num(b,a,'failed tariff insert leaves no audit');
      ELSIF id='T_TAX_MULTIROW' THEN
        SELECT COUNT(*) INTO n FROM TaxRates WHERE TaxType='PA3_SAMPLE_MULTI';
        equal_num(n,0,'reserved tax group unused');
        SELECT COUNT(*) INTO a FROM AuditLog;
        code:=0;
        BEGIN
          INSERT INTO TaxRates (ConnectionTypeCode,TaxType,TaxAuthorityID,StartDate,EndDate,Rate)
          SELECT 1,'PA3_SAMPLE_MULTI','FBR',DATE '2037-01-01',DATE '2037-06-30',0.05 FROM dual
          UNION ALL
          SELECT 1,'PA3_SAMPLE_MULTI','FBR',DATE '2037-06-30',DATE '2037-12-31',0.06 FROM dual;
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20013,'inclusive multi-row overlap code');
        SELECT COUNT(*) INTO n FROM TaxRates WHERE TaxType='PA3_SAMPLE_MULTI';
        equal_num(n,0,'failed statement leaves no tax rows');
        SELECT COUNT(*) INTO b FROM AuditLog;
        equal_num(b,a,'failed multi-row statement leaves no audit');
      ELSIF id='V_RESIDENTIAL' THEN
        SELECT * INTO conn FROM Connections WHERE ConnectionID=
          (SELECT MIN(ConnectionID) FROM Connections WHERE ConnectionTypeCode BETWEEN 1 AND 4);
        SELECT COUNT(*) INTO n FROM Connections WHERE ConnectionID='PA3_SAMPLE_CONN';
        equal_num(n,0,'reserved connection key unused');
        conn.ConnectionID:='PA3_SAMPLE_CONN';
        INSERT INTO Connections VALUES conn;
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM vw_ResidentialConnections WHERE ConnectionID=''PA3_SAMPLE_CONN''' INTO n;
        equal_num(n,1,'fixture visible in residential view');
        code:=0;
        BEGIN
          EXECUTE IMMEDIATE 'UPDATE vw_ResidentialConnections SET ConnectionTypeCode=11 WHERE ConnectionID=''PA3_SAMPLE_CONN''';
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-1402,'check option rejection');
      ELSIF id='T_FEE' THEN
        new_bill;
        INSERT INTO PaymentDetails VALUES (-934000001,DATE '2037-01-10','Paid',4,100);
        SELECT AmountPaid INTO a FROM PaymentDetails WHERE BillID=-934000001;
        equal_num(a,150,'JazzCash insert fee');
        UPDATE PaymentDetails SET PaymentMethodID=1 WHERE BillID=-934000001;
        SELECT AmountPaid INTO a FROM PaymentDetails WHERE BillID=-934000001;
        equal_num(a,100,'fee refund');
        UPDATE PaymentDetails SET PaymentMethodID=4 WHERE BillID=-934000001;
        UPDATE PaymentDetails SET PaymentMethodID=4 WHERE BillID=-934000001;
        SELECT AmountPaid INTO a FROM PaymentDetails WHERE BillID=-934000001;
        equal_num(a,150,'same-method update no extra fee');
        UPDATE PaymentDetails SET AmountPaid=200,PaymentMethodID=4 WHERE BillID=-934000001;
        SELECT AmountPaid INTO a FROM PaymentDetails WHERE BillID=-934000001;
        equal_num(a,250,'new base amount priority');
        UPDATE PaymentDetails SET AmountPaid=NULL WHERE BillID=-934000001;
        SELECT AmountPaid INTO a FROM PaymentDetails WHERE BillID=-934000001;
        IF a IS NOT NULL THEN RAISE_APPLICATION_ERROR(-20990,'NULL amount was changed'); END IF;
      ELSIF id='T_ADJUSTMENT' THEN
        new_bill;
        SELECT COUNT(*) INTO n FROM BillAdjustments WHERE AdjustmentID IN ('PA3_SAMPLE_A1','PA3_SAMPLE_A2','PA3_SAMPLE_A3','PA3_SAMPLE_A4','PA3_SAMPLE_A5','PA3_SAMPLE_A6');
        equal_num(n,0,'reserved adjustment keys unused');
        INSERT INTO BillAdjustments (AdjustmentID,BillID,AdjustmentAmount)
        VALUES ('PA3_SAMPLE_A1',-934000001,100);
        SELECT TotalAmount_BeforeDueDate,TotalAmount_AfterDueDate,AdjustmentAmount
        INTO a,b,c FROM Bill WHERE BillID=-934000001;
        equal_num(a,900,'adjusted before-due total'); equal_num(b,990,'adjusted after-due total');
        equal_num(c,100,'cumulative adjustment');
        SELECT OriginalBillAmount,AdjustmentDate INTO a,d FROM BillAdjustments WHERE AdjustmentID='PA3_SAMPLE_A1';
        equal_num(a,1000,'original amount default');
        IF d IS NULL OR d<>TRUNC(SYSDATE) THEN RAISE_APPLICATION_ERROR(-20990,'adjustment date default'); END IF;
        INSERT INTO BillAdjustments (AdjustmentID,BillID,AdjustmentAmount,OriginalBillAmount,AdjustmentDate)
        VALUES ('PA3_SAMPLE_A2',-934000001,200,999,DATE '2036-01-01');
        SELECT TotalAmount_BeforeDueDate,TotalAmount_AfterDueDate,AdjustmentAmount INTO a,b,c
        FROM Bill WHERE BillID=-934000001;
        equal_num(a,700,'second adjustment total'); equal_num(b,770,'second after-due total'); equal_num(c,300,'second accumulation');
        SELECT OriginalBillAmount,AdjustmentDate INTO a,d FROM BillAdjustments WHERE AdjustmentID='PA3_SAMPLE_A2';
        equal_num(a,999,'explicit original amount preserved');
        IF d<>DATE '2036-01-01' OR d IS NULL THEN RAISE_APPLICATION_ERROR(-20990,'explicit date changed'); END IF;
        code:=0;
        BEGIN
          INSERT INTO BillAdjustments (AdjustmentID,BillID,AdjustmentAmount) VALUES ('PA3_SAMPLE_A3',-934000001,701);
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20021,'over-adjustment code');
        SELECT TotalAmount_BeforeDueDate INTO a FROM Bill WHERE BillID=-934000001;
        equal_num(a,700,'rejected adjustment preserves bill');
        SELECT COUNT(*) INTO n FROM BillAdjustments WHERE BillID=-934000001;
        equal_num(n,2,'rejected adjustment is absent');
        code:=0;
        BEGIN
          INSERT INTO BillAdjustments (AdjustmentID,BillID,AdjustmentAmount)
          SELECT 'PA3_SAMPLE_A5',-934000001,400 FROM dual
          UNION ALL SELECT 'PA3_SAMPLE_A6',-934000001,400 FROM dual;
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20021,'cumulative multi-row over-adjustment code');
        SELECT TotalAmount_BeforeDueDate,TotalAmount_AfterDueDate,AdjustmentAmount
        INTO a,b,c FROM Bill WHERE BillID=-934000001;
        equal_num(a,700,'failed statement restores before-due total');
        equal_num(b,770,'failed statement restores after-due total');
        equal_num(c,300,'failed statement restores accumulated adjustment');
        SELECT COUNT(*) INTO n FROM BillAdjustments WHERE BillID=-934000001;
        equal_num(n,2,'failed statement leaves no partial adjustments');
        code:=0;
        BEGIN
          INSERT INTO BillAdjustments (AdjustmentID,BillID,AdjustmentAmount) VALUES ('PA3_SAMPLE_A4',-934000002,1);
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20020,'missing bill code');
      ELSIF id='T_PROTECT' THEN
        new_bill;
        INSERT INTO PaymentDetails VALUES (-934000001,DATE '2037-01-10','Paid',1,10);
        code:=0;
        BEGIN DELETE FROM Bill WHERE BillID=-934000001;
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20030,'paid bill delete code');
        code:=0;
        BEGIN UPDATE Bill SET BillingMonth=BillingMonth WHERE BillID=-934000001;
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20031,'targeted protected column code');
      ELSIF id='T_PORTAL' THEN
        new_bill;
        SELECT c.CustomerID INTO customer FROM Connections c JOIN Bill b ON b.ConnectionID=c.ConnectionID
        WHERE b.BillID=-934000001;
        EXECUTE IMMEDIATE 'UPDATE vw_CustomerBills SET PhoneNumber=''03000000000'',Email=''pa3.sample@example.test'' WHERE BillID=-934000001';
        equal_num(SQL%ROWCOUNT,1,'portal fixture matched');
        SELECT PhoneNumber,Email INTO old_txt,txt FROM Customers WHERE CustomerID=customer;
        equal_text(old_txt,'03000000000','portal phone'); equal_text(txt,'pa3.sample@example.test','portal email');
        EXECUTE IMMEDIATE 'UPDATE vw_CustomerBills SET DueDate=DueDate WHERE BillID=-934000001';
        code:=0;
        BEGIN EXECUTE IMMEDIATE 'UPDATE vw_CustomerBills SET BillingMonth=2,Email=''blocked@example.test'' WHERE BillID=-934000001';
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20040,'portal non-contact update code');
        SELECT Email INTO txt FROM Customers WHERE CustomerID=customer;
        equal_text(txt,'pa3.sample@example.test','rejected mixed update preserves contact');
        code:=0;
        BEGIN EXECUTE IMMEDIATE 'DELETE FROM vw_CustomerBills WHERE BillID=-934000001';
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20041,'portal delete code');
        code:=0;
        BEGIN EXECUTE IMMEDIATE 'INSERT INTO vw_CustomerBills (BillID) VALUES (-934000002)';
        EXCEPTION WHEN OTHERS THEN code:=SQLCODE; END;
        equal_num(code,-20041,'portal insert code');
      ELSE
        RAISE_APPLICATION_ERROR(-20990,'Unknown public test');
      END IF;
      DBMS_OUTPUT.PUT_LINE('PASS|'||id);
    EXCEPTION WHEN OTHERS THEN
      failures:=failures+1;
      DBMS_OUTPUT.PUT_LINE('FAIL|'||id||'|'||SQLCODE||'|'||SQLERRM);
    END;
    ROLLBACK TO pa3_sample_case;
    pkg_audit.set_reason(saved_reason);
  END;
BEGIN
  run_case('V_DIRECTORY');
  run_case('V_PAYMENTS');
  run_case('T_AUDIT');
  run_case('T_TARIFF_DATES');
  run_case('T_TAX_MULTIROW');
  run_case('V_RESIDENTIAL');
  run_case('T_FEE');
  run_case('T_ADJUSTMENT');
  run_case('T_PROTECT');
  run_case('T_PORTAL');
  IF failures>0 THEN
    DBMS_OUTPUT.PUT_LINE('FAIL|PUBLIC_SUMMARY|'||failures||' failed of 10');
    RAISE_APPLICATION_ERROR(-20990,'Public samples failed; inspect FAIL markers above.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('PASS|PUBLIC_SUMMARY|10 passed');
END;
/
