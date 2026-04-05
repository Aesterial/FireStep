import {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
} from 'react';

import type { CurrentUser } from '../contracts/app';
import { authService } from '../contracts/auth';

const USER_STORAGE_KEY = 'firestep-current-user';

interface AuthContextType {
  user: CurrentUser | null;
  isLoading: boolean;
  setUser: (user: CurrentUser | null) => void;
  refresh: () => Promise<CurrentUser | null>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  isLoading: true,
  setUser: () => {},
  refresh: async () => null,
  logout: async () => {},
});

async function fetchCurrentUser() {
  const response = await fetch('/api/me', {
    credentials: 'same-origin',
  });

  if (!response.ok) {
    return null;
  }

  return (await response.json()) as CurrentUser;
}

function readStoredUser() {
  if (typeof window === 'undefined') {
    return null;
  }

  try {
    const raw = window.localStorage.getItem(USER_STORAGE_KEY);
    return raw ? (JSON.parse(raw) as CurrentUser) : null;
  } catch {
    return null;
  }
}

function persistUser(nextUser: CurrentUser | null) {
  if (typeof window === 'undefined') {
    return;
  }

  if (!nextUser) {
    window.localStorage.removeItem(USER_STORAGE_KEY);
    return;
  }

  window.localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(nextUser));
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<CurrentUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const authMutationRef = useRef(0);

  const applyUser = useCallback((nextUser: CurrentUser | null) => {
    authMutationRef.current += 1;
    setUser(nextUser);
    persistUser(nextUser);
    setIsLoading(false);
  }, []);

  const refresh = useCallback(async () => {
    const requestVersion = authMutationRef.current;

    try {
      const nextUser = await fetchCurrentUser();

      if (requestVersion !== authMutationRef.current) {
        return nextUser;
      }

      if (nextUser) {
        setUser(nextUser);
        persistUser(nextUser);
        return nextUser;
      }

      setUser((previous) => {
        if (previous) {
          return previous;
        }

        persistUser(null);
        return null;
      });

      return nextUser;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const logout = useCallback(async () => {
    await authService.logout();
    applyUser(null);
  }, [applyUser]);

  useEffect(() => {
    const storedUser = readStoredUser();

    if (storedUser) {
      setUser(storedUser);
      setIsLoading(false);
    }

    void refresh();
  }, [refresh]);

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        setUser: applyUser,
        refresh,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
