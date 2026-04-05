import {
  type ChannelCredentials,
  type ClientUnaryCall,
  credentials,
  type GrpcObject,
  loadPackageDefinition,
  Metadata,
  type ServiceError,
  status,
} from '@grpc/grpc-js';
import protoLoader from '@grpc/proto-loader';
import googleProtoFiles from 'google-proto-files';
import path from 'node:path';

import type { CurrentUser, OrgUserInfo, SeanceInfo, SessionInfo } from '../../contracts/app';
import type { LoginRequest, RegisterRequest, UserInfo } from '../../contracts/auth';

const SESSION_METADATA_KEY = 'aesterial_firestep_session';
const SESSION_METADATA_PREFIX = 'FS-';
const DEVICE_METADATA_KEY = 'device';
const DEVICE_TYPE = 'web';
export const SESSION_COOKIE_NAME = 'firestep_session';

interface ProtoTimestamp {
  seconds?: string | number;
  nanos?: number;
}

interface ProtoUser {
  id?: string;
  username?: string;
  initials?: string;
  email?: string;
  org?: string;
  joined?: ProtoTimestamp | null;
}

interface ProtoUsers {
  list?: ProtoUser[];
}

interface ProtoSession {
  id?: string;
  ownerId?: string;
  device?: string;
  createdAt?: ProtoTimestamp | null;
  expiresAt?: ProtoTimestamp | null;
  lastSeenAt?: ProtoTimestamp | null;
}

interface ProtoSessions {
  list?: ProtoSession[];
}

interface ProtoSeance {
  id?: string;
  ownerId?: string;
  errors?: number;
  actionsJson?: string;
  at?: ProtoTimestamp | null;
  done?: ProtoTimestamp | null;
}

interface ProtoSeances {
  list?: ProtoSeance[];
}

interface ProtoStats {
  seanceCount?: number;
  errorsCount?: number;
  avgSeconds?: number;
  latest?: ProtoSeance[];
}

interface ProtoGraphPoint {
  at?: ProtoTimestamp | null;
  count?: number;
}

interface ProtoGraphStats {
  errors?: ProtoGraphPoint[];
  usersActivity?: ProtoGraphPoint[];
}

interface UnaryCallback<TResponse> {
  (error: ServiceError | null, response: TResponse): void;
}

interface LoginServiceClient {
  Register(
    request: RegisterRequest,
    metadata: Metadata,
    callback: UnaryCallback<ProtoUser>,
  ): ClientUnaryCall;
  Login(
    request: LoginRequest,
    metadata: Metadata,
    callback: UnaryCallback<ProtoUser>,
  ): ClientUnaryCall;
  Logout(
    request: Record<string, never>,
    metadata: Metadata,
    callback: UnaryCallback<Record<string, never>>,
  ): ClientUnaryCall;
}

interface UserServiceClient {
  Info(
    request: Record<string, never>,
    metadata: Metadata,
    callback: UnaryCallback<ProtoUser>,
  ): ClientUnaryCall;
  List(
    request: Record<string, never>,
    metadata: Metadata,
    callback: UnaryCallback<ProtoUsers>,
  ): ClientUnaryCall;
}

interface StatsServiceClient {
  TitleStats(
    request: Record<string, never>,
    metadata: Metadata,
    callback: UnaryCallback<ProtoStats>,
  ): ClientUnaryCall;
  GraphStats(
    request: Record<string, never>,
    metadata: Metadata,
    callback: UnaryCallback<ProtoGraphStats>,
  ): ClientUnaryCall;
}

interface SessionsServiceClient {
  List(
    request: Record<string, never>,
    metadata: Metadata,
    callback: UnaryCallback<ProtoSessions>,
  ): ClientUnaryCall;
}

interface SeancesServiceClient {
  List(
    request: Record<string, never>,
    metadata: Metadata,
    callback: UnaryCallback<ProtoSeances>,
  ): ClientUnaryCall;
}

interface LoginPackage {
  LoginService: {
    new (address: string, grpcCredentials: ChannelCredentials): LoginServiceClient;
  };
}

interface UserPackage {
  UserService: {
    new (address: string, grpcCredentials: ChannelCredentials): UserServiceClient;
  };
}

interface StatsPackage {
  StatsService: {
    new (address: string, grpcCredentials: ChannelCredentials): StatsServiceClient;
  };
}

interface SessionsPackage {
  SessionsService: {
    new (
      address: string,
      grpcCredentials: ChannelCredentials,
    ): SessionsServiceClient;
  };
}

interface SeancesPackage {
  SeancesService: {
    new (
      address: string,
      grpcCredentials: ChannelCredentials,
    ): SeancesServiceClient;
  };
}

export class GrpcBackendError extends Error {
  statusCode: number;

  constructor(message: string, statusCode: number) {
    super(message);
    this.name = 'GrpcBackendError';
    this.statusCode = statusCode;
  }
}

let loginClient: LoginServiceClient | null = null;
let userClient: UserServiceClient | null = null;
let statsClient: StatsServiceClient | null = null;
let sessionsClient: SessionsServiceClient | null = null;
let seancesClient: SeancesServiceClient | null = null;

function getBackendAddress() {
  return process.env.FIRESTEP_GRPC_ADDR ?? '127.0.0.1:8080';
}

function loadServicePackage<TPackage>(
  protoRelativePath: string,
  packageName: string,
): TPackage {
  const apiRoot = path.join(process.cwd(), '..', 'api');
  const definition = protoLoader.loadSync(path.join(apiRoot, protoRelativePath), {
    keepCase: false,
    longs: String,
    enums: String,
    defaults: true,
    oneofs: true,
    includeDirs: [apiRoot, googleProtoFiles.getProtoPath()],
  });

  const grpcObject = loadPackageDefinition(definition) as GrpcObject;

  return ((((grpcObject.xyz as GrpcObject).fire_step as GrpcObject).v1 as GrpcObject)[
    packageName
  ] ?? {}) as unknown as TPackage;
}

function getLoginClient() {
  if (!loginClient) {
    const servicePackage = loadServicePackage<LoginPackage>(
      'xyz/fire-step/v1/login/service.proto',
      'login',
    );
    loginClient = new servicePackage.LoginService(
      getBackendAddress(),
      credentials.createInsecure(),
    );
  }

  return loginClient;
}

function getUserClient() {
  if (!userClient) {
    const servicePackage = loadServicePackage<UserPackage>(
      'xyz/fire-step/v1/user/service.proto',
      'user',
    );
    userClient = new servicePackage.UserService(
      getBackendAddress(),
      credentials.createInsecure(),
    );
  }

  return userClient;
}

function getStatsClient() {
  if (!statsClient) {
    const servicePackage = loadServicePackage<StatsPackage>(
      'xyz/fire-step/v1/stats/service.proto',
      'stats',
    );
    statsClient = new servicePackage.StatsService(
      getBackendAddress(),
      credentials.createInsecure(),
    );
  }

  return statsClient;
}

function getSessionsClient() {
  if (!sessionsClient) {
    const servicePackage = loadServicePackage<SessionsPackage>(
      'xyz/fire-step/v1/session/service.proto',
      'session',
    );
    sessionsClient = new servicePackage.SessionsService(
      getBackendAddress(),
      credentials.createInsecure(),
    );
  }

  return sessionsClient;
}

function getSeancesClient() {
  if (!seancesClient) {
    const servicePackage = loadServicePackage<SeancesPackage>(
      'xyz/fire-step/v1/seances/service.proto',
      'seances',
    );
    seancesClient = new servicePackage.SeancesService(
      getBackendAddress(),
      credentials.createInsecure(),
    );
  }

  return seancesClient;
}

function createPublicMetadata() {
  const metadata = new Metadata();
  metadata.set(DEVICE_METADATA_KEY, DEVICE_TYPE);
  return metadata;
}

function createAuthorizedMetadata(sessionId: string) {
  const metadata = createPublicMetadata();
  metadata.set(
    SESSION_METADATA_KEY,
    sessionId.startsWith(SESSION_METADATA_PREFIX)
      ? sessionId
      : `${SESSION_METADATA_PREFIX}${sessionId}`,
  );
  return metadata;
}

function mapGrpcStatusToHttp(statusCode?: number) {
  switch (statusCode) {
    case status.INVALID_ARGUMENT:
      return 400;
    case status.UNAUTHENTICATED:
      return 401;
    case status.PERMISSION_DENIED:
      return 403;
    case status.NOT_FOUND:
      return 404;
    case status.ALREADY_EXISTS:
      return 409;
    case status.UNAVAILABLE:
      return 503;
    default:
      return 500;
  }
}

function mapGrpcMessage(message: string, statusCode?: number) {
  switch (statusCode) {
    case status.UNAUTHENTICATED:
      return 'Требуется авторизация.';
    case status.PERMISSION_DENIED:
      return 'Недостаточно прав для этого действия.';
    case status.ALREADY_EXISTS:
      return 'Такой username или email уже используется.';
    case status.INVALID_ARGUMENT:
      return 'Проверьте обязательные поля формы.';
    case status.UNAVAILABLE:
      return 'gRPC backend недоступен. Проверьте, что Go сервер запущен.';
    default:
      return message || 'Не удалось выполнить запрос к backend.';
  }
}

function normalizeError(error: ServiceError | null) {
  if (!error) {
    return null;
  }

  return new GrpcBackendError(
    mapGrpcMessage(error.message, error.code),
    mapGrpcStatusToHttp(error.code),
  );
}

function timestampToIso(timestamp?: ProtoTimestamp | null) {
  if (!timestamp || timestamp.seconds === undefined || timestamp.seconds === null) {
    return '';
  }

  const secondsValue =
    typeof timestamp.seconds === 'string'
      ? Number(timestamp.seconds)
      : timestamp.seconds;

  if (!Number.isFinite(secondsValue) || secondsValue <= 0) {
    return '';
  }

  return new Date(
    secondsValue * 1000 + Math.round((timestamp.nanos ?? 0) / 1_000_000),
  ).toISOString();
}

function mapUser(user: ProtoUser): UserInfo {
  return {
    id: user.id ?? '',
    username: user.username ?? '',
    initials: user.initials ?? '',
    email: user.email ?? '',
    org: user.org ?? '',
    joined: timestampToIso(user.joined),
  };
}

function parseActionsCount(actionsJson?: string) {
  if (!actionsJson) {
    return 0;
  }

  try {
    const parsed = JSON.parse(actionsJson) as unknown;

    return Array.isArray(parsed) ? parsed.length : 0;
  } catch {
    return 0;
  }
}

function diffSeconds(startedAt: string, doneAt: string) {
  if (!startedAt || !doneAt) {
    return 0;
  }

  const diff = Math.round((Date.parse(doneAt) - Date.parse(startedAt)) / 1000);
  return Number.isFinite(diff) && diff > 0 ? diff : 0;
}

function mapSeance(seance: ProtoSeance): SeanceInfo {
  const startedAt = timestampToIso(seance.at);
  const doneAt = timestampToIso(seance.done);

  return {
    id: seance.id ?? '',
    ownerId: seance.ownerId ?? '',
    errors: seance.errors ?? 0,
    actionsJson: seance.actionsJson ?? '',
    actionsCount: parseActionsCount(seance.actionsJson),
    startedAt,
    doneAt,
    durationSeconds: diffSeconds(startedAt, doneAt),
  };
}

function mapSession(session: ProtoSession): SessionInfo {
  return {
    id: session.id ?? '',
    ownerId: session.ownerId ?? '',
    device: String(session.device ?? ''),
    createdAt: timestampToIso(session.createdAt),
    expiresAt: timestampToIso(session.expiresAt),
    lastSeenAt: timestampToIso(session.lastSeenAt),
  };
}

function extractSessionId(metadata: Metadata) {
  const rawValue = metadata.get(SESSION_METADATA_KEY)[0];

  if (typeof rawValue !== 'string') {
    return '';
  }

  return rawValue.startsWith(SESSION_METADATA_PREFIX)
    ? rawValue.slice(SESSION_METADATA_PREFIX.length)
    : rawValue;
}

function invokeUnary<TRequest, TResponse>(
  runner: (
    request: TRequest,
    metadata: Metadata,
    callback: UnaryCallback<TResponse>,
  ) => ClientUnaryCall,
  request: TRequest,
  metadata: Metadata,
) {
  return new Promise<{ response: TResponse; metadata: Metadata }>(
    (resolve, reject) => {
      let responseMetadata = new Metadata();

      const call = runner(
        request,
        metadata,
        (error: ServiceError | null, response: TResponse) => {
          const normalizedError = normalizeError(error);

          if (normalizedError) {
            reject(normalizedError);
            return;
          }

          resolve({ response, metadata: responseMetadata });
        },
      );

      call.on('metadata', (nextMetadata) => {
        responseMetadata = nextMetadata;
      });
    },
  );
}

export async function loginWithBackend(request: LoginRequest) {
  const result = await invokeUnary(
    getLoginClient().Login.bind(getLoginClient()),
    request,
    createPublicMetadata(),
  );

  return {
    user: mapUser(result.response),
    sessionId: extractSessionId(result.metadata),
  };
}

export async function registerWithBackend(request: RegisterRequest) {
  const result = await invokeUnary(
    getLoginClient().Register.bind(getLoginClient()),
    request,
    createPublicMetadata(),
  );

  return {
    user: mapUser(result.response),
    sessionId: extractSessionId(result.metadata),
  };
}

export async function logoutWithBackend(sessionId: string) {
  await invokeUnary(
    getLoginClient().Logout.bind(getLoginClient()),
    {},
    createAuthorizedMetadata(sessionId),
  );
}

export async function getUserInfoBySession(sessionId: string) {
  const result = await invokeUnary(
    getUserClient().Info.bind(getUserClient()),
    {},
    createAuthorizedMetadata(sessionId),
  );

  return mapUser(result.response);
}

export async function listUsersBySession(sessionId: string) {
  const result = await invokeUnary(
    getUserClient().List.bind(getUserClient()),
    {},
    createAuthorizedMetadata(sessionId),
  );

  return (result.response.list ?? []).map((user) => mapUser(user)) as OrgUserInfo[];
}

export async function detectAdminBySession(sessionId: string) {
  try {
    await listUsersBySession(sessionId);
    return true;
  } catch (error) {
    if (error instanceof GrpcBackendError && error.statusCode === 403) {
      return false;
    }

    throw error;
  }
}

export async function getCurrentUserBySession(sessionId: string) {
  const [user, isAdmin] = await Promise.all([
    getUserInfoBySession(sessionId),
    detectAdminBySession(sessionId),
  ]);

  return {
    ...user,
    isAdmin,
  } satisfies CurrentUser;
}

export async function listSessionsBySession(sessionId: string) {
  const result = await invokeUnary(
    getSessionsClient().List.bind(getSessionsClient()),
    {},
    createAuthorizedMetadata(sessionId),
  );

  return (result.response.list ?? [])
    .map((session) => mapSession(session))
    .sort((left, right) => right.lastSeenAt.localeCompare(left.lastSeenAt));
}

export async function listSeancesBySession(sessionId: string) {
  const result = await invokeUnary(
    getSeancesClient().List.bind(getSeancesClient()),
    {},
    createAuthorizedMetadata(sessionId),
  );

  return (result.response.list ?? [])
    .map((seance) => mapSeance(seance))
    .sort((left, right) => right.doneAt.localeCompare(left.doneAt));
}

export async function getAdminOverviewBySession(sessionId: string) {
  const result = await invokeUnary(
    getStatsClient().TitleStats.bind(getStatsClient()),
    {},
    createAuthorizedMetadata(sessionId),
  );

  return {
    seanceCount: result.response.seanceCount ?? 0,
    errorsCount: result.response.errorsCount ?? 0,
    avgSeconds: result.response.avgSeconds ?? 0,
    latest: (result.response.latest ?? []).map((seance) => mapSeance(seance)),
  };
}

export async function getAdminGraphBySession(sessionId: string) {
  const result = await invokeUnary(
    getStatsClient().GraphStats.bind(getStatsClient()),
    {},
    createAuthorizedMetadata(sessionId),
  );

  return {
    errors: (result.response.errors ?? []).map((point) => ({
      at: timestampToIso(point.at),
      count: point.count ?? 0,
    })),
    usersActivity: (result.response.usersActivity ?? []).map((point) => ({
      at: timestampToIso(point.at),
      count: point.count ?? 0,
    })),
  };
}
