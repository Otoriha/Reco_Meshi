import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getDislikedIngredients, createDislikedIngredient, updateDislikedIngredient, deleteDislikedIngredient } from '../../src/api/dislikedIngredients';
import { apiClient } from '../../src/api/client';

vi.mock('../../src/api/client');

describe('dislikedIngredients API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getDislikedIngredients', () => {
    it('苦手食材一覧を取得できる', async () => {
      const mockData = [
        {
          id: '1',
          user_id: 1,
          ingredient_id: 20,
          priority: 'medium' as const,
          priority_label: '中',
          reason: 'テスト理由',
          ingredient: { id: 20, name: 'セロリ', category: 'vegetables', unit: 'g', emoji: '🌿' },
          created_at: '2025-10-09T00:00:00Z',
          updated_at: '2025-10-09T00:00:00Z'
        }
      ];

      vi.mocked(apiClient.get).mockResolvedValue({ data: mockData });

      const result = await getDislikedIngredients();

      expect(apiClient.get).toHaveBeenCalledWith('/users/disliked_ingredients');
      expect(result).toEqual(mockData);
    });
  });

  describe('createDislikedIngredient', () => {
    it('苦手食材を登録できる', async () => {
      const createData = {
        ingredient_id: 20,
        priority: 'medium' as const,
        reason: 'テスト理由'
      };

      const mockResponse = {
        id: '1',
        user_id: 1,
        ingredient_id: 20,
        priority: 'medium' as const,
        priority_label: '中',
        reason: 'テスト理由',
        ingredient: { id: 20, name: 'セロリ', category: 'vegetables', unit: 'g', emoji: '🌿' },
        created_at: '2025-10-09T00:00:00Z',
        updated_at: '2025-10-09T00:00:00Z'
      };

      vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse });

      const result = await createDislikedIngredient(createData);

      expect(apiClient.post).toHaveBeenCalledWith('/users/disliked_ingredients', {
        disliked_ingredient: createData
      });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('updateDislikedIngredient', () => {
    it('苦手食材を更新できる', async () => {
      const updateData = {
        priority: 'high' as const,
        reason: '更新した理由'
      };

      const mockResponse = {
        id: '1',
        user_id: 1,
        ingredient_id: 20,
        priority: 'high' as const,
        priority_label: '高',
        reason: '更新した理由',
        ingredient: { id: 20, name: 'セロリ', category: 'vegetables', unit: 'g', emoji: '🌿' },
        created_at: '2025-10-09T00:00:00Z',
        updated_at: '2025-10-09T01:00:00Z'
      };

      vi.mocked(apiClient.patch).mockResolvedValue({ data: mockResponse });

      const result = await updateDislikedIngredient(1, updateData);

      expect(apiClient.patch).toHaveBeenCalledWith('/users/disliked_ingredients/1', {
        disliked_ingredient: updateData
      });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('deleteDislikedIngredient', () => {
    it('苦手食材を削除できる', async () => {
      vi.mocked(apiClient.delete).mockResolvedValue({ data: undefined });

      await deleteDislikedIngredient(1);

      expect(apiClient.delete).toHaveBeenCalledWith('/users/disliked_ingredients/1');
    });
  });
});
