import type { UserInfo } from './auth';

export interface CurrentUser extends UserInfo {
  isAdmin: boolean;
}

export interface SessionInfo {
  id: string;
  ownerId: string;
  device: string;
  createdAt: string;
  expiresAt: string;
  lastSeenAt: string;
}

export interface SeanceInfo {
  id: string;
  ownerId: string;
  errors: number;
  actionsJson: string;
  actionsCount: number;
  startedAt: string;
  doneAt: string;
  durationSeconds: number;
}

export interface UserStatsSummary {
  seancesCount: number;
  totalErrors: number;
  avgSeconds: number;
  bestSeconds: number;
  lastPlayedAt: string;
}

export interface UserStatsResponse {
  user: CurrentUser;
  summary: UserStatsSummary;
  seances: SeanceInfo[];
  sessions: SessionInfo[];
}

export interface GraphPoint {
  at: string;
  count: number;
}

export interface AdminOverview {
  seanceCount: number;
  errorsCount: number;
  avgSeconds: number;
  latest: SeanceInfo[];
}

export interface OrgUserInfo extends UserInfo {}

export interface AdminStatsResponse {
  user: CurrentUser;
  overview: AdminOverview;
  graph: {
    errors: GraphPoint[];
    usersActivity: GraphPoint[];
  };
  users: OrgUserInfo[];
}
