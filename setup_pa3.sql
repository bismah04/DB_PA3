-- ============================================================================
-- CS340 PA3 - setup script.  Run ONCE after the PA2 database is populated.
--   SQL> @setup_pa3;
-- Creates: seq_AuditLog, AuditLog, pkg_audit (spec + body).
-- Safe to re-run: it drops only these three objects first.
-- ============================================================================
SET SERVEROUTPUT ON
SET FEEDBACK OFF

BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE pkg_audit';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AuditLog CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_AuditLog'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE SEQUENCE seq_AuditLog START WITH 1 INCREMENT BY 1;

CREATE TABLE AuditLog (
  id            NUMBER PRIMARY KEY,
  table_name    VARCHAR2(30)   NOT NULL,
  operation     VARCHAR2(6)    NOT NULL,   -- 'INSERT' | 'UPDATE' | 'DELETE'
  changed_by    VARCHAR2(128)  NOT NULL,   -- USER
  changed_at    TIMESTAMP      NOT NULL,   -- SYSTIMESTAMP
  old_value     VARCHAR2(4000),            -- NULL for INSERT
  new_value     VARCHAR2(4000),            -- NULL for DELETE
  change_reason VARCHAR2(255)
);

CREATE OR REPLACE PACKAGE pkg_audit AS
  g_change_reason VARCHAR2(255);
  PROCEDURE set_reason(p_reason VARCHAR2);
  PROCEDURE clear_reason;
END pkg_audit;
/

CREATE OR REPLACE PACKAGE BODY pkg_audit AS
  PROCEDURE set_reason(p_reason VARCHAR2) IS
  BEGIN
    g_change_reason := SUBSTR(p_reason, 1, 255);
  END set_reason;

  PROCEDURE clear_reason IS
  BEGIN
    g_change_reason := NULL;
  END clear_reason;
END pkg_audit;
/

SHOW ERRORS
PROMPT PA3 setup complete.
SET FEEDBACK ON
