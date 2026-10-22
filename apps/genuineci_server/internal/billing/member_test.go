package billing

import (
	"errors"
	"testing"

	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestAuthorizeBillingMember(t *testing.T) {
	for _, userID := range []string{"user-1", "user-2", "outsider", ""} {
		t.Run("user="+userID, func(t *testing.T) {
			ctx, pool := testutil.NewBillingMemberDB(t)
			testutil.ExecSQL(t, ctx, pool, "DELETE FROM billing_accounts WHERE team_id = 'team-1'")
			err := authorizeBillingMember(ctx, pool, billingMember{TeamID: "team-1", UserID: userID})
			allowed := userID == "user-1" || userID == "user-2"
			if allowed && err != nil || !allowed && !errors.Is(err, errBillingForbidden) {
				t.Fatalf("only current members may initialize billing: %v", err)
			}
			var count int
			if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_accounts WHERE team_id = 'team-1'").Scan(&count); err != nil {
				t.Fatal(err)
			}
			if allowed && count != 1 || !allowed && count != 0 {
				t.Fatal("rejected authorization must not leave a billing account")
			}
		})
	}
}

func TestAuthorizeBillingMemberAfterLockWait(t *testing.T) {
	for _, deletion := range []string{
		"DELETE FROM team_members WHERE team_id = 'team-1' AND user_id = 'user-1'",
		"DELETE FROM teams WHERE id = 'team-1'",
	} {
		t.Run(deletion, func(t *testing.T) {
			ctx, pool := testutil.NewBillingMemberDB(t)
			blocker, err := pool.Begin(ctx)
			if err != nil {
				t.Fatal(err)
			}
			defer blocker.Rollback(ctx)
			if _, err := blocker.Exec(ctx, "SELECT id FROM teams WHERE id = 'team-1' FOR UPDATE"); err != nil {
				t.Fatal(err)
			}
			result := make(chan error, 1)
			go func() { result <- authorizeBillingMember(ctx, pool, billingMember{TeamID: "team-1", UserID: "user-1"}) }()
			testutil.WaitForLocks(t, ctx, pool, 1)
			if _, err := blocker.Exec(ctx, deletion); err != nil {
				t.Fatal(err)
			}
			if err := blocker.Commit(ctx); err != nil {
				t.Fatal(err)
			}
			if err := <-result; !errors.Is(err, errBillingForbidden) {
				t.Fatalf("membership and team existence must be checked after waiting: %v", err)
			}
		})
	}
}

func TestAuthorizeBillingMemberWithoutIdentity(t *testing.T) {
	if err := authorizeBillingMember(t.Context(), nil, billingMember{TeamID: "team-1"}); !errors.Is(err, errBillingForbidden) {
		t.Fatal("missing verified user must be rejected before database access")
	}
}
