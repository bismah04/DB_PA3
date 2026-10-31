# CS340 PA3: SQL Views and Triggers

Student starter files for the populated PA2 Oracle database. Read `PA3_questions.md` for the requirements. The assignment manual is distributed separately through the course; it is not included in this repository or starter ZIP. Consult the LMS for the deadline and marking details.

Implement the seven views in `views.sql` and ten triggers in `triggers.sql`. Both files are **unsolved scaffolding**. The initial views return no rows and the trigger bodies contain TODOs.

Open SQL*Plus or SQLcl in this directory and connect using your existing course account, entering the password at the prompt. Use a fresh development session and the schema that already contains the PA2 tables and seed data. Do not rerun PA2 functions or execute `schema_reference.sql` over an existing database; that file is for reference.

```sql
@setup_pa3.sql
@views.sql
@triggers.sql
@check_pa3_objects.sql
@test_pa3_sample.sql
```

After editing, compile views before triggers. Replacing `vw_CustomerBills` removes its INSTEAD OF trigger, so rerun `triggers.sql` after replacing views.

`check_pa3_objects.sql` checks structure and compilation. It can pass on the untouched scaffolding. The ten behavioral examples in `test_pa3_sample.sql` are expected to fail until you implement the assignment. A successful run ends with `PASS|PUBLIC_SUMMARY|10 passed`; passing these examples does not establish full correctness. Add tests for the other specified cases. The examples assume the original PA2 lookup rows, including payment methods 1 and 4 and tax authority FBR.

Public test cases use savepoints, roll back their fixture changes on success or failure, and restore the audit reason. Audit sequence gaps after rollback are normal. Setup, compilation and optional cleanup contain DDL and can commit pending work; run them outside test transactions. Setup preserves compatible audit history. `cleanup_pa3.sql` removes only the named PA3 views and triggers, preserving PA2 data and audit infrastructure.

Submit only your completed `s<roll_number>_views.sql` and `s<roll_number>_triggers.sql`, with the required identification and explanation comments. Keep credentials, setup, cleanup, schema definitions and tests out of the submitted files.
