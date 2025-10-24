import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import PasswordResetSuccess from '../../../src/pages/Auth/PasswordResetSuccess';

describe('PasswordResetSuccess', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('emailが渡された場合、待機状態が表示されること', () => {
    render(
      <MemoryRouter initialEntries={[{ pathname: '/password/reset/success', state: { email: 'test@example.com' } }]}>
        <PasswordResetSuccess />
      </MemoryRouter>
    );

    expect(screen.getByText('パスワードリセットメールを送信しました')).toBeInTheDocument();
    expect(screen.getByText(/test@example.com/)).toBeInTheDocument();
  });

  it('successフラグが渡された場合、成功状態が表示されること', () => {
    render(
      <MemoryRouter initialEntries={[{ pathname: '/password/reset/success', state: { success: true } }]}>
        <PasswordResetSuccess />
      </MemoryRouter>
    );

    expect(screen.getByText('パスワード変更完了')).toBeInTheDocument();
    expect(screen.getByText('新しいパスワードでログインしてください。')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'ログインする' })).toBeInTheDocument();
  });

  it('stateがない場合、ログイン画面にリダイレクトされること', async () => {
    render(
      <MemoryRouter initialEntries={[{ pathname: '/password/reset/success' }]}>
        <Routes>
          <Route path="/password/reset/success" element={<PasswordResetSuccess />} />
          <Route path="/login" element={<div>ログイン画面</div>} />
        </Routes>
      </MemoryRouter>
    );

    // stateなしでリダイレクトされるため、PasswordResetSuccessの内容が表示されず、
    // 代わりにログイン画面へ遷移する
    await waitFor(() => {
      expect(screen.getByText('ログイン画面')).toBeInTheDocument();
    });
  });

  it('待機状態でログイン画面に戻るボタンが動作すること', async () => {
    const user = userEvent.setup();

    render(
      <MemoryRouter initialEntries={[{ pathname: '/password/reset/success', state: { email: 'test@example.com' } }]}>
        <Routes>
          <Route path="/password/reset/success" element={<PasswordResetSuccess />} />
          <Route path="/login" element={<div>ログイン画面</div>} />
        </Routes>
      </MemoryRouter>
    );

    const backButton = screen.getByRole('button', { name: 'ログイン画面に戻る' });
    await user.click(backButton);

    await waitFor(() => {
      expect(screen.getByText('ログイン画面')).toBeInTheDocument();
    });
  });

  it('成功状態でログインするボタンが動作すること', async () => {
    const user = userEvent.setup();

    render(
      <MemoryRouter initialEntries={[{ pathname: '/password/reset/success', state: { success: true } }]}>
        <Routes>
          <Route path="/password/reset/success" element={<PasswordResetSuccess />} />
          <Route path="/login" element={<div>ログイン画面</div>} />
        </Routes>
      </MemoryRouter>
    );

    const loginButton = screen.getByRole('button', { name: 'ログインする' });
    await user.click(loginButton);

    await waitFor(() => {
      expect(screen.getByText('ログイン画面')).toBeInTheDocument();
    });
  });
});
