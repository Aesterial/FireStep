import type { CurrentUser } from './app';

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  initials: string;
  org: string;
}

export interface UserInfo {
  id: string;
  username: string;
  initials: string;
  email: string;
  org: string;
  joined: string;
}

export interface AuthResponse {
  user: CurrentUser;
}

export interface LogoutResponse {
  success: boolean;
}

interface ApiErrorPayload {
  message?: string;
}

class AuthApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = 'AuthApiError';
    this.status = status;
  }
}

async function requestJson<TResponse>(
  path: string,
  init: RequestInit,
): Promise<TResponse> {
  const response = await fetch(path, {
    ...init,
    credentials: 'same-origin',
    headers: {
      'content-type': 'application/json',
      ...init.headers,
    },
  });

  const contentType = response.headers.get('content-type') ?? '';
  const payload = contentType.includes('application/json')
    ? ((await response.json()) as ApiErrorPayload | TResponse)
    : null;

  if (!response.ok) {
    const errorPayload = payload as ApiErrorPayload | null;
    const message =
      typeof errorPayload?.message === 'string'
        ? errorPayload.message
        : 'Не удалось выполнить запрос.';

    throw new AuthApiError(message, response.status);
  }

  return payload as TResponse;
}

export interface IAuthServiceClient {
  login(request: LoginRequest): Promise<AuthResponse>;
  register(request: RegisterRequest): Promise<AuthResponse>;
  logout(): Promise<LogoutResponse>;
}

class AuthServiceClient implements IAuthServiceClient {
  login(request: LoginRequest): Promise<AuthResponse> {
    return requestJson<AuthResponse>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  register(request: RegisterRequest): Promise<AuthResponse> {
    return requestJson<AuthResponse>('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  logout(): Promise<LogoutResponse> {
    return requestJson<LogoutResponse>('/api/auth/logout', {
      method: 'POST',
      body: JSON.stringify({}),
    });
  }
}

export const authService = new AuthServiceClient();
