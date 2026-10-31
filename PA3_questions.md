# CS340 Programming Assignment 3: SQL Views and Triggers

Databases - Fall 2026

Student starter release. See the LMS for the deadline and marking details.

## Overview
PA2 implemented the billing logic of an Electricity Distribution Company (DISCO) as PL/SQL functions. In practice, a billing system also needs the following:

- **Controlled access to data.** Different departments (customer service, recovery, management, the regulator) need different slices of the database. Some users must not see or change data outside their remit.
- **Accountability and integrity.** Rate tables decide every customer's bill. Changes to them must be traceable, and inconsistent rate data must never enter the database, whichever application or person issues the DML.

In PA3 you will implement both requirements using **views** (Part 1) and **triggers** (Part 2). The schema is the same as PA2 (Appendix A), plus one audit table.

The authoritative table definitions are provided in `schema_reference.sql`, copied unchanged from PA2. The PA2 database schema diagram is available in the separately distributed assignment manual. AuditLog is an additional PA3 table, provided by setup_pa3.sql.


## General conventions
- Target DBMS: Oracle (SQL*Plus). Do not rely on IDENTITY columns or JSON functions.
- Object names given in this document are fixed. Do not rename them.
- When a rule is violated, the trigger must call `RAISE_APPLICATION_ERROR` with the exact error code listed. The message text is free-form.
- Every trigger must behave correctly for **multi-row** statements (`INSERT ... SELECT`, `UPDATE` touching many rows), not just single-row `INSERT ... VALUES`.
- Derived monetary values are rounded to 2 decimal places. Do not round consumption thresholds or change the audit serialization rules.
- PA3 uses the PA2 schema and seed data. Implement and test through direct SQL; PA2 function implementations are not required or graded.
- Implement seven views and ten triggers across the fourteen tasks below. Additional requirements within each task are part of the specification.

---


- Use the fixed names, column names, and column order below. Use unquoted identifiers. Do not include setup, cleanup, sample tests, credentials, or seed data in the submission.
- Use CREATE OR REPLACE for your objects. No COMMIT, ROLLBACK, autonomous transactions, schema changes, grants, or trigger disabling in solutions. Test transaction controls belong in separate test scripts. Any helper functions/procedures/packages must have prefix `h_pa3_` and be defined before use in the submitted files. Do not create helper tables, views, sequences, or types.
- For payment reporting, revenue and adjustment tests, bill totals are non-NULL. No additional validation of otherwise schema-permitted NULL bill totals is required.

## Part 1: Views
### 1.1 `vw_ConnectionDirectory`: customer service lookup
**Scenario:** A customer calls the helpline about their connection. The agent needs one screen with the owner, connection type and division of that connection. Today that means joining four tables by hand.

**Columns:**
- ConnectionID
- CustomerID
- CustomerName (`FirstName || ' ' || LastName`)
- OrgName
- ConnectionTypeCode
- TypeDescription (from `ConnectionTypes.Description`)
- DivisionName
- SubDivName
- Status

There is one row per connection, including connections with NULL ConnectionTypeCode or NULL division/subdivision foreign keys. Preserve these rows with NULL lookup descriptions. Join DivInfo on both DivisionID and SubDivID.
**Output column order:**
```text
ConnectionID,
CustomerID,
CustomerName,
OrgName,
ConnectionTypeCode,
TypeDescription,
DivisionName,
SubDivName,
Status
```

### 1.2 `vw_BillPaymentStatus`: recovery department
**Scenario:** The recovery (collections) department chases defaulters. It needs, for **every** bill (including bills with no payment yet), how much has been paid and how much is still outstanding.

**Columns:**
- BillID, ConnectionID, BillingMonth, BillingYear, DueDate
- TotalPaid = sum of `AmountPaid` over the bill's payments (0 if none)
- PaymentCount (0 if none)
- LastPaymentDate (NULL if none)
- AmountDue = `TotalAmount_BeforeDueDate` if LastPaymentDate ≤ DueDate, otherwise `TotalAmount_AfterDueDate`. An unpaid bill counts as late.
- Outstanding = `GREATEST(AmountDue − TotalPaid, 0)`
- DerivedStatus:
  - `'UNPAID'` when there are no payments
  - `'PAID'` when Outstanding = 0
  - `'PARTIAL'` otherwise

**Additional requirements:** count actual PaymentDetails rows even if AmountPaid is NULL or zero; TotalPaid is NVL(SUM(AmountPaid),0). Do not filter on PaymentStatus. LastPaymentDate is MAX(PaymentDate). Compare full Oracle DATE values to DueDate, without TRUNC or SYSDATE. An unpaid bill uses the after-due total even if its due date is in the future. Overpayments leave Outstanding at zero.

**Output column order:**
```text
BillID,
ConnectionID,
BillingMonth,
BillingYear,
DueDate,
TotalPaid,
PaymentCount,
LastPaymentDate,
AmountDue,
Outstanding,
DerivedStatus
```

### 1.3 `vw_ChargeComponents`: schedule of charges
**Scenario:** The regulator requires the DISCO to publish one consolidated "schedule of charges" per connection type. Taxes, fixed charges and subsidies are currently stored in three differently shaped tables.

**Columns:**
- ComponentType: `'TAX'`, `'FIXED'` or `'SUBSIDY'`
- ConnectionTypeCode
- ComponentName: TaxType, FixedChargeType or SubsidyCode
- AuthorityOrProvider: TaxAuthorityID or ProviderID
- StartDate
- EndDate
- Value: Rate, FixedFee or RatePerUnit

Build it with `UNION ALL` over TaxRates, FixedCharges and Subsidy.

**Additional requirements:** retain all rows with UNION ALL; preserve the numeric Value and date types. Do not multiply tax rates by 100.

**Output column order:**
```text
ComponentType,
ConnectionTypeCode,
ComponentName,
AuthorityOrProvider,
StartDate,
EndDate,
Value
```

### 1.4 `vw_TariffRateHistory`: tariff revision review
**Scenario:** When tariffs are revised, the regulator and the media ask: "By how much did the per-unit rate of each slab change?"

**Columns:** all columns of Tariff, plus:
- PrevRatePerUnit: RatePerUnit of the immediately preceding period (by StartDate) for the same (ConnectionTypeCode, TariffType, Slab). NULL if there is no earlier period.
- ChangePct = `ROUND((RatePerUnit − PrevRatePerUnit) / PrevRatePerUnit × 100, 2)`. NULL if there is no earlier period or PrevRatePerUnit is zero.

**Additional requirements:** partition by the complete three-column key. Return all 12 Tariff columns in definition order, then PrevRatePerUnit and ChangePct. A zero previous rate produces NULL ChangePct. For this view, assume distinct StartDate values within each group satisfying the validity rules. LAG or an equivalent correlated query is allowed.

All Tariff columns must follow their table-definition order; see Appendix B.

**Output column order:**
```text
TariffCode,
TariffType,
ConnectionTypeCode,
Slab,
StartDate,
EndDate,
ThresholdLow_perHour,
ThresholdHigh_perHour,
TarrifDescription,
RatePerUnit,
MinAmount,
MinUnit,
PrevRatePerUnit,
ChangePct
```

### 1.5 `vw_DivisionMonthlyRevenue`: management report
**Scenario:** Each month, management compares divisions on recovery rate: how much of what was billed was actually collected.

Build this view **on top of `vw_BillPaymentStatus`**. There is one row per (DivisionName, BillingYear, BillingMonth).

**Columns (in this order):**
- DivisionName, BillingYear, BillingMonth
- NumBills
- TotalBilled (sum of AmountDue)
- TotalCollected (sum of TotalPaid)
- CollectionRatePct = `ROUND(TotalCollected / TotalBilled × 100, 2)`

**Additional requirements:** return DivisionName, BillingYear, BillingMonth first, followed by the four listed measures. Join Connections and DivInfo without losing bills with a missing nullable division link; they form a NULL DivisionName group. Use both division keys, and count each bill once. CollectionRatePct is NULL if TotalBilled is zero; do not cap it at 100. Group by the specified DivisionName, not subdivision or DivisionID.

**Output column order:**
```text
DivisionName,
BillingYear,
BillingMonth,
NumBills,
TotalBilled,
TotalCollected,
CollectionRatePct
```

### 1.6 `vw_ResidentialConnections`: restricted clerk access
**Scenario:** A clerk at the residential connections desk may view, add and edit residential connections only (ConnectionTypeCode 1–4). The clerk must not be able to create a connection of another type or move a connection out of the residential range.

**Definition:**
- An updatable view over `Connections` with all of its columns.
- Restricted to `ConnectionTypeCode BETWEEN 1 AND 4`.
- Created `WITH CHECK OPTION`.

**Question to answer in a comment:** What happens when an INSERT or UPDATE through the view would produce a non-residential row? Why?

**Additional requirements:** expose all eight Connections columns in table order. Restriction applies to DML through the view. No user accounts or privileges need to be created.

**Output column order:**
```text
ConnectionID,
CustomerID,
DivisionID,
SubDivID,
ConnectionTypeCode,
InstallationDate,
MeterType,
Status
```

### 1.7 `vw_CustomerBills`: customer self-service portal
**Scenario:** The online portal shows a customer their bills together with their contact details. Customers may update their phone number and email from this page, but nothing else.

**Columns:**
- BillID, ConnectionID, BillingMonth, BillingYear, DueDate
- TotalAmount_BeforeDueDate, TotalAmount_AfterDueDate
- CustomerID, FirstName, LastName, PhoneNumber, Email

This view joins Bill, Connections and Customers. Oracle may permit some DML on a key-preserved table in a join view; the join alone does not enforce the portal policy. Trigger 2.7 must enforce the required contact-only write behavior.

**Additional requirements:** use inner joins Bill -> Connections -> Customers. A bill with no matching connection is absent. There is one row per matching bill; multiple bills may display the same customer's contact details. This exercise does not implement login-based row security.

**Output column order:**
```text
BillID,
ConnectionID,
BillingMonth,
BillingYear,
DueDate,
TotalAmount_BeforeDueDate,
TotalAmount_AfterDueDate,
CustomerID,
FirstName,
LastName,
PhoneNumber,
Email
```

## Part 2: Triggers
### Provided objects
```sql
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
```
An officer calls `pkg_audit.set_reason('NEPRA notification 2026-14')` before changing rates. The reason stays set for the rest of the session until it is cleared.


### 2.1 Audit triggers on rate tables
**Scenario:**
- Tariff, TaxRates, FixedCharges and Subsidy determine every customer's bill.
- A wrong rate, entered by mistake or on purpose, silently over- or under-bills thousands of customers.
- Auditors and the regulator must be able to answer: *who changed which rate, when, from what, to what, and why?*

**Triggers:** `trg_audit_Tariff`, `trg_audit_TaxRates`, `trg_audit_FixedCharges`, `trg_audit_Subsidy`. Each is an AFTER INSERT OR UPDATE OR DELETE, row-level trigger that inserts one AuditLog row per affected row.

**Field rules:**
- `id` comes from `seq_AuditLog.NEXTVAL`.
- `changed_by` = `USER`.
- `changed_at` = `SYSTIMESTAMP`.
- `change_reason` = `pkg_audit.g_change_reason`.

**Format of `old_value` and `new_value`:** all columns of the row, in table-definition order, as `Col1=val1;Col2=val2;...`
- Dates are formatted `YYYY-MM-DD`.
- NULLs are written as the literal `NULL`.
- Numbers use `TO_CHAR(x)` with no format mask.

**Edge cases:**
- An UPDATE that leaves every column unchanged must **not** produce an audit row. The comparison must be null-safe.
- If the triggering statement fails and is rolled back, its audit rows must roll back too. Explain in a comment why this happens without any extra code.

**Additional requirements:** table_name is exactly `Tariff`, `TaxRates`, `FixedCharges`, or `Subsidy`; operation is uppercase INSERT/UPDATE/DELETE. Use exact schema column spellings, including `TarrifDescription`. Separate fields by semicolons with no trailing semicolon. An entire old_value is NULL on INSERT and an entire new_value is NULL on DELETE. Within a snapshot, a NULL field is the literal NULL. Text is copied as stored; no extra quoting or escaping is required. Compare actual typed values null-safely to detect changes, not formatted snapshots (two different date times may format to the same day). An UPDATE affecting zero rows creates no audit rows. g_change_reason is session state and does not roll back with DML; set/clear it explicitly in tests.

### 2.2 `trg_Tariff_Validity`: no ambiguous tariffs
**Scenario:**
- The bill-generation logic from PA2 picks *the* tariff in effect on the bill issue date for a given (ConnectionTypeCode, TariffType, Slab).
- Suppose a revised tariff is entered while the old one has not been end-dated. Two tariffs are then valid at the same time, and billing either fails (`TOO_MANY_ROWS`) or picks one arbitrarily.
- The same error can also come from a typo where EndDate is before StartDate.

**Rules:**
- Each row must satisfy `StartDate ≤ EndDate`. Otherwise raise error **-20010**.
- After the statement, no two Tariff rows with the same (ConnectionTypeCode, TariffType, Slab) may have overlapping `[StartDate, EndDate]` periods. Otherwise raise error **-20011**.

**Implementation requirements:**
- Implement this as a **compound trigger**.
- A plain row-level trigger that queries Tariff fails with ORA-04091 (mutating table) on multi-row statements. Explain in a comment why this happens and how the compound trigger avoids it.
- The check must cover both INSERT and UPDATE. That includes an UPDATE that shifts dates so that two existing rows start to overlap.

**Additional requirements:** date intervals are inclusive: ending on the same DATE instant another starts is overlap. StartDate=EndDate is a valid single-instant interval. Compare full DATE values. Check the statement's final state, including conflicts among rows changed by that statement, and do not compare a row with itself. A key-changing UPDATE must validate the resulting group. Fixtures initially satisfy the validity rules. Multi-session overlap races are outside the grading scope; correct single-session multi-row behavior is required.

### 2.3 `trg_TaxRates_Validity`
**Scenario:** The same reasoning as 2.2 applies to taxes. Two overlapping GST rates for the same connection type and authority would double-charge customers.

**Rules:**
- Same structure as 2.2.
- Overlaps are checked per (ConnectionTypeCode, TaxType, TaxAuthorityID).
- Error codes: **-20012** (StartDate after EndDate) and **-20013** (overlap).

**Additional requirements:** date intervals are inclusive: ending on the same DATE instant another starts is overlap. StartDate=EndDate is a valid single-instant interval. Compare full DATE values. Check the statement's final state, including conflicts among rows changed by that statement, and do not compare a row with itself. A key-changing UPDATE must validate the resulting group. Fixtures initially satisfy the validity rules. Multi-session overlap races are outside the grading scope; correct single-session multi-row behavior is required.

Use the supplied compound-trigger interface for INSERT and UPDATE on TaxRates. Each row must satisfy StartDate <= EndDate; perform overlap validation on the statement's final state.

### 2.4 `trg_PaymentDetails_Fee`: mobile-wallet convenience fee
**Scenario:**
- JazzCash charges the payer a flat **Rs. 50** convenience fee per bill payment.
- The DISCO records the total amount the customer actually paid.
- The payment entry systems only send the bill amount, so the fee must be added in the database. That way no entry path can forget it.

**Trigger type:** BEFORE INSERT OR UPDATE OF AmountPaid, PaymentMethodID on PaymentDetails, row level. JazzCash is `PaymentMethodID = 4`.

| Situation | Effect on `:NEW.AmountPaid` |
|---|---|
| INSERT, method = 4, AmountPaid not NULL | + 50 |
| INSERT, other method | unchanged |
| UPDATE that sets AmountPaid (`UPDATING('AmountPaid')`) | the new value is the base amount: + 50 if the resulting method = 4 |
| UPDATE of PaymentMethodID only, 4 → other | − 50 (refund the fee) |
| UPDATE of PaymentMethodID only, other → 4 | + 50 |
| AmountPaid is NULL | stays NULL |

The table only covers the cases above. Payments loaded before the trigger was created are not modified.

**Additional requirements:** NULL PaymentMethodID is treated as a non-JazzCash method. For method-only updates, 4->4, NULL->NULL, and non-4->non-4 leave AmountPaid unchanged. If AmountPaid and PaymentMethodID are both targeted, the AmountPaid branch takes priority. Even `SET AmountPaid=AmountPaid` supplies a new base amount, and adds 50 when the resulting method is 4. Unrelated-column updates do not add a fee. Existing payments are not rewritten on trigger creation; a later method-only update follows the table literally, including subtraction of 50 on an old method-4 row. Views sum stored AmountPaid including the fee; do not subtract fees in reports.

### 2.5 `trg_BillAdjustments_Apply`: keep bills consistent with adjustments
**Scenario:**
- When an officer approves a complaint (faulty meter, wrong reading), they insert a row into BillAdjustments.
- If the corresponding Bill is not updated at the same moment, the customer is shown and charged the wrong amount.
- A trigger guarantees consistency whichever application inserts the adjustment.

**Rules (on INSERT into BillAdjustments):**
- Before the row is stored:
  - If OriginalBillAmount is NULL, set it to the bill's current `TotalAmount_BeforeDueDate`.
  - If AdjustmentDate is NULL, set it to `TRUNC(SYSDATE)`.
- After the row is stored, update the referenced Bill as follows:
  - `AdjustmentAmount = NVL(AdjustmentAmount,0) + :NEW.AdjustmentAmount`
  - `TotalAmount_BeforeDueDate = TotalAmount_BeforeDueDate − :NEW.AdjustmentAmount`
  - `TotalAmount_AfterDueDate = ROUND(new TotalAmount_BeforeDueDate × 1.10, 2)`
- Errors:
  - The bill does not exist: **-20020**.
  - The adjustment would make `TotalAmount_BeforeDueDate` negative: **-20021**.

**Additional requirements:** NULL or missing BillID raises -20020. Preserve non-NULL OriginalBillAmount and AdjustmentDate supplied by the caller. Defaults use the current bill state immediately before that row's adjustment. Repeated adjustments accumulate; OriginalBillAmount is descriptive and does not drive the calculation. A new before-due total of exactly zero is allowed. Zero and negative AdjustmentAmount are not separately prohibited: apply the given subtraction rule. Do not add extra error codes. The task applies on INSERT only; no reversal on later UPDATE/DELETE is required. A failing multi-row INSERT must leave neither partial bill changes nor adjustment rows. Row-processing order is unspecified; tests must not assume which of several same-bill rows gets which intermediate default.

Use the supplied compound-trigger interface in triggers.sql, with BEFORE EACH ROW for defaults and validation and AFTER EACH ROW for applying the bill update.

### 2.6 `trg_Bill_Protect`: issued bills are legal records
**Scenario:**
- Once issued, a bill is a legal demand notice.
- Its identity and the consumption it is based on must never be edited in place. Corrections go through adjustments (2.5).
- A bill that has been paid against must never be deleted, or the payment records lose their meaning.

**Rules (BEFORE UPDATE OR DELETE on Bill):**
- DELETE of a bill that has at least one PaymentDetails row: **-20030**.
- UPDATE of any of the following columns: **-20031**.
  - ConnectionID, BillingMonth, BillingYear
  - Import_PeakUnits, Import_OffPeakUnits, Export_PeakUnits, Export_OffPeakUnits
  - Net_PeakUnits, Net_OffPeakUnits
- Amount columns stay updatable, so that 2.5 keeps working.

**Additional requirements:** reject an UPDATE that targets any protected column, even if the assigned value equals the old value. Use the column-targeting meaning of UPDATE here. Preserve the amount-only update path needed by 2.5. Zero-row UPDATE/DELETE does not fire this row trigger. Other foreign keys (for example BillAdjustments) can still prevent a DELETE for their ordinary Oracle constraint reasons.

Use the row-level trigger interface supplied in triggers.sql.

### 2.7 `trg_vw_CustomerBills_IO`: making the portal view writable
**Scenario:** The portal (view 1.7) must let customers update their contact details. It must reject any attempt to alter bill data through the same page.

**Trigger type:** INSTEAD OF INSERT OR UPDATE OR DELETE on `vw_CustomerBills`.

**Rules:**
- UPDATE that changes only PhoneNumber and/or Email: update the matching row in `Customers`.
- UPDATE that changes any other column: **-20040**.
- INSERT or DELETE: **-20041**.

**Additional requirements:** use NULL-safe old/new value comparisons for every non-contact column. Reject an actual non-contact value change with -20040; a same-value non-contact assignment is allowed. A mixed contact/non-contact change rejects the entire statement. Use the unchanged customer identity to update Customers. NULL contact values are allowed by the schema. Repeated portal rows for one customer must give correct results for updates assigning the same contact values; conflicting per-bill contact values in one statement are not graded. INSERT and DELETE that affect rows raise -20041. No-op updates are allowed, and zero-row DML need not raise an error.

Use the row-level trigger interface supplied in triggers.sql.

## Getting Started and Public Testing

Use the database schema and populated dataset supplied for PA2. Your PA2 function implementations and their tests are not required for PA3. If your PA2 database is already populated, do not recreate or repopulate it. If you are starting with an empty development database, prepare the PA2 schema and data separately using the original PA2 release. The schema_reference.sql file is a reference, not a migration script from PA1.

### Files provided
Extract the student starter ZIP. It contains these consolidated questions and the following SQL files. The manual is distributed separately:

| File | Purpose |
|---|---|
| `views.sql` | Unsolved definitions for the seven views. |
| `triggers.sql` | Unsolved definitions for the ten triggers. |
| `setup_pa3.sql` | Provided AuditLog, seq_AuditLog and pkg_audit infrastructure. |
| `check_pa3_objects.sql` | Required-object, column-order and compilation checks. |
| `test_pa3_sample.sql` | Public behavioral assertions and examples. |
| `cleanup_pa3.sql` | Optional cleanup of the seventeen named PA3 views/triggers. |
| `schema_reference.sql` | Unchanged PA2 table definitions, for reference. |

### Connecting using SQL*Plus
Open a terminal in the extracted student directory. Start SQL*Plus and connect using your existing course database account and service alias:

```text
sqlplus /nolog
SQL> CONNECT <user_name>@<connection_alias>
Enter password:
```

Enter the password when prompted. Do not put database passwords in your submission files. For an Oracle Cloud database, use the connection alias and wallet/network configuration already established for your course account. Select the same schema in which the PA2 data was loaded.

### Creating and compiling the assignment objects
Start with a fresh development session, before making uncommitted test changes. Run the following commands in SQL*Plus:

```sql
@setup_pa3.sql
@views.sql
@triggers.sql
@check_pa3_objects.sql
```

setup_pa3.sql checks for the PA2 schema, including FixedCharges and the additional BillAdjustments columns. If it reports a missing or incompatible object, resolve that issue before continuing. It preserves a compatible existing AuditLog and sequence when rerun; it recreates pkg_audit and resets its session state. If audit infrastructure is only partly present, setup stops for inspection rather than deleting it.

Fill in the queries in views.sql and the trigger bodies in triggers.sql. The initial views return no rows, and the trigger bodies contain TODOs. These are unsolved starter definitions. After editing, run views.sql first, then triggers.sql again. Replacing a conventional view removes its INSTEAD OF trigger, so the portal trigger must be recreated after replacing the view.

Setup and CREATE OR REPLACE statements are DDL and can commit pending work. Do not run setup, object compilation or cleanup inside a test transaction. The optional cleanup_pa3.sql drops only the seven named views and ten named triggers. It preserves the audit infrastructure/history, helper objects and PA2 tables/data. After cleanup, rebuild views.sql and then triggers.sql.

For an individual object, inspect errors explicitly, for example:

```sql
SHOW ERRORS TRIGGER trg_Tariff_Validity
SHOW ERRORS VIEW vw_BillPaymentStatus
```

The check_pa3_objects.sql script examines every required object, so do not rely only on SHOW ERRORS for the last object compiled. Structural success does not prove that the implementation is correct.

### Oracle Cloud SQL worksheet
If you use your Oracle Cloud SQL worksheet instead of a local client, open the worksheet for the existing PA2 schema and load each SQL file from the extracted package. Execute complete scripts in the order above using the worksheet's script execution mode. Keep each PL/SQL block and its terminating slash on a separate line as supplied. Run tests in the same worksheet session so that package variables and savepoints behave consistently.

Client support for SQL*Plus commands may differ. If the worksheet does not accept a client directive such as @filename, SET, WHENEVER or SHOW ERRORS, use SQL*Plus for the supplied scripts. Do not modify the submitted definitions to accommodate worksheet-only commands. The database rules and required object names are the same in either client.

### Running and interpreting the public tests
After implementing and compiling both files, run:

```sql
@test_pa3_sample.sql
```

The script emits PASS or FAIL for each of ten public sample cases. PASS|PUBLIC_SUMMARY|10 passed means the public cases completed successfully. FAIL|PUBLIC_SUMMARY reports the number of failed cases; inspect each preceding FAIL line and its error details. ORA-20990 is raised by the test script to signal failed assertions; it is not an assignment trigger error code. Other compilation or runtime errors must also be investigated. A missing summary does not establish a successful test run.

The script is expected to fail behavioral assertions on the untouched starter files. Each DML sample rolls back to its own savepoint on success or failure and restores the audit reason. Sequence values may still advance: gaps in seq_AuditLog are normal after rollback. Run these samples in a development database and write additional tests for the remaining edge cases. Public samples are examples, not an exhaustive correctness check.

## Submission Instructions

Submit exactly two SQL files containing your completed definitions:

```text
s<roll_number>_views.sql
s<roll_number>_triggers.sql
```

For example, a student with roll number 24100173 submits s24100173_views.sql and s24100173_triggers.sql. Keep the question labels in the starter files. At the top of each file, add your name, roll number and section as comments:

```sql
-- Name: <Your Name>
-- Roll Number: <Your Roll Number>
-- Section: <Your Section>
```

Keep every required object name, output column name/order, trigger interface and error code unchanged. Use unquoted identifiers. Include any permitted h_pa3_ helper function, procedure or package before its first use in the submitted files. Do not submit setup, cleanup, public tests, schema/seed files, the manual, connection details or credentials as part of your solution. Do not include client-specific commands or test transaction controls in the submission files.

Write the following explanations in SQL comments beside the corresponding definitions:

- Task 1.6: what happens when INSERT or UPDATE through the residential view would produce a non-residential row, and why.
- Task 2.1: why audit rows roll back with a failed triggering statement without extra transaction code.
- Task 2.2: why a plain row-level trigger querying Tariff can raise ORA-04091, and how a compound trigger avoids it.

Consult the LMS for the submission deadline and marking details.

## Appendix A: Database Schema

Refer to `schema_reference.sql` for the complete PA2 table definitions and to the separately distributed manual for the schema diagram. AuditLog is provided separately in Task 2.

## Appendix B: Required Table Column Order

| Table | Columns, in definition order |
|---|---|
| `Connections` | `ConnectionID`, `CustomerID`, `DivisionID`, `SubDivID`, `ConnectionTypeCode`, `InstallationDate`, `MeterType`, `Status` |
| `Tariff` | `TariffCode`, `TariffType`, `ConnectionTypeCode`, `Slab`, `StartDate`, `EndDate`, `ThresholdLow_perHour`, `ThresholdHigh_perHour`, `TarrifDescription`, `RatePerUnit`, `MinAmount`, `MinUnit` |
| `TaxRates` | `ConnectionTypeCode`, `TaxType`, `TaxAuthorityID`, `StartDate`, `EndDate`, `Rate` |
| `FixedCharges` | `ConnectionTypeCode`, `FixedChargeType`, `TaxAuthorityID`, `StartDate`, `EndDate`, `FixedFee` |
| `Subsidy` | `SubsidyCode`, `ProviderID`, `ConnectionTypeCode`, `StartDate`, `EndDate`, `ThresholdLow_perHour`, `ThresholdHigh_perHour`, `SubsidyDescription`, `RatePerUnit` |


## Appendix C: Error Code Summary
| Code | Raised by | Meaning |
|---|---|---|
| -20010 | 2.2 | Tariff StartDate > EndDate |
| -20011 | 2.2 | Overlapping tariff periods |
| -20012 | 2.3 | TaxRates StartDate > EndDate |
| -20013 | 2.3 | Overlapping tax periods |
| -20020 | 2.5 | Adjustment for non-existent bill |
| -20021 | 2.5 | Adjustment exceeds bill total |
| -20030 | 2.6 | Delete of a bill with payments |
| -20031 | 2.6 | Update of protected bill column |
| -20040 | 2.7 | Update of non-contact column via portal view |
| -20041 | 2.7 | Insert/Delete via portal view |
