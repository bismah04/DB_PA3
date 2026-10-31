-- Read-only structure/compilation check; no commits or object changes.
-- Structural success does not establish implementation correctness.
SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR CONTINUE
DECLARE
  n NUMBER;
  cols VARCHAR2(4000);
  failures NUMBER:=0;
  PROCEDURE require_ok(ok BOOLEAN,label VARCHAR2) IS
  BEGIN
    IF ok THEN DBMS_OUTPUT.PUT_LINE('PASS|STRUCTURE|'||label);
    ELSE failures:=failures+1; DBMS_OUTPUT.PUT_LINE('FAIL|STRUCTURE|'||label); END IF;
  END;
BEGIN
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='VW_CONNECTIONDIRECTORY' AND object_type='VIEW' AND status='VALID';
  require_ok(n=1,'vw_ConnectionDirectory exists and is VALID');
  SELECT LISTAGG(column_name,',') WITHIN GROUP (ORDER BY column_id) INTO cols FROM user_tab_columns WHERE table_name='VW_CONNECTIONDIRECTORY';
  require_ok(cols='CONNECTIONID,CUSTOMERID,CUSTOMERNAME,ORGNAME,CONNECTIONTYPECODE,TYPEDESCRIPTION,DIVISIONNAME,SUBDIVNAME,STATUS','vw_ConnectionDirectory column names/order');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='VW_BILLPAYMENTSTATUS' AND object_type='VIEW' AND status='VALID';
  require_ok(n=1,'vw_BillPaymentStatus exists and is VALID');
  SELECT LISTAGG(column_name,',') WITHIN GROUP (ORDER BY column_id) INTO cols FROM user_tab_columns WHERE table_name='VW_BILLPAYMENTSTATUS';
  require_ok(cols='BILLID,CONNECTIONID,BILLINGMONTH,BILLINGYEAR,DUEDATE,TOTALPAID,PAYMENTCOUNT,LASTPAYMENTDATE,AMOUNTDUE,OUTSTANDING,DERIVEDSTATUS','vw_BillPaymentStatus column names/order');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='VW_CHARGECOMPONENTS' AND object_type='VIEW' AND status='VALID';
  require_ok(n=1,'vw_ChargeComponents exists and is VALID');
  SELECT LISTAGG(column_name,',') WITHIN GROUP (ORDER BY column_id) INTO cols FROM user_tab_columns WHERE table_name='VW_CHARGECOMPONENTS';
  require_ok(cols='COMPONENTTYPE,CONNECTIONTYPECODE,COMPONENTNAME,AUTHORITYORPROVIDER,STARTDATE,ENDDATE,VALUE','vw_ChargeComponents column names/order');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='VW_TARIFFRATEHISTORY' AND object_type='VIEW' AND status='VALID';
  require_ok(n=1,'vw_TariffRateHistory exists and is VALID');
  SELECT LISTAGG(column_name,',') WITHIN GROUP (ORDER BY column_id) INTO cols FROM user_tab_columns WHERE table_name='VW_TARIFFRATEHISTORY';
  require_ok(cols='TARIFFCODE,TARIFFTYPE,CONNECTIONTYPECODE,SLAB,STARTDATE,ENDDATE,THRESHOLDLOW_PERHOUR,THRESHOLDHIGH_PERHOUR,TARRIFDESCRIPTION,RATEPERUNIT,MINAMOUNT,MINUNIT,PREVRATEPERUNIT,CHANGEPCT','vw_TariffRateHistory column names/order');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='VW_DIVISIONMONTHLYREVENUE' AND object_type='VIEW' AND status='VALID';
  require_ok(n=1,'vw_DivisionMonthlyRevenue exists and is VALID');
  SELECT LISTAGG(column_name,',') WITHIN GROUP (ORDER BY column_id) INTO cols FROM user_tab_columns WHERE table_name='VW_DIVISIONMONTHLYREVENUE';
  require_ok(cols='DIVISIONNAME,BILLINGYEAR,BILLINGMONTH,NUMBILLS,TOTALBILLED,TOTALCOLLECTED,COLLECTIONRATEPCT','vw_DivisionMonthlyRevenue column names/order');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='VW_RESIDENTIALCONNECTIONS' AND object_type='VIEW' AND status='VALID';
  require_ok(n=1,'vw_ResidentialConnections exists and is VALID');
  SELECT LISTAGG(column_name,',') WITHIN GROUP (ORDER BY column_id) INTO cols FROM user_tab_columns WHERE table_name='VW_RESIDENTIALCONNECTIONS';
  require_ok(cols='CONNECTIONID,CUSTOMERID,DIVISIONID,SUBDIVID,CONNECTIONTYPECODE,INSTALLATIONDATE,METERTYPE,STATUS','vw_ResidentialConnections column names/order');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='VW_CUSTOMERBILLS' AND object_type='VIEW' AND status='VALID';
  require_ok(n=1,'vw_CustomerBills exists and is VALID');
  SELECT LISTAGG(column_name,',') WITHIN GROUP (ORDER BY column_id) INTO cols FROM user_tab_columns WHERE table_name='VW_CUSTOMERBILLS';
  require_ok(cols='BILLID,CONNECTIONID,BILLINGMONTH,BILLINGYEAR,DUEDATE,TOTALAMOUNT_BEFOREDUEDATE,TOTALAMOUNT_AFTERDUEDATE,CUSTOMERID,FIRSTNAME,LASTNAME,PHONENUMBER,EMAIL','vw_CustomerBills column names/order');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_AUDIT_TARIFF' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_audit_Tariff exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_AUDIT_TARIFF' AND status='ENABLED';
  require_ok(n=1,'trg_audit_Tariff enabled');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_AUDIT_TAXRATES' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_audit_TaxRates exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_AUDIT_TAXRATES' AND status='ENABLED';
  require_ok(n=1,'trg_audit_TaxRates enabled');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_AUDIT_FIXEDCHARGES' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_audit_FixedCharges exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_AUDIT_FIXEDCHARGES' AND status='ENABLED';
  require_ok(n=1,'trg_audit_FixedCharges enabled');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_AUDIT_SUBSIDY' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_audit_Subsidy exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_AUDIT_SUBSIDY' AND status='ENABLED';
  require_ok(n=1,'trg_audit_Subsidy enabled');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_TARIFF_VALIDITY' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_Tariff_Validity exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_TARIFF_VALIDITY' AND status='ENABLED';
  require_ok(n=1,'trg_Tariff_Validity enabled');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_TAXRATES_VALIDITY' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_TaxRates_Validity exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_TAXRATES_VALIDITY' AND status='ENABLED';
  require_ok(n=1,'trg_TaxRates_Validity enabled');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_PAYMENTDETAILS_FEE' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_PaymentDetails_Fee exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_PAYMENTDETAILS_FEE' AND status='ENABLED';
  require_ok(n=1,'trg_PaymentDetails_Fee enabled');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_BILLADJUSTMENTS_APPLY' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_BillAdjustments_Apply exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_BILLADJUSTMENTS_APPLY' AND status='ENABLED';
  require_ok(n=1,'trg_BillAdjustments_Apply enabled');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_BILL_PROTECT' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_Bill_Protect exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_BILL_PROTECT' AND status='ENABLED';
  require_ok(n=1,'trg_Bill_Protect enabled');
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name='TRG_VW_CUSTOMERBILLS_IO' AND object_type='TRIGGER' AND status='VALID';
  require_ok(n=1,'trg_vw_CustomerBills_IO exists and is VALID');
  SELECT COUNT(*) INTO n FROM user_triggers WHERE trigger_name='TRG_VW_CUSTOMERBILLS_IO' AND status='ENABLED';
  require_ok(n=1,'trg_vw_CustomerBills_IO enabled');
  FOR e IN (SELECT name,type,line,position,text FROM user_errors
            WHERE name IN ('VW_CONNECTIONDIRECTORY','VW_BILLPAYMENTSTATUS','VW_CHARGECOMPONENTS','VW_TARIFFRATEHISTORY','VW_DIVISIONMONTHLYREVENUE','VW_RESIDENTIALCONNECTIONS','VW_CUSTOMERBILLS','TRG_AUDIT_TARIFF','TRG_AUDIT_TAXRATES','TRG_AUDIT_FIXEDCHARGES','TRG_AUDIT_SUBSIDY','TRG_TARIFF_VALIDITY','TRG_TAXRATES_VALIDITY','TRG_PAYMENTDETAILS_FEE','TRG_BILLADJUSTMENTS_APPLY','TRG_BILL_PROTECT','TRG_VW_CUSTOMERBILLS_IO','PKG_AUDIT') ORDER BY name,type,sequence) LOOP
    DBMS_OUTPUT.PUT_LINE('DIAG|'||e.name||'|'||e.type||'|'||e.line||':'||e.position||'|'||e.text);
  END LOOP;
  IF failures>0 THEN
    DBMS_OUTPUT.PUT_LINE('FAIL|STRUCTURE_SUMMARY|'||failures);
    RAISE_APPLICATION_ERROR(-20990,'PA3 structure checks failed; inspect diagnostics.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('PASS|STRUCTURE_SUMMARY|17 fixed objects valid, required columns present, triggers enabled');
END;
/
