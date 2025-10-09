import React, { useMemo, useState } from 'react';
import Modal from '../ui/Modal';
import { useIngredients } from '../../hooks/useIngredients';
import type { AllergyIngredient } from '../../types/allergy';

type Props = {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: { ingredient_id: number; note?: string }) => Promise<void>;
  existingAllergies: AllergyIngredient[];
};

const AddAllergyModal: React.FC<Props> = ({ isOpen, onClose, onSubmit, existingAllergies }) => {
  const { items, search, setSearch } = useIngredients({ perPage: 50 });
  const [selectedId, setSelectedId] = useState<number | ''>('');
  const [note, setNote] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  // 既に登録済みの食材IDのセット
  const existingIngredientIds = useMemo(() => {
    return new Set(existingAllergies.map(a => a.ingredient_id));
  }, [existingAllergies]);

  // 選択可能な食材（既登録を除外）
  const availableItems = useMemo(() => {
    return items.filter(item => !existingIngredientIds.has(item.id));
  }, [items, existingIngredientIds]);

  const canSubmit = useMemo(() => {
    return !!selectedId && note.length <= 500;
  }, [selectedId, note]);

  const handleSubmit = async () => {
    setError(null);
    if (!selectedId) {
      setError('食材を選択してください');
      return;
    }
    if (note.length > 500) {
      setError('備考は500文字以内で入力してください');
      return;
    }

    try {
      await onSubmit({
        ingredient_id: Number(selectedId),
        note: note || undefined
      });
      // 成功時はリセット
      setSelectedId('');
      setNote('');
      setSearch('');
      onClose();
    } catch (e: unknown) {
      const error = e as { response?: { data?: { errors?: Record<string, string[]> } }; message?: string };
      if (error?.response?.data?.errors) {
        const errors = error.response.data.errors;
        const messages = Object.entries(errors)
          .map(([key, msgs]) => `${key}: ${msgs.join(', ')}`)
          .join('\n');
        setError(messages);
      } else {
        setError(error?.message || '登録に失敗しました');
      }
    }
  };

  const handleClose = () => {
    setSelectedId('');
    setNote('');
    setSearch('');
    setError(null);
    onClose();
  };

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title="アレルギー食材を追加">
      <div className="space-y-3">
        {error && (
          <div className="text-sm text-red-600 bg-red-50 border border-red-200 p-2 rounded whitespace-pre-line">
            {error}
          </div>
        )}

        <div>
          <label className="block text-sm text-gray-700 mb-1">食材を検索</label>
          <input
            type="text"
            className="w-full px-3 py-2 border rounded"
            placeholder="例: そば"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div>
          <label className="block text-sm text-gray-700 mb-1">
            食材 <span className="text-red-500">*</span>
          </label>
          <select
            className="w-full px-3 py-2 border rounded"
            value={selectedId}
            onChange={(e) => setSelectedId(e.target.value ? Number(e.target.value) : '')}
          >
            <option value="">選択してください</option>
            {availableItems.map((i) => (
              <option key={i.id} value={i.id}>
                {i.name}
              </option>
            ))}
          </select>
          {availableItems.length === 0 && items.length > 0 && (
            <p className="text-xs text-gray-500 mt-1">全ての食材が既に登録済みです</p>
          )}
        </div>

        <div>
          <label className="flex justify-between text-sm text-gray-700 mb-1">
            <span>備考（任意）</span>
            <span className="text-xs text-gray-500">{note.length}/500</span>
          </label>
          <textarea
            className="w-full px-3 py-2 border rounded"
            rows={3}
            maxLength={500}
            placeholder="症状やその他の情報を入力"
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
        </div>

        <div className="flex justify-end gap-2 pt-2">
          <button
            className="px-4 py-2 bg-gray-200 text-gray-800 rounded"
            onClick={handleClose}
          >
            キャンセル
          </button>
          <button
            className="px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
            disabled={!canSubmit}
            onClick={handleSubmit}
          >
            追加
          </button>
        </div>
      </div>
    </Modal>
  );
};

export default AddAllergyModal;
