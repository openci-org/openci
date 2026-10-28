# Firebase SQL Connect schemas

This directory has its own Firebase configuration, separate from Hosting.

- `schema/schema.gql` maps the existing `teams` and `team_members` tables.
- `teams/queries.gql` defines `GetMyTeams`. It requires a non-anonymous Firebase
  user and filters membership by `auth.uid`. There are no client mutations.
- Text IDs, JSON-encoded `installation_ids`, Unix-second timestamps (`bigint`),
  and membership IDs (`bigserial`) retain their existing storage types.
- Explicit `limit: null` preserves the existing API's full team/member lists.

## Retired features

`invitations`, `user_devices`, and `udid_requests` are retired from the migration
scope. Their schemas, connector operations, and data will not be migrated to SQL
Connect. Cleanup of the existing server APIs, shared models, and legacy database
tables is tracked in [G-1569](https://linear.app/genuineci/issue/G-1569/retire-legacy-invitation-device-and-udid-request-storage)
and has not been implemented yet.

## Billing

`schema/billing.gql` maps `billing_accounts` and `billing_periods`, preserving
text IDs, Unix-second timestamps, and nullable bigint allowances. The unique
`(id, team_id)` index supports the existing admission/execution foreign keys.

`billing/mutations.gql` defines the server-only `CreateBillingPeriod` operation
(`@auth(level: NO_ACCESS)`). Its five `@check` directives validate the plan,
period type, time range, non-negative allowance, and required paid allowance.
`Int64` values are converted to integers in CEL before numeric comparisons.
The billing account is created if missing, and the period is inserted in the
same `@transaction`. Duplicate period IDs fail without overwriting the existing
period or leaving a newly created account behind.

`BillingPeriod.billingAccount` defines the foreign key using `@ref`. Billing
accounts have no foreign key to teams, so team deletion retains billing history.
No update or delete operation is exposed. Do not physically delete billing
accounts: the required `@ref` would cascade-delete their periods.

No supplemental SQL migration is required. These validations apply to this
connector operation, not direct SQL or ad hoc administrative mutations. Future
write operations must carry the same checks. The existing servers still use
their current database; routing billing writes through this operation is
follow-up work.

## Secrets

`schema/secret.gql` defines `secret_references`: team, name, timestamps, and
`secretVersionPath` (`projects/{project}/secrets/{secret}/versions/{number}`).
The value belongs in Secret Manager. Numeric versions let the server publish a
new value by updating the reference after the version has been created.

Only the server will write these references and access values after checking
team/build permissions. No connector operations expose this table yet.
The existing encrypted `secrets` table remains separate; switching the server,
copying existing values, and cleaning up Secret Manager versions on update or
team/secret deletion are follow-up work.

## Local validation

Use Firebase CLI 15.25.0. From the repository root:

```sh
cd firebase/dataconnect
firebase emulators:exec --only dataconnect --project demo-openci 'true'
```

The emulator uses ports `9399` (Data Connect) and `9939` (PostgreSQL).
Use `--project demo-openci` for local validation to override the cloud default.

## Provisioned service

The default project is `openci-b1b91`, with service `openci-b1b91-service` in
`asia-northeast1`. Its Cloud SQL instance is `openci-b1b91-instance` and database
is `openci-b1b91-database`.

`COMPATIBLE` allows unrelated tables but can still alter mapped tables. Review
`firebase dataconnect:sql:diff --project openci-b1b91` before deployment.

Dashboard still uses the existing server. The provisioned service contains an
older server's team-data snapshot; current production data has not been migrated
or synchronized to it.
