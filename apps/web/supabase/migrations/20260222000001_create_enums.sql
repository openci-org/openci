-- Enum types for OpenCI

CREATE TYPE org_role AS ENUM ('owner', 'admin', 'member');
CREATE TYPE project_role AS ENUM ('admin', 'write', 'read');
CREATE TYPE invitation_status AS ENUM ('pending', 'accepted', 'expired', 'cancelled');
CREATE TYPE build_status AS ENUM ('queued', 'in_progress', 'success', 'failure', 'cancelled');
CREATE TYPE log_level AS ENUM ('info', 'warning', 'error');
CREATE TYPE trigger_type AS ENUM ('push', 'pull_request', 'tag', 'release');
