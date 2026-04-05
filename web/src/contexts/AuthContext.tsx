import {
  createContext,
  type ReactNode,
  useContext,
  useEffect,
  useState,
} from 'react';

import type { CurrentUser } from '../contracts/app';
import { authService } from '../contracts/auth';

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

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<CurrentUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const refresh = async () => {
    try {
      const nextUser = await fetchCurrentUser();
      setUser(nextUser);
      return nextUser;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    await authService.logout();
    setUser(null);
  };

  useEffect(() => {
    void refresh();
  }, []);

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        setUser,
        refresh,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
