# Team reads with Firebase SQL Connect

This directory has its own Firebase configuration, separate from Hosting.

- `schema/schema.gql` maps the existing `teams` and `team_members` tables.
- `teams/queries.gql` defines `GetMyTeams`. It requires a non-anonymous Firebase
  user and filters membership by `auth.uid`. There are no client mutations.
- Text IDs, JSON-encoded `installation_ids`, Unix-second timestamps (`bigint`),
  and membership IDs (`bigserial`) retain their existing storage types.
- Explicit `limit: null` preserves the existing API's full team/member lists.

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
