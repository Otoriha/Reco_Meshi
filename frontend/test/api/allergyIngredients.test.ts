import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getAllergyIngredients, createAllergyIngredient, updateAllergyIngredient, deleteAllergyIngredient } from '../../src/api/allergyIngredients';
import { apiClient } from '../../src/api/client';

vi.mock('../../src/api/client');

describe('allergyIngredients API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getAllergyIngredients', () => {
    it('アレルギー食材一覧を取得できる', async () => {
      const mockData = [
        {
          id: 1,
          user_id: 1,
          ingredient_id: 10,
          note: 'テスト備考',
          ingredient: { id: 10, name: 'そば', category: 'others', unit: 'g', emoji: '🍜' },
          created_at: '2025-10-09T00:00:00Z',
          updated_at: '2025-10-09T00:00:00Z'
        }
      ];

      vi.mocked(apiClient.get).mockResolvedValue({ data: mockData });

      const result = await getAllergyIngredients();

      expect(apiClient.get).toHaveBeenCalledWith('/users/allergy_ingredients');
      expect(result).toEqual(mockData);
    });
  });

  describe('createAllergyIngredient', () => {
    it('アレルギー食材を登録できる', async () => {
      const createData = {
        ingredient_id: 10,
        note: 'テスト備考'
      };

      const mockResponse = {
        id: 1,
        user_id: 1,
        ingredient_id: 10,
        note: 'テスト備考',
        ingredient: { id: 10, name: 'そば', category: 'others', unit: 'g', emoji: '🍜' },
        created_at: '2025-10-09T00:00:00Z',
        updated_at: '2025-10-09T00:00:00Z'
      };

      vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse });

      const result = await createAllergyIngredient(createData);

      expect(apiClient.post).toHaveBeenCalledWith('/users/allergy_ingredients', {
        allergy_ingredient: createData
      });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('updateAllergyIngredient', () => {
    it('アレルギー食材を更新できる', async () => {
      const updateData = {
        note: '更新した備考'
      };

      const mockResponse = {
        id: 1,
        user_id: 1,
        ingredient_id: 10,
        note: '更新した備考',
        ingredient: { id: 10, name: 'そば', category: 'others', unit: 'g', emoji: '🍜' },
        created_at: '2025-10-09T00:00:00Z',
        updated_at: '2025-10-09T01:00:00Z'
      };

      vi.mocked(apiClient.patch).mockResolvedValue({ data: mockResponse });

      const result = await updateAllergyIngredient(1, updateData);

      expect(apiClient.patch).toHaveBeenCalledWith('/users/allergy_ingredients/1', {
        allergy_ingredient: updateData
      });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('deleteAllergyIngredient', () => {
    it('アレルギー食材を削除できる', async () => {
      vi.mocked(apiClient.delete).mockResolvedValue({ data: undefined });

      await deleteAllergyIngredient(1);

      expect(apiClient.delete).toHaveBeenCalledWith('/users/allergy_ingredients/1');
    });
  });
});
