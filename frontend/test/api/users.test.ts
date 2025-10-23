import { describe, it, expect, vi, beforeEach } from 'vitest';
import { apiClient } from '../../src/api/client';
import {
  changeEmail,
  confirmEmail,
  getUserProfile,
  updateUserProfile,
} from '../../src/api/users';

// Mock apiClient
vi.mock('../../src/api/client');

describe('Users API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('changeEmail', () => {
    it('should send change email request with correct payload', async () => {
      const mockResponse = {
        data: {
          message: 'メールアドレス変更リクエストを送信しました',
          unconfirmed_email: 'new@example.com',
        },
      };

      vi.mocked(apiClient.post).mockResolvedValue(mockResponse);

      const result = await changeEmail({
        email: 'new@example.com',
        current_password: 'password123',
      });

      expect(apiClient.post).toHaveBeenCalledWith('/users/change_email', {
        email_change: {
          email: 'new@example.com',
          current_password: 'password123',
        },
      });

      expect(result).toEqual({
        message: 'メールアドレス変更リクエストを送信しました',
        unconfirmedEmail: 'new@example.com',
      });
    });

    it('should convert snake_case to camelCase', async () => {
      const mockResponse = {
        data: {
          message: 'Success',
          unconfirmed_email: 'test@example.com',
        },
      };

      vi.mocked(apiClient.post).mockResolvedValue(mockResponse);

      const result = await changeEmail({
        email: 'test@example.com',
        current_password: 'pass',
      });

      expect(result.unconfirmedEmail).toBe('test@example.com');
    });
  });

  describe('confirmEmail', () => {
    it('should confirm email with token', async () => {
      const mockResponse = {
        data: {
          message: 'メールアドレスを確認しました。ログインしてください',
          email: 'confirmed@example.com',
        },
      };

      vi.mocked(apiClient.get).mockResolvedValue(mockResponse);

      const result = await confirmEmail('test-token-123');

      expect(apiClient.get).toHaveBeenCalledWith(
        '/auth/confirmation',
        expect.objectContaining({
          params: {
            confirmation_token: 'test-token-123',
          },
        })
      );

      expect(result).toEqual({
        message: 'メールアドレスを確認しました。ログインしてください',
        email: 'confirmed@example.com',
      });
    });

    it('should handle confirmation errors', async () => {
      const error = new Error('Token invalid');
      vi.mocked(apiClient.get).mockRejectedValue(error);

      await expect(confirmEmail('invalid-token')).rejects.toThrow('Token invalid');
    });
  });

  describe('getUserProfile', () => {
    it('should fetch user profile', async () => {
      const mockResponse = {
        data: {
          name: 'John Doe',
          email: 'john@example.com',
          provider: 'email',
        },
      };

      vi.mocked(apiClient.get).mockResolvedValue(mockResponse);

      const result = await getUserProfile();

      expect(apiClient.get).toHaveBeenCalledWith('/users/profile');
      expect(result).toEqual(mockResponse.data);
    });
  });

  describe('updateUserProfile', () => {
    it('should update user profile with new name', async () => {
      const mockResponse = {
        data: {
          message: 'プロフィールを更新しました',
        },
      };

      vi.mocked(apiClient.patch).mockResolvedValue(mockResponse);

      const result = await updateUserProfile({ name: 'Jane Doe' });

      expect(apiClient.patch).toHaveBeenCalledWith('/users/profile', {
        profile: { name: 'Jane Doe' },
      });

      expect(result).toEqual(mockResponse.data);
    });
  });
});
