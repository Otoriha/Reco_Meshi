import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import EmailConfirmationSuccess from '../../../src/pages/Settings/EmailConfirmationSuccess';
import * as usersAPI from '../../../src/api/users';
import * as authHooks from '../../../src/hooks/useAuth';
import * as toastHooks from '../../../src/hooks/useToast';

// Mock modules
vi.mock('../../../src/api/users');
vi.mock('../../../src/hooks/useAuth');
vi.mock('../../../src/hooks/useToast');
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => vi.fn(),
  };
});

describe('EmailConfirmationSuccess Page', () => {
  const mockLogout = vi.fn();
  const mockShowToast = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();

    vi.mocked(authHooks.useAuth).mockReturnValue({
      logout: mockLogout,
      isAuthenticated: true,
      user: null,
    } as ReturnType<typeof authHooks.useAuth>);

    vi.mocked(toastHooks.useToast).mockReturnValue({
      showToast: mockShowToast,
    } as ReturnType<typeof toastHooks.useToast>);

    vi.mocked(usersAPI.confirmEmail).mockResolvedValue({
      message: 'メールアドレスを確認しました。ログインしてください',
      email: 'confirmed@example.com',
    });
  });

  it('should display awaiting state after email change submission', async () => {
    const { getByText, getByDisplayValue } = render(
      <MemoryRouter
        initialEntries={[
          {
            pathname: '/settings/email-confirmation',
            state: { unconfirmedEmail: 'new@example.com' },
          },
        ]}
      >
        <EmailConfirmationSuccess />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(getByText('確認メールを送信しました')).toBeInTheDocument();
      expect(getByDisplayValue('new@example.com')).toBeInTheDocument();
    });

    expect(getByText('メール内のリンクをクリックして、メールアドレスの確認を完了してください。')).toBeInTheDocument();
  });

  it('should display loading state when token is present', async () => {
    const { getByText } = render(
      <MemoryRouter
        initialEntries={['/settings/email-confirmation?confirmation_token=test-token']}
      >
        <EmailConfirmationSuccess />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(getByText('メールアドレスを確認中...')).toBeInTheDocument();
    });
  });

  it('should display success state after email confirmation', async () => {
    const { getByText, getByDisplayValue } = render(
      <MemoryRouter
        initialEntries={['/settings/email-confirmation?confirmation_token=test-token']}
      >
        <EmailConfirmationSuccess />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(getByText('メールアドレス確認完了')).toBeInTheDocument();
      expect(getByDisplayValue('confirmed@example.com')).toBeInTheDocument();
    });

    expect(mockShowToast).toHaveBeenCalledWith(
      'メールアドレスが確認されました',
      'success'
    );
  });

  it('should display error state when confirmation token is invalid', async () => {
    const error = new Error('Invalid token') as Error & {
      response?: { status: number; data: { message: string } };
    };
    error.response = {
      status: 422,
      data: {
        message: 'トークンが無効です',
      },
    };

    vi.mocked(usersAPI.confirmEmail).mockRejectedValue(error);

    const { getByText } = render(
      <MemoryRouter
        initialEntries={['/settings/email-confirmation?confirmation_token=invalid-token']}
      >
        <EmailConfirmationSuccess />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(getByText('確認に失敗しました')).toBeInTheDocument();
      expect(getByText('トークンが無効です')).toBeInTheDocument();
    });
  });

  it('should handle 401 errors and logout', async () => {
    const error = new Error('Unauthorized') as Error & {
      response?: { status: number; data: Record<string, unknown> };
    };
    error.response = {
      status: 401,
      data: {},
    };

    vi.mocked(usersAPI.confirmEmail).mockRejectedValue(error);

    render(
      <MemoryRouter
        initialEntries={['/settings/email-confirmation?confirmation_token=test-token']}
      >
        <EmailConfirmationSuccess />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(mockLogout).toHaveBeenCalled();
    });
  });

  it('should display back button and retry button in error state', async () => {
    const error = new Error('Token expired') as Error & {
      response?: { status: number; data: { message: string } };
    };
    error.response = {
      status: 422,
      data: {
        message: 'トークンの有効期限が切れています',
      },
    };

    vi.mocked(usersAPI.confirmEmail).mockRejectedValue(error);

    const { getByText } = render(
      <MemoryRouter
        initialEntries={['/settings/email-confirmation?confirmation_token=expired-token']}
      >
        <EmailConfirmationSuccess />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(getByText('戻る')).toBeInTheDocument();
      expect(getByText('再度変更')).toBeInTheDocument();
    });
  });
});
