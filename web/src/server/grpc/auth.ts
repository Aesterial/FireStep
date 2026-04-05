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

import type {
  LoginRequest,
  RegisterRequest,
  UserInfo,
} from '../../contracts/auth';

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

interface LoginPackage {
  LoginService: {
    new (
      address: string,
      grpcCredentials: ChannelCredentials,
    ): LoginServiceClient;
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

function getBackendAddress() {
  return process.env.FIRESTEP_GRPC_ADDR ?? '127.0.0.1:50051';
}

function getLoginClient() {
  if (loginClient) {
    return loginClient;
  }

  const apiRoot = path.join(process.cwd(), '..', 'api');
  const definition = protoLoader.loadSync(
    path.join(apiRoot, 'xyz/fire-step/v1/login/service.proto'),
    {
      keepCase: false,
      longs: String,
      enums: String,
      defaults: true,
      oneofs: true,
      includeDirs: [apiRoot, googleProtoFiles.getProtoPath()],
    },
  );

  const grpcObject = loadPackageDefinition(definition) as GrpcObject;
  const loginPackage = ((((grpcObject.xyz as GrpcObject).fire_step as GrpcObject)
    .v1 as GrpcObject).login ?? {}) as unknown as LoginPackage;

  loginClient = new loginPackage.LoginService(
    getBackendAddress(),
    credentials.createInsecure(),
  );

  return loginClient;
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
      return 'Неверный username или пароль.';
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

  const millis =
    secondsValue * 1000 + Math.round((timestamp.nanos ?? 0) / 1_000_000);

  return new Date(millis).toISOString();
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
  const client = getLoginClient();
  const result = await invokeUnary(
    client.Login.bind(client),
    request,
    createPublicMetadata(),
  );

  return {
    user: mapUser(result.response),
    sessionId: extractSessionId(result.metadata),
  };
}

export async function registerWithBackend(request: RegisterRequest) {
  const client = getLoginClient();
  const result = await invokeUnary(
    client.Register.bind(client),
    request,
    createPublicMetadata(),
  );

  return {
    user: mapUser(result.response),
    sessionId: extractSessionId(result.metadata),
  };
}

export async function logoutWithBackend(sessionId: string) {
  const client = getLoginClient();

  await invokeUnary(
    client.Logout.bind(client),
    {},
    createAuthorizedMetadata(sessionId),
  );
}
