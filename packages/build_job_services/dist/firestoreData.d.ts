export declare const BuildJobStatus: {
    readonly WAITING: "WAITING";
    readonly QUEUED: "QUEUED";
    readonly IN_PROGRESS: "IN_PROGRESS";
    readonly SUCCESS: "SUCCESS";
    readonly FAILURE: "FAILURE";
    readonly CANCELLED: "CANCELLED";
    readonly SKIPPED: "SKIPPED";
    readonly TIMED_OUT: "TIMED_OUT";
};
export type BuildJobStatus = (typeof BuildJobStatus)[keyof typeof BuildJobStatus];
export declare const InvitationStatus: {
    readonly PENDING: "PENDING";
    readonly ACCEPTED: "ACCEPTED";
    readonly EXPIRED: "EXPIRED";
};
export type InvitationStatus = (typeof InvitationStatus)[keyof typeof InvitationStatus];
export declare const connectorConfig: {
    connector: string;
    serviceId: string;
    location: string;
};
declare function getTeamById(...args: any[]): Promise<{
    data: {
        team: any;
    };
}>;
declare function getTeamForMember(...args: any[]): Promise<{
    data: {
        team: any;
    };
}>;
declare function findTeamByInstallation(...args: any[]): Promise<{
    data: {
        teams: any;
    };
}>;
declare function linkGitHubInstallation(...args: any[]): Promise<{
    data: {
        team_update: {
            id: any;
        };
    };
}>;
declare function listTeamMembers(...args: any[]): Promise<{
    data: {
        teamMembers: any;
    };
}>;
declare function addTeamMember(...args: any[]): Promise<{
    data: {
        user_upsert: {
            id: any;
        };
        teamMember_upsert: {
            teamId: any;
            userId: any;
        };
    };
}>;
declare function createInvitation(...args: any[]): Promise<{
    data: {
        invitation_insert: {
            id: any;
        };
    };
}>;
declare function reinviteInvitation(...args: any[]): Promise<{
    data: {
        invitation_update: {
            id: any;
        };
    };
}>;
declare function findExistingPendingInvitation(...args: any[]): Promise<{
    data: {
        invitations: any;
    };
}>;
declare function getInvitationByToken(...args: any[]): Promise<{
    data: {
        invitations: any[];
    };
}>;
declare function listMyPendingInvitations(...args: any[]): Promise<{
    data: {
        invitations: any[];
    };
}>;
declare function expireInvitation(...args: any[]): Promise<{
    data: {
        invitation_update: {
            id: any;
        };
    };
}>;
declare function acceptInvitationAndJoinTeam(...args: any[]): Promise<{
    data: {
        user_upsert: {
            id: any;
        };
        invitation_update: {
            id: any;
        };
        teamMember_upsert: {
            teamId: any;
            userId: any;
        };
    };
}>;
declare function listWorkflowFilesForBranch(...args: any[]): Promise<{
    data: {
        workflowFiles: any;
    };
}>;
declare function getWorkflowFile(...args: any[]): Promise<{
    data: {
        workflowFile: any;
    };
}>;
declare function upsertWorkflowFile(...args: any[]): Promise<{
    data: {
        workflowFile_upsert: {
            id: any;
        };
    };
}>;
declare function deleteWorkflowFile(...args: any[]): Promise<{
    data: {
        workflowFile_delete: {
            id: any;
        };
    };
}>;
declare function createBuildJob(...args: any[]): Promise<{
    data: {
        buildJob_insert: {
            id: any;
        };
    };
}>;
declare function getBuildJob(...args: any[]): Promise<{
    data: {
        buildJob: any;
    };
}>;
declare function updateBuildJobStatus(...args: any[]): Promise<{
    data: {
        buildJob_update: {
            id: any;
        };
    };
}>;
declare function listBuildJobsByWorkflowRun(...args: any[]): Promise<{
    data: {
        buildJobs: any;
    };
}>;
declare function listWaitingBuildJobs(...args: any[]): Promise<{
    data: {
        buildJobs: any;
    };
}>;
declare function claimQueuedBuildJob(...args: any[]): Promise<{
    data: {
        job: any;
    };
}>;
declare function createBuildRunForWorker(...args: any[]): Promise<{
    data: {
        buildRun_upsert: {
            buildJobId: any;
            id: any;
        };
        buildJob_update: {
            id: any;
        };
    };
}>;
declare function appendBuildLogForWorker(...args: any[]): Promise<{
    data: {
        buildLog_upsert: {
            buildRunBuildJobId: any;
            buildRunId: any;
            id: any;
        };
    };
}>;
declare function updateBuildRunStatusForWorker(...args: any[]): Promise<{
    data: {
        buildRun_update: {
            buildJobId: any;
            id: any;
        };
    };
}>;
declare function completeBuildJobForWorker(...args: any[]): Promise<{
    data: {
        buildJob_update: {
            id: any;
        };
    };
}>;
declare function upsertWorkerHeartbeat(...args: any[]): Promise<{
    data: {
        workerHeartbeat_upsert: {
            id: any;
        };
    };
}>;
declare function listLatestBuildLogs(...args: any[]): Promise<{
    data: {
        buildLogs: any;
    };
}>;
declare function listTeamNotificationUsers(...args: any[]): Promise<{
    data: {
        teamMembers: any;
    };
}>;
declare function updateUserFcmTokens(...args: any[]): Promise<{
    data: {
        user_update: {
            id: any;
        };
    };
}>;
declare function updateBuildJobFailureSummary(...args: any[]): Promise<{
    data: {
        buildJob_update: {
            id: any;
        };
    };
}>;
declare function findSecretByNameForTeam(...args: any[]): Promise<{
    data: {
        secrets: any;
    };
}>;
declare function getSecretsByNamesForTeam(...args: any[]): Promise<{
    data: {
        secrets: any;
    };
}>;
declare function listWorkerSecrets(...args: any[]): Promise<{
    data: {
        secrets: any;
    };
}>;
declare function createSecretMetadata(...args: any[]): Promise<{
    data: {
        secret_insert: {
            id: any;
        };
    };
}>;
declare function getSecretPathForTeam(...args: any[]): Promise<{
    data: {
        secret: any;
    };
}>;
declare function updateSecretMetadata(...args: any[]): Promise<{
    data: {
        secret_update: {
            id: any;
        };
    };
}>;
declare function deleteSecretMetadata(...args: any[]): Promise<{
    data: {
        secret_delete: {
            id: any;
        };
    };
}>;
declare function listWorkflowsForTeam(...args: any[]): Promise<{
    data: {
        workflows: any;
    };
}>;
declare function updateWorkflowSecretKeys(...args: any[]): Promise<{
    data: {
        workflow_update: {
            id: any;
        };
    };
}>;
declare function listWorkerEnvironmentVariables(...args: any[]): Promise<{
    data: {
        environmentVariables: any;
    };
}>;
declare function updateEnvironmentVariableValueForWorker(...args: any[]): Promise<{
    data: {
        environmentVariable_update: {
            id: any;
        };
    };
}>;
export { acceptInvitationAndJoinTeam, addTeamMember, appendBuildLogForWorker, claimQueuedBuildJob, completeBuildJobForWorker, createBuildJob, createBuildRunForWorker, createInvitation, createSecretMetadata, deleteSecretMetadata, deleteWorkflowFile, expireInvitation, findExistingPendingInvitation, findSecretByNameForTeam, findTeamByInstallation, getBuildJob, getInvitationByToken, getSecretPathForTeam, getSecretsByNamesForTeam, getTeamById, getTeamForMember, getWorkflowFile, linkGitHubInstallation, listBuildJobsByWorkflowRun, listLatestBuildLogs, listMyPendingInvitations, listTeamMembers, listTeamNotificationUsers, listWaitingBuildJobs, listWorkerEnvironmentVariables, listWorkerSecrets, listWorkflowFilesForBranch, listWorkflowsForTeam, reinviteInvitation, updateBuildJobFailureSummary, updateBuildJobStatus, updateBuildRunStatusForWorker, updateEnvironmentVariableValueForWorker, updateSecretMetadata, updateUserFcmTokens, updateWorkflowSecretKeys, upsertWorkerHeartbeat, upsertWorkflowFile, };
