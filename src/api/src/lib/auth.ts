import { HttpRequest } from '@azure/functions';

/**
 * Parsed SWA Easy Auth client principal.
 * SWA injects the `x-ms-client-principal` header on every authenticated request.
 * The value is a Base64-encoded JSON payload.
 */
export interface ClientPrincipal {
  identityProvider: string;
  userId: string;
  userDetails: string;
  userRoles: string[];
  claims: Array<{ typ: string; val: string }>;
}

export interface AuthUser {
  identityProvider: string;
  userId: string;
  userDetails: string;
  userRoles: string[];
}

/**
 * Parse the SWA client principal header and return typed user info.
 * Returns `null` when the request is unauthenticated.
 */
export function getUser(request: HttpRequest): AuthUser | null {
  const header = request.headers.get('x-ms-client-principal');
  if (!header) {
    return null;
  }

  try {
    const decoded = Buffer.from(header, 'base64').toString('utf-8');
    const principal: ClientPrincipal = JSON.parse(decoded);

    return {
      identityProvider: principal.identityProvider,
      userId: principal.userId,
      userDetails: principal.userDetails,
      userRoles: principal.userRoles ?? [],
    };
  } catch {
    return null;
  }
}

/**
 * Require authentication — throws a Response with 401 if not authenticated.
 * Use at the top of any Azure Function handler that needs auth.
 */
export function requireAuth(request: HttpRequest): AuthUser {
  const user = getUser(request);
  if (!user) {
    throw { status: 401, body: 'Unauthorized: no valid client principal' };
  }
  return user;
}
