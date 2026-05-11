'use client';

import { useEffect, useState } from 'react';

interface AuthUser {
  identityProvider: string;
  userId: string;
  userDetails: string;
  userRoles: string[];
}

interface AuthState {
  user: AuthUser | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: () => void;
  logout: () => void;
}

interface SWAAuthResponse {
  clientPrincipal: {
    identityProvider: string;
    userId: string;
    userDetails: string;
    userRoles: string[];
  } | null;
}

/**
 * React hook for SWA Easy Auth.
 * Calls the `/.auth/me` endpoint to retrieve the current user session.
 */
export function useAuth(): AuthState {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function fetchUser(): Promise<void> {
      try {
        const res = await fetch('/.auth/me');
        if (!res.ok) {
          setUser(null);
          return;
        }
        const data: SWAAuthResponse = await res.json();
        if (!cancelled && data.clientPrincipal) {
          setUser({
            identityProvider: data.clientPrincipal.identityProvider,
            userId: data.clientPrincipal.userId,
            userDetails: data.clientPrincipal.userDetails,
            userRoles: data.clientPrincipal.userRoles ?? [],
          });
        }
      } catch {
        if (!cancelled) setUser(null);
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    }

    void fetchUser();
    return () => { cancelled = true; };
  }, []);

  return {
    user,
    isLoading,
    isAuthenticated: user !== null,
    login: () => { window.location.href = '/.auth/login/aad'; },
    logout: () => { window.location.href = '/.auth/logout'; },
  };
}
