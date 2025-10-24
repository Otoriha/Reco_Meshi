import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import ChangePassword from '../../../src/pages/Settings/ChangePassword';
import * as usersApi from '../../../src/api/users';

const mockShowToast = vi.fn();

vi.mock('../../../src/api/users');
vi.mock('../../../src/hooks/useToast', () => ({
  useToast: () => ({
    showToast: mockShowToast,
  }),
}));
vi.mock('../../../src/hooks/useAuth', () => ({
  useAuth: () => ({
    logout: vi.fn(),
  }),
}));

describe('ChangePassword', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const renderWithRouter = (component: React.ReactElement) => {
    return render(
      <BrowserRouter>
        {component}
      </BrowserRouter>
    );
  };

  it('フォームが表示されること', () => {
    renderWithRouter(<ChangePassword />);

    expect(screen.getByText('パスワードを変更')).toBeInTheDocument();
    expect(screen.getByLabelText('現在のパスワード')).toBeInTheDocument();
    expect(screen.getByLabelText('新しいパスワード')).toBeInTheDocument();
    expect(screen.getByLabelText('パスワード確認')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '変更する' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'キャンセル' })).toBeInTheDocument();
  });

  it('パスワード変更が成功すること', async () => {
    vi.mocked(usersApi.changePassword).mockResolvedValue({
      message: 'パスワードを変更しました',
    });

    const user = userEvent.setup();

    renderWithRouter(<ChangePassword />);

    const currentPasswordInput = screen.getByLabelText('現在のパスワード');
    const newPasswordInput = screen.getByLabelText('新しいパスワード');
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: '変更する' });

    await user.type(currentPasswordInput, 'oldPassword123');
    await user.type(newPasswordInput, 'newPassword456');
    await user.type(confirmInput, 'newPassword456');
    await user.click(submitButton);

    await waitFor(() => {
      expect(usersApi.changePassword).toHaveBeenCalledWith({
        current_password: 'oldPassword123',
        new_password: 'newPassword456',
        new_password_confirmation: 'newPassword456',
      });
    });
  });

  it('パスワードが一致しない場合、バリデーションエラーが表示されること', async () => {
    const user = userEvent.setup();

    renderWithRouter(<ChangePassword />);

    const currentPasswordInput = screen.getByLabelText('現在のパスワード');
    const newPasswordInput = screen.getByLabelText('新しいパスワード');
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: '変更する' });

    await user.type(currentPasswordInput, 'oldPassword123');
    await user.type(newPasswordInput, 'newPassword456');
    await user.type(confirmInput, 'differentPassword789');
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('新しいパスワードが一致しません')).toBeInTheDocument();
    });
  });

  it('パスワード長が6文字未満の場合、バリデーションエラーが表示されること', async () => {
    const user = userEvent.setup();

    renderWithRouter(<ChangePassword />);

    const currentPasswordInput = screen.getByLabelText('現在のパスワード');
    const newPasswordInput = screen.getByLabelText('新しいパスワード');
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: '変更する' });

    await user.type(currentPasswordInput, 'oldPassword123');
    await user.type(newPasswordInput, 'pass');
    await user.type(confirmInput, 'pass');
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('パスワードは6文字以上で入力してください')).toBeInTheDocument();
    });
  });

  it('APIエラー時にエラーメッセージが表示されること', async () => {
    vi.mocked(usersApi.changePassword).mockRejectedValue(
      new Error('API Error')
    );

    const user = userEvent.setup();

    renderWithRouter(<ChangePassword />);

    const currentPasswordInput = screen.getByLabelText('現在のパスワード');
    const newPasswordInput = screen.getByLabelText('新しいパスワード');
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: '変更する' });

    await user.type(currentPasswordInput, 'oldPassword123');
    await user.type(newPasswordInput, 'newPassword456');
    await user.type(confirmInput, 'newPassword456');
    await user.click(submitButton);

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith('パスワード変更に失敗しました', 'error');
    });
  });

  it('現在のパスワードが正しくない場合、エラーメッセージが表示されること', async () => {
    const errorResponse = {
      response: {
        status: 401,
      },
    };
    vi.mocked(usersApi.changePassword).mockRejectedValue(errorResponse);

    const user = userEvent.setup();

    renderWithRouter(<ChangePassword />);

    const currentPasswordInput = screen.getByLabelText('現在のパスワード');
    const newPasswordInput = screen.getByLabelText('新しいパスワード');
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: '変更する' });

    await user.type(currentPasswordInput, 'wrongPassword');
    await user.type(newPasswordInput, 'newPassword456');
    await user.type(confirmInput, 'newPassword456');
    await user.click(submitButton);

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith('現在のパスワードが正しくありません', 'error');
    });
  });

  it('バリデーションエラー時にバックエンドのエラーメッセージが表示されること', async () => {
    const errorMessage = 'パスワードに特殊文字を含めてください';
    const errorResponse = {
      response: {
        status: 422,
        data: { errors: { newPassword: [errorMessage] } },
      },
    };
    vi.mocked(usersApi.changePassword).mockRejectedValue(errorResponse);

    const user = userEvent.setup();

    renderWithRouter(<ChangePassword />);

    const currentPasswordInput = screen.getByLabelText('現在のパスワード');
    const newPasswordInput = screen.getByLabelText('新しいパスワード');
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: '変更する' });

    await user.type(currentPasswordInput, 'oldPassword123');
    await user.type(newPasswordInput, 'newPassword456');
    await user.type(confirmInput, 'newPassword456');
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(errorMessage)).toBeInTheDocument();
      expect(mockShowToast).toHaveBeenCalledWith('入力内容を確認してください', 'error');
    });
  });

  it('送信中はボタンが非活性化されること', async () => {
    let resolveRequest: () => void;
    const requestPromise = new Promise<{ message: string }>((resolve) => {
      resolveRequest = () => resolve({ message: 'success' });
    });

    vi.mocked(usersApi.changePassword).mockReturnValue(requestPromise);

    const user = userEvent.setup();

    renderWithRouter(<ChangePassword />);

    const currentPasswordInput = screen.getByLabelText('現在のパスワード');
    const newPasswordInput = screen.getByLabelText('新しいパスワード');
    const confirmInput = screen.getByLabelText('パスワード確認');
    const submitButton = screen.getByRole('button', { name: '変更する' });
    const cancelButton = screen.getByRole('button', { name: 'キャンセル' });

    await user.type(currentPasswordInput, 'oldPassword123');
    await user.type(newPasswordInput, 'newPassword456');
    await user.type(confirmInput, 'newPassword456');
    await user.click(submitButton);

    expect(submitButton).toHaveTextContent('処理中...');
    expect(currentPasswordInput).toBeDisabled();
    expect(newPasswordInput).toBeDisabled();
    expect(confirmInput).toBeDisabled();
    expect(cancelButton).toBeDisabled();

    resolveRequest!();
  });
});
