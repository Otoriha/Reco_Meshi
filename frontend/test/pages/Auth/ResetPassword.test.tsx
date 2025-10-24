import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import ResetPassword from '../../../src/pages/Auth/ResetPassword';
import * as authApi from '../../../src/api/auth';

vi.mock('../../../src/api/auth');

const renderWithRouter = (component: React.ReactElement, { route = '/password/reset?reset_password_token=test-token-123' } = {}) => {
  window.history.pushState({}, 'Test page', route);
  return render(
    <BrowserRouter>
      {component}
    </BrowserRouter>
  );
};

describe('ResetPassword', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('トークンが存在する場合、フォームが表示されること', () => {
    renderWithRouter(<ResetPassword />);

    expect(screen.getByText('新しいパスワードの設定')).toBeInTheDocument();
    expect(screen.getByLabelText(/新しいパスワード/)).toBeInTheDocument();
    expect(screen.getByLabelText('パスワード確認')).toBeInTheDocument();
  });

  it('トークンがない場合、エラーが表示されること', () => {
    renderWithRouter(<ResetPassword />, { route: '/password/reset' });

    expect(screen.getByText('パスワードリセットリンクが無効です。再度パスワードリセットを申請してください。')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'パスワードリセットを再申請' })).toBeInTheDocument();
  });

  it('パスワードが一致しない場合、バリデーションエラーが表示されること', async () => {
    const user = userEvent.setup();

    renderWithRouter(<ResetPassword />);

    const passwordInput = screen.getByLabelText(/新しいパスワード/);
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: 'パスワードを変更' });

    await user.type(passwordInput, 'password123');
    await user.type(confirmInput, 'password456');
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('パスワードが一致しません')).toBeInTheDocument();
    });
  });

  it('パスワード長が6文字未満の場合、バリデーションエラーが表示されること', async () => {
    const user = userEvent.setup();

    renderWithRouter(<ResetPassword />);

    const passwordInput = screen.getByLabelText(/新しいパスワード/);
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: 'パスワードを変更' });

    await user.type(passwordInput, 'pass');
    await user.type(confirmInput, 'pass');
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('パスワードは6文字以上で入力してください')).toBeInTheDocument();
    });
  });

  it('パスワード変更が成功すること', async () => {
    vi.mocked(authApi.resetPassword).mockResolvedValue({
      message: 'パスワードを変更しました'
    });

    const user = userEvent.setup();

    renderWithRouter(<ResetPassword />);

    const passwordInput = screen.getByLabelText(/新しいパスワード/);
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: 'パスワードを変更' });

    await user.type(passwordInput, 'newPassword123');
    await user.type(confirmInput, 'newPassword123');
    await user.click(submitButton);

    await waitFor(() => {
      expect(authApi.resetPassword).toHaveBeenCalledWith({
        password: 'newPassword123',
        password_confirmation: 'newPassword123',
        reset_password_token: 'test-token-123'
      });
    });
  });

  it('APIエラー時にエラーメッセージが表示されること', async () => {
    const errorMessage = 'トークンが無効です';
    vi.mocked(authApi.resetPassword).mockRejectedValue({
      response: {
        status: 422,
        data: { errors: [errorMessage] }
      }
    });

    const user = userEvent.setup();

    renderWithRouter(<ResetPassword />);

    const passwordInput = screen.getByLabelText(/新しいパスワード/);
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: 'パスワードを変更' });

    await user.type(passwordInput, 'newPassword123');
    await user.type(confirmInput, 'newPassword123');
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(errorMessage)).toBeInTheDocument();
    });
  });

  it('送信中はボタンと入力フィールドが非活性化されること', async () => {
    let resolveRequest: () => void;
    const requestPromise = new Promise<{ message: string }>((resolve) => {
      resolveRequest = () => resolve({ message: 'success' });
    });

    vi.mocked(authApi.resetPassword).mockReturnValue(requestPromise);

    const user = userEvent.setup();

    renderWithRouter(<ResetPassword />);

    const passwordInput = screen.getByLabelText(/新しいパスワード/);
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: 'パスワードを変更' });

    await user.type(passwordInput, 'newPassword123');
    await user.type(confirmInput, 'newPassword123');
    await user.click(submitButton);

    expect(submitButton).toHaveTextContent('変更中...');
    expect(passwordInput).toBeDisabled();
    expect(confirmInput).toBeDisabled();

    resolveRequest!();
  });

  it('パスワードフィールドのトグルが動作すること', async () => {
    const user = userEvent.setup();

    renderWithRouter(<ResetPassword />);

    const passwordInput = screen.getByLabelText(/新しいパスワード/) as HTMLInputElement;
    const toggleButtons = screen.getAllByRole('button').filter((btn) => {
      return btn.getAttribute('aria-label')?.includes('パスワード');
    });

    // 初期状態はpassword型
    expect(passwordInput.type).toBe('password');

    // トグル
    await user.click(toggleButtons[0]);
    expect(passwordInput.type).toBe('text');

    await user.click(toggleButtons[0]);
    expect(passwordInput.type).toBe('password');
  });

  it('エラー状態から再送信ができること', async () => {
    const user = userEvent.setup();

    renderWithRouter(<ResetPassword />);

    const passwordInput = screen.getByLabelText(/新しいパスワード/);
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: 'パスワードを変更' });

    // 最初の送信（バリデーションエラー）
    await user.type(passwordInput, 'pass');
    await user.type(confirmInput, 'pass');
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('パスワードは6文字以上で入力してください')).toBeInTheDocument();
    });

    // 入力をリセット
    await user.clear(passwordInput);
    await user.clear(confirmInput);

    // 正しいパスワードで再送信
    vi.mocked(authApi.resetPassword).mockResolvedValue({
      message: 'パスワードを変更しました'
    });

    await user.type(passwordInput, 'newPassword123');
    await user.type(confirmInput, 'newPassword123');
    await user.click(submitButton);

    await waitFor(() => {
      expect(authApi.resetPassword).toHaveBeenCalled();
    });
  });
});
