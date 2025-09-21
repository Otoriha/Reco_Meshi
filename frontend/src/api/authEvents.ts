import type { UserData } from './auth';

export const AUTH_TOKEN_CHANGED_EVENT = 'auth-token-changed';

export interface AuthChangeDetail {
  user?: UserData | null;
  isLoggedIn?: boolean;
}

export const dispatchAuthTokenChanged = (detail?: AuthChangeDetail) => {
  window.dispatchEvent(
    new CustomEvent<AuthChangeDetail>(AUTH_TOKEN_CHANGED_EVENT, { detail })
  );
};
