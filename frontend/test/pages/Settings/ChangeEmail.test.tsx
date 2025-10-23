import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import ChangeEmail from '../../../src/pages/Settings/ChangeEmail';
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

describe('ChangeEmail Page', () => {
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

    vi.mocked(usersAPI.getUserProfile).mockResolvedValue({
      name: 'Test User',
      email: 'current@example.com',
      provider: 'email',
    });

    vi.mocked(usersAPI.changeEmail).mockResolvedValue({
      message: 'メールアドレス変更リクエストを送信しました',
      unconfirmedEmail: 'new@example.com',
    });
  });

  it('should load and display current email', async () => {
    render(
      <BrowserRouter>
        <ChangeEmail />
      </BrowserRouter>
    );

    await waitFor(() => {
      expect(screen.getByDisplayValue('current@example.com')).toBeInTheDocument();
    });
  });

  it('should show error when new email is same as current email', async () => {
    const user = userEvent.setup();

    render(
      <BrowserRouter>
        <ChangeEmail />
      </BrowserRouter>
    );

    await waitFor(() => {
      expect(screen.getByDisplayValue('current@example.com')).toBeInTheDocument();
    });

    const emailInput = screen.getByPlaceholderText('new-email@example.com');
    const passwordInput = screen.getByPlaceholderText('パスワードを入力');

    await user.type(emailInput, 'current@example.com');
    await user.type(passwordInput, 'password123');
    await user.click(screen.getByText('変更する'));

    expect(mockShowToast).toHaveBeenCalledWith(
      '新しいメールアドレスを入力してください',
      'error'
    );
  });

  it('should submit form with valid data', async () => {
    const user = userEvent.setup();

    render(
      <BrowserRouter>
        <ChangeEmail />
      </BrowserRouter>
    );

    await waitFor(() => {
      expect(screen.getByDisplayValue('current@example.com')).toBeInTheDocument();
    });

    const emailInput = screen.getByPlaceholderText('new-email@example.com');
    const passwordInput = screen.getByPlaceholderText('パスワードを入力');

    await user.type(emailInput, 'new@example.com');
    await user.type(passwordInput, 'password123');
    await user.click(screen.getByText('変更する'));

    await waitFor(() => {
      expect(usersAPI.changeEmail).toHaveBeenCalledWith({
        email: 'new@example.com',
        current_password: 'password123',
      });
    });
  });

  it('should handle API error with 422 status', async () => {
    const error = new Error('Validation error') as Error & {
      response?: { status: number; data: { errors: Record<string, string[]> } };
    };
    error.response = {
      status: 422,
      data: {
        errors: {
          email: ['このメールアドレスは既に登録されています'],
        },
      },
    };

    vi.mocked(usersAPI.changeEmail).mockRejectedValue(error);

    const user = userEvent.setup();

    render(
      <BrowserRouter>
        <ChangeEmail />
      </BrowserRouter>
    );

    await waitFor(() => {
      expect(screen.getByDisplayValue('current@example.com')).toBeInTheDocument();
    });

    const emailInput = screen.getByPlaceholderText('new-email@example.com');
    const passwordInput = screen.getByPlaceholderText('パスワードを入力');

    await user.type(emailInput, 'existing@example.com');
    await user.type(passwordInput, 'password123');
    await user.click(screen.getByText('変更する'));

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith('入力内容を確認してください', 'error');
    });
  });

  it('should display error message from API', async () => {
    const user = userEvent.setup();

    render(
      <BrowserRouter>
        <ChangeEmail />
      </BrowserRouter>
    );

    await waitFor(() => {
      expect(screen.getByDisplayValue('current@example.com')).toBeInTheDocument();
    });

    const emailInput = screen.getByPlaceholderText('new-email@example.com');
    const passwordInput = screen.getByPlaceholderText('パスワードを入力');

    await user.type(emailInput, 'new@example.com');
    await user.type(passwordInput, 'wrongpassword');
    await user.click(screen.getByText('変更する'));

    const error = new Error('Unauthorized') as Error & {
      response?: { status: number };
    };
    error.response = {
      status: 401,
    };

    vi.mocked(usersAPI.changeEmail).mockRejectedValue(error);

    await user.click(screen.getByText('変更する'));

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith(
        'セッションが切れました。再度ログインしてください',
        'error'
      );
    });
  });
});
