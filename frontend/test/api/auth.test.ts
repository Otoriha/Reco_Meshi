import { describe, it, expect, vi, beforeEach } from 'vitest';
import { generateLineNonce, lineLoginWithCode, requestPasswordReset, resetPassword } from '../../src/api/auth';
import { apiClient } from '../../src/api/client';
import { dispatchAuthTokenChanged } from '../../src/api/authEvents';

vi.mock('../../src/api/client');
vi.mock('../../src/api/authEvents');

describe('LINE Login API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // localStorage mock
    global.localStorage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn(),
      length: 0,
      key: vi.fn()
    };
  });

  describe('generateLineNonce', () => {
    it('ノンスを正常に取得できること', async () => {
      const mockNonce = 'test-nonce-123';
      vi.mocked(apiClient.post).mockResolvedValue({
        data: { nonce: mockNonce }
      });

      const result = await generateLineNonce();

      expect(apiClient.post).toHaveBeenCalledWith('/auth/generate_nonce');
      expect(result).toBe(mockNonce);
    });

    it('エラー時に例外をスローすること', async () => {
      vi.mocked(apiClient.post).mockRejectedValue(new Error('Network error'));

      await expect(generateLineNonce()).rejects.toThrow('Network error');
    });
  });

  describe('lineLoginWithCode', () => {
    const mockUserData = {
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      created_at: '2025-10-15T00:00:00Z',
      updated_at: '2025-10-15T00:00:00Z'
    };

    const mockToken = 'mock-jwt-token';

    const loginData = {
      code: 'test-authorization-code',
      nonce: 'test-nonce-123',
      redirectUri: 'http://localhost:3001/auth/line/callback'
    };

    it('LINEログインが成功すること', async () => {
      vi.mocked(apiClient.post).mockResolvedValue({
        data: {
          token: mockToken,
          user: mockUserData
        }
      });

      const result = await lineLoginWithCode(loginData);

      expect(apiClient.post).toHaveBeenCalledWith('/auth/line/exchange', {
        code: loginData.code,
        nonce: loginData.nonce,
        redirect_uri: loginData.redirectUri
      });

      expect(localStorage.setItem).toHaveBeenCalledWith('authToken', mockToken);
      expect(localStorage.setItem).toHaveBeenCalledWith('userData', JSON.stringify(mockUserData));

      expect(dispatchAuthTokenChanged).toHaveBeenCalledWith({
        isLoggedIn: true,
        user: mockUserData
      });

      expect(result).toEqual(mockUserData);
    });

    it('トークン交換エラー時に適切なエラーメッセージを返すこと', async () => {
      const errorResponse = {
        response: {
          data: {
            error: {
              code: 'token_exchange_failed',
              message: 'Token exchange failed'
            }
          }
        },
        isAxiosError: true
      };

      vi.mocked(apiClient.post).mockRejectedValue(errorResponse);

      await expect(lineLoginWithCode(loginData)).rejects.toThrow('Token exchange failed');
    });

    it('文字列型エラー時に適切なエラーメッセージを返すこと', async () => {
      const errorResponse = {
        response: {
          data: {
            error: 'ログインに失敗しました'
          }
        },
        isAxiosError: true
      };

      vi.mocked(apiClient.post).mockRejectedValue(errorResponse);

      await expect(lineLoginWithCode(loginData)).rejects.toThrow('ログインに失敗しました');
    });

    it('一般的なネットワークエラー時にデフォルトメッセージを返すこと', async () => {
      vi.mocked(apiClient.post).mockRejectedValue(new Error('Network error'));

      await expect(lineLoginWithCode(loginData)).rejects.toThrow('LINEログインに失敗しました。もう一度お試しください。');
    });
  });
});

describe('Password Reset API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('requestPasswordReset', () => {
    it('パスワードリセットメール送信が成功すること', async () => {
      const mockMessage = 'パスワードリセットメールを送信しました。メールをご確認ください';
      const testEmail = 'test@example.com';

      vi.mocked(apiClient.post).mockResolvedValue({
        data: { message: mockMessage }
      });

      const result = await requestPasswordReset({ email: testEmail });

      expect(apiClient.post).toHaveBeenCalledWith('/auth/password', {
        user: { email: testEmail }
      });
      expect(result).toEqual({ message: mockMessage });
    });

    it('バリデーションエラー時に例外をスローすること', async () => {
      const errorResponse = {
        response: {
          status: 422,
          data: {
            errors: ['無効なメールアドレスです']
          }
        },
        isAxiosError: true
      };

      vi.mocked(apiClient.post).mockRejectedValue(errorResponse);

      await expect(
        requestPasswordReset({ email: 'invalid-email' })
      ).rejects.toThrow();
    });
  });

  describe('resetPassword', () => {
    it('パスワード変更が成功すること', async () => {
      const mockMessage = 'パスワードを変更しました。新しいパスワードでログインしてください';
      const resetData = {
        password: 'newPassword123',
        password_confirmation: 'newPassword123',
        reset_password_token: 'test-token-123'
      };

      vi.mocked(apiClient.put).mockResolvedValue({
        data: { message: mockMessage }
      });

      const result = await resetPassword(resetData);

      expect(apiClient.put).toHaveBeenCalledWith('/auth/password', {
        user: resetData
      });
      expect(result).toEqual({ message: mockMessage });
    });

    it('無効なトークンでバリデーションエラーが発生すること', async () => {
      const errorResponse = {
        response: {
          status: 422,
          data: {
            errors: ['トークンが無効またはメールアドレスが既に確認されています']
          }
        },
        isAxiosError: true
      };

      vi.mocked(apiClient.put).mockRejectedValue(errorResponse);

      const resetData = {
        password: 'newPassword123',
        password_confirmation: 'newPassword123',
        reset_password_token: 'invalid-token'
      };

      await expect(resetPassword(resetData)).rejects.toThrow();
    });
  });
});
