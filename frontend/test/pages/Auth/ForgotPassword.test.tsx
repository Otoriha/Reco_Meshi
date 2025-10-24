import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import ForgotPassword from '../../../src/pages/Auth/ForgotPassword';
import * as authApi from '../../../src/api/auth';

vi.mock('../../../src/api/auth');

describe('ForgotPassword', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('フォームが表示されること', () => {
    render(
      <BrowserRouter>
        <ForgotPassword />
      </BrowserRouter>
    );

    expect(screen.getByText('パスワードリセット')).toBeInTheDocument();
    expect(screen.getByLabelText('メールアドレス')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /パスワードリセットメールを送信/ })).toBeInTheDocument();
  });

  it('メール送信成功時にPasswordResetSuccessへ遷移すること', async () => {
    vi.mocked(authApi.requestPasswordReset).mockResolvedValue({
      message: 'パスワードリセットメールを送信しました'
    });

    const user = userEvent.setup();

    render(
      <BrowserRouter>
        <ForgotPassword />
      </BrowserRouter>
    );

    const emailInput = screen.getByLabelText('メールアドレス');
    const submitButton = screen.getByRole('button', { name: /パスワードリセットメールを送信/ });

    await user.type(emailInput, 'test@example.com');
    await user.click(submitButton);

    await waitFor(() => {
      expect(authApi.requestPasswordReset).toHaveBeenCalledWith({
        email: 'test@example.com'
      });
    });
  });

  it('APIエラー時にエラーメッセージを表示すること', async () => {
    const errorMessage = '無効なメールアドレスです';
    vi.mocked(authApi.requestPasswordReset).mockRejectedValue({
      response: {
        status: 422,
        data: { errors: [errorMessage] }
      }
    });

    const user = userEvent.setup();

    render(
      <BrowserRouter>
        <ForgotPassword />
      </BrowserRouter>
    );

    const emailInput = screen.getByLabelText('メールアドレス');
    const submitButton = screen.getByRole('button', { name: /パスワードリセットメールを送信/ });

    await user.type(emailInput, 'invalid-email');
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(errorMessage)).toBeInTheDocument();
    });
  });

  it('送信中はフォームが非活性化されること', async () => {
    let resolveRequest: () => void;
    const requestPromise = new Promise<{ message: string }>((resolve) => {
      resolveRequest = () => resolve({ message: 'success' });
    });

    vi.mocked(authApi.requestPasswordReset).mockReturnValue(requestPromise);

    const user = userEvent.setup();

    render(
      <BrowserRouter>
        <ForgotPassword />
      </BrowserRouter>
    );

    const emailInput = screen.getByLabelText('メールアドレス');
    const submitButton = screen.getByRole('button', { name: /パスワードリセットメールを送信/ });

    await user.type(emailInput, 'test@example.com');
    await user.click(submitButton);

    expect(submitButton).toHaveTextContent('送信中...');
    expect(emailInput).toBeDisabled();

    resolveRequest!();
  });
});
