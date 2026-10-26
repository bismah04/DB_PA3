-- ============================================================================
-- CS340 PA3 - cleanup script.  Drops EVERY PA3 object (views, triggers,
-- AuditLog, seq_AuditLog, pkg_audit, and your h_ helper objects).
-- It never touches the PA2 tables or data.
--   SQL> @cleanup_pa3;
-- ============================================================================
SET SERVEROUTPUT ON
SET FEEDBACK OFF

DECLARE
  PROCEDURE drop_it(p_type VARCHAR2, p_name VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP ' || p_type || ' ' || p_name ||
                      CASE WHEN p_type = 'TABLE' THEN ' CASCADE CONSTRAINTS' ELSE '' END;
    DBMS_OUTPUT.PUT_LINE('dropped ' || p_type || ' ' || p_name);
  EXCEPTION WHEN OTHERS THEN NULL;     -- did not exist
  END;
BEGIN
  -- every trigger in this schema (PA2 had none)
  FOR r IN (SELECT trigger_name FROM user_triggers) LOOP
    drop_it('TRIGGER', r.trigger_name);
  END LOOP;
  -- every view in this schema (PA2 had none)
  FOR r IN (SELECT view_name FROM user_views) LOOP
    drop_it('VIEW', r.view_name);
  END LOOP;
  -- helper objects students may have made (prefix h_)
  FOR r IN (SELECT object_name, object_type FROM user_objects
             WHERE object_type IN ('FUNCTION','PROCEDURE','PACKAGE','TYPE')
               AND object_name LIKE 'H\_%' ESCAPE '\') LOOP
    drop_it(r.object_type, r.object_name);
  END LOOP;
  drop_it('PACKAGE',  'pkg_audit');
  drop_it('TABLE',    'AuditLog');
  drop_it('SEQUENCE', 'seq_AuditLog');
END;
/
PROMPT PA3 objects removed. Run @setup_pa3 to start again.
SET FEEDBACK ON
