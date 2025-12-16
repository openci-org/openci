import type { WorkflowJobQueuedEvent } from "@octokit/webhooks-types";

export const mockGithubPayload: WorkflowJobQueuedEvent = {
	action: "queued",
	installation: {
		id: 12345,
		node_id: "MDIzOkludGVncmF0aW9uMTIzNDU=",
	},
	organization: {
		avatar_url: "https://avatars.githubusercontent.com/u/1?v=4",
		description: "Test organization",
		events_url: "https://api.github.com/orgs/test-org/events",
		hooks_url: "https://api.github.com/orgs/test-org/hooks",
		id: 1,
		issues_url: "https://api.github.com/orgs/test-org/issues",
		login: "test-org",
		members_url: "https://api.github.com/orgs/test-org/members{/member}",
		node_id: "MDEyOk9yZ2FuaXphdGlvbjE=",
		public_members_url:
			"https://api.github.com/orgs/test-org/public_members{/member}",
		repos_url: "https://api.github.com/orgs/test-org/repos",
		url: "https://api.github.com/orgs/test-org",
	},
	repository: {
		allow_forking: true,
		archive_url:
			"https://api.github.com/repos/test-org/test-repo/{archive_format}{/ref}",
		archived: false,
		assignees_url:
			"https://api.github.com/repos/test-org/test-repo/assignees{/user}",
		blobs_url:
			"https://api.github.com/repos/test-org/test-repo/git/blobs{/sha}",
		branches_url:
			"https://api.github.com/repos/test-org/test-repo/branches{/branch}",
		clone_url: "https://github.com/test-org/test-repo.git",
		collaborators_url:
			"https://api.github.com/repos/test-org/test-repo/collaborators{/collaborator}",
		comments_url:
			"https://api.github.com/repos/test-org/test-repo/comments{/number}",
		commits_url:
			"https://api.github.com/repos/test-org/test-repo/commits{/sha}",
		compare_url:
			"https://api.github.com/repos/test-org/test-repo/compare/{base}...{head}",
		contents_url:
			"https://api.github.com/repos/test-org/test-repo/contents/{+path}",
		contributors_url:
			"https://api.github.com/repos/test-org/test-repo/contributors",
		created_at: "2021-01-01T00:00:00Z",
		custom_properties: {},
		default_branch: "main",
		deployments_url:
			"https://api.github.com/repos/test-org/test-repo/deployments",
		description: "Test repository",
		disabled: false,
		downloads_url: "https://api.github.com/repos/test-org/test-repo/downloads",
		events_url: "https://api.github.com/repos/test-org/test-repo/events",
		fork: false,
		forks: 0,
		forks_count: 0,
		forks_url: "https://api.github.com/repos/test-org/test-repo/forks",
		full_name: "test-org/test-repo",
		git_commits_url:
			"https://api.github.com/repos/test-org/test-repo/git/commits{/sha}",
		git_refs_url:
			"https://api.github.com/repos/test-org/test-repo/git/refs{/sha}",
		git_tags_url:
			"https://api.github.com/repos/test-org/test-repo/git/tags{/sha}",
		git_url: "git://github.com/test-org/test-repo.git",
		has_discussions: false,
		has_downloads: true,
		has_issues: true,
		has_pages: false,
		has_projects: true,
		has_wiki: true,
		homepage: null,
		hooks_url: "https://api.github.com/repos/test-org/test-repo/hooks",
		html_url: "https://github.com/test-org/test-repo",
		id: 1,
		is_template: false,
		issue_comment_url:
			"https://api.github.com/repos/test-org/test-repo/issues/comments{/number}",
		issue_events_url:
			"https://api.github.com/repos/test-org/test-repo/issues/events{/number}",
		issues_url:
			"https://api.github.com/repos/test-org/test-repo/issues{/number}",
		keys_url: "https://api.github.com/repos/test-org/test-repo/keys{/key_id}",
		labels_url: "https://api.github.com/repos/test-org/test-repo/labels{/name}",
		language: "TypeScript",
		languages_url: "https://api.github.com/repos/test-org/test-repo/languages",
		license: null,
		merges_url: "https://api.github.com/repos/test-org/test-repo/merges",
		milestones_url:
			"https://api.github.com/repos/test-org/test-repo/milestones{/number}",
		mirror_url: null,
		name: "test-repo",
		node_id: "MDEwOlJlcG9zaXRvcnkx",
		notifications_url:
			"https://api.github.com/repos/test-org/test-repo/notifications{?since,all,participating}",
		open_issues: 0,
		open_issues_count: 0,
		owner: {
			avatar_url: "https://avatars.githubusercontent.com/u/1?v=4",
			events_url: "https://api.github.com/users/test-org/events{/privacy}",
			followers_url: "https://api.github.com/users/test-org/followers",
			following_url:
				"https://api.github.com/users/test-org/following{/other_user}",
			gists_url: "https://api.github.com/users/test-org/gists{/gist_id}",
			gravatar_id: "",
			html_url: "https://github.com/test-org",
			id: 1,
			login: "test-org",
			node_id: "MDEyOk9yZ2FuaXphdGlvbjE=",
			organizations_url: "https://api.github.com/users/test-org/orgs",
			received_events_url:
				"https://api.github.com/users/test-org/received_events",
			repos_url: "https://api.github.com/users/test-org/repos",
			site_admin: false,
			starred_url:
				"https://api.github.com/users/test-org/starred{/owner}{/repo}",
			subscriptions_url: "https://api.github.com/users/test-org/subscriptions",
			type: "Organization",
			url: "https://api.github.com/users/test-org",
		},
		private: false,
		pulls_url: "https://api.github.com/repos/test-org/test-repo/pulls{/number}",
		pushed_at: "2021-01-01T00:00:00Z",
		releases_url:
			"https://api.github.com/repos/test-org/test-repo/releases{/id}",
		size: 0,
		ssh_url: "git@github.com:test-org/test-repo.git",
		stargazers_count: 0,
		stargazers_url:
			"https://api.github.com/repos/test-org/test-repo/stargazers",
		statuses_url:
			"https://api.github.com/repos/test-org/test-repo/statuses/{sha}",
		subscribers_url:
			"https://api.github.com/repos/test-org/test-repo/subscribers",
		subscription_url:
			"https://api.github.com/repos/test-org/test-repo/subscription",
		svn_url: "https://github.com/test-org/test-repo",
		tags_url: "https://api.github.com/repos/test-org/test-repo/tags",
		teams_url: "https://api.github.com/repos/test-org/test-repo/teams",
		topics: [],
		trees_url:
			"https://api.github.com/repos/test-org/test-repo/git/trees{/sha}",
		updated_at: "2021-01-01T00:00:00Z",
		url: "https://api.github.com/repos/test-org/test-repo",
		visibility: "public",
		watchers: 0,
		watchers_count: 0,
		web_commit_signoff_required: false,
	},
	sender: {
		avatar_url: "https://avatars.githubusercontent.com/u/1?v=4",
		events_url: "https://api.github.com/users/test-user/events{/privacy}",
		followers_url: "https://api.github.com/users/test-user/followers",
		following_url:
			"https://api.github.com/users/test-user/following{/other_user}",
		gists_url: "https://api.github.com/users/test-user/gists{/gist_id}",
		gravatar_id: "",
		html_url: "https://github.com/test-user",
		id: 1,
		login: "test-user",
		node_id: "MDQ6VXNlcjE=",
		organizations_url: "https://api.github.com/users/test-user/orgs",
		received_events_url:
			"https://api.github.com/users/test-user/received_events",
		repos_url: "https://api.github.com/users/test-user/repos",
		site_admin: false,
		starred_url:
			"https://api.github.com/users/test-user/starred{/owner}{/repo}",
		subscriptions_url: "https://api.github.com/users/test-user/subscriptions",
		type: "User",
		url: "https://api.github.com/users/test-user",
	},
	workflow_job: {
		check_run_url:
			"https://api.github.com/repos/test-org/test-repo/check-runs/1",
		completed_at: null,
		conclusion: null,
		created_at: "2021-01-01T00:00:00Z",
		head_branch: "main",
		head_sha: "abc123",
		html_url: "https://github.com/test-org/test-repo/actions/runs/1/jobs/1",
		id: 1,
		labels: ["self-hosted"],
		name: "test-job",
		node_id: "MDg6Q2hlY2tSdW4x",
		run_attempt: 1,
		run_id: 67890,
		run_url: "https://api.github.com/repos/test-org/test-repo/actions/runs/1",
		runner_group_id: null,
		runner_group_name: null,
		runner_id: null,
		runner_name: null,
		started_at: "2021-01-01T00:00:00Z",
		status: "queued",
		steps: [],
		url: "https://api.github.com/repos/test-org/test-repo/actions/jobs/1",
		workflow_name: "Test Workflow",
	},
};
