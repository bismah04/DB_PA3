-- CS340 PA3 provided infrastructure. Run in a fresh SQL*Plus session.
-- Preserves compatible AuditLog/seq_AuditLog; replaces pkg_audit.
-- DDL can commit pending work. No PA2 data or functions are changed.
SET DEFINE OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
  n NUMBER;
  t NUMBER;
  s NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM user_tables WHERE table_name IN
    ('DIVINFO','CUSTOMERS','CONNECTIONTYPES','CONNECTIONS','TARIFF',
     'TAXAUTHORITY','TAXRATES','METERREADINGS','SUBSIDYPROVIDER','SUBSIDY',
     'BILL','BILLADJUSTMENTS','PAYMENTMETHODS','PAYMENTDETAILS','FIXEDCHARGES');
  IF n <> 15 THEN
    RAISE_APPLICATION_ERROR(-20980,'Use the populated PA2 schema, including FixedCharges.');
  END IF;
  SELECT COUNT(*) INTO n FROM user_tab_columns
  WHERE table_name='BILLADJUSTMENTS' AND column_name IN
    ('ADJUSTMENTDATE','OFFICERNAME','OFFICERDESIGNATION','ORIGINALBILLAMOUNT');
  IF n <> 4 THEN
    RAISE_APPLICATION_ERROR(-20980,'PA2 BillAdjustments columns are missing. PA1 alone is insufficient.');
  END IF;
  SELECT COUNT(*) INTO t FROM user_objects WHERE object_name='AUDITLOG';
  SELECT COUNT(*) INTO s FROM user_objects WHERE object_name='SEQ_AUDITLOG';
  IF t <> s OR t > 1 THEN
    RAISE_APPLICATION_ERROR(-20981,'Audit table/sequence must both exist or both be absent; inspect before repair.');
  END IF;
  IF t=1 THEN
    SELECT COUNT(*) INTO n FROM user_tables WHERE table_name='AUDITLOG';
    IF n<>1 THEN RAISE_APPLICATION_ERROR(-20981,'AuditLog name belongs to another object type.'); END IF;
    SELECT COUNT(*) INTO n FROM user_sequences
    WHERE sequence_name='SEQ_AUDITLOG' AND increment_by=1 AND cycle_flag='N';
    IF n<>1 THEN RAISE_APPLICATION_ERROR(-20981,'seq_AuditLog must be a noncycling increment-1 sequence.'); END IF;
    SELECT COUNT(*) INTO n FROM user_tab_columns WHERE table_name='AUDITLOG';
    IF n<>8 THEN RAISE_APPLICATION_ERROR(-20981,'Existing AuditLog has an incompatible column count.'); END IF;
    SELECT COUNT(*) INTO n FROM user_tab_columns WHERE table_name='AUDITLOG' AND
      ((column_id=1 AND column_name='ID' AND data_type='NUMBER' AND nullable='N') OR
       (column_id=2 AND column_name='TABLE_NAME' AND data_type='VARCHAR2' AND char_length=30 AND nullable='N') OR
       (column_id=3 AND column_name='OPERATION' AND data_type='VARCHAR2' AND char_length=6 AND nullable='N') OR
       (column_id=4 AND column_name='CHANGED_BY' AND data_type='VARCHAR2' AND char_length=128 AND nullable='N') OR
       (column_id=5 AND column_name='CHANGED_AT' AND data_type='TIMESTAMP(6)' AND nullable='N') OR
       (column_id=6 AND column_name='OLD_VALUE' AND data_type='VARCHAR2' AND char_length=4000 AND nullable='Y') OR
       (column_id=7 AND column_name='NEW_VALUE' AND data_type='VARCHAR2' AND char_length=4000 AND nullable='Y') OR
       (column_id=8 AND column_name='CHANGE_REASON' AND data_type='VARCHAR2' AND char_length=255 AND nullable='Y'));
    IF n<>8 THEN RAISE_APPLICATION_ERROR(-20981,'Existing AuditLog column definition differs from the provided contract.'); END IF;
    SELECT COUNT(*) INTO n FROM user_constraints c
    WHERE c.table_name='AUDITLOG' AND c.constraint_type='P' AND c.status='ENABLED'
      AND (SELECT COUNT(*) FROM user_cons_columns k WHERE k.constraint_name=c.constraint_name)=1
      AND EXISTS (SELECT 1 FROM user_cons_columns k WHERE k.constraint_name=c.constraint_name AND k.column_name='ID');
    IF n<>1 THEN RAISE_APPLICATION_ERROR(-20981,'Existing AuditLog needs its ID primary key.'); END IF;
  ELSE
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_AuditLog START WITH 1 INCREMENT BY 1 NOCYCLE';
    EXECUTE IMMEDIATE q'[
      CREATE TABLE AuditLog (
        id NUMBER PRIMARY KEY,
        table_name VARCHAR2(30) NOT NULL,
        operation VARCHAR2(6) NOT NULL,
        changed_by VARCHAR2(128) NOT NULL,
        changed_at TIMESTAMP NOT NULL,
        old_value VARCHAR2(4000),
        new_value VARCHAR2(4000),
        change_reason VARCHAR2(255)
      )]';
  END IF;
END;
/

CREATE OR REPLACE PACKAGE pkg_audit AS
  g_change_reason VARCHAR2(255);
  PROCEDURE set_reason(p_reason VARCHAR2);
  PROCEDURE clear_reason;
END pkg_audit;
/
SHOW ERRORS PACKAGE pkg_audit

CREATE OR REPLACE PACKAGE BODY pkg_audit AS
  PROCEDURE set_reason(p_reason VARCHAR2) IS
  BEGIN
    g_change_reason := SUBSTR(p_reason,1,255);
  END set_reason;
  PROCEDURE clear_reason IS
  BEGIN
    g_change_reason := NULL;
  END clear_reason;
END pkg_audit;
/
SHOW ERRORS PACKAGE BODY pkg_audit

DECLARE
  n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM user_objects
  WHERE object_name='PKG_AUDIT' AND object_type IN ('PACKAGE','PACKAGE BODY') AND status='VALID';
  IF n<>2 THEN RAISE_APPLICATION_ERROR(-20982,'pkg_audit did not compile; inspect USER_ERRORS.'); END IF;
END;
/
PROMPT PA3 infrastructure ready. Audit history and existing sequence values were preserved.
WHENEVER SQLERROR CONTINUE
