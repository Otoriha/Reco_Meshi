import React, { useMemo, useState } from 'react';
import Modal from '../ui/Modal';
import { useIngredients } from '../../hooks/useIngredients';
import { PRIORITY_OPTIONS } from '../../constants/settings';
import type { DislikedIngredient, DislikedIngredientCreateData } from '../../types/disliked';

type Props = {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: DislikedIngredientCreateData) => Promise<void>;
  existingDisliked: DislikedIngredient[];
};

const AddDislikedModal: React.FC<Props> = ({ isOpen, onClose, onSubmit, existingDisliked }) => {
  const { items, search, setSearch } = useIngredients({ perPage: 50 });
  const [selectedId, setSelectedId] = useState<number | ''>('');
  const [priority, setPriority] = useState<'low' | 'medium' | 'high'>('low');
  const [reason, setReason] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  // 既に登録済みの食材IDのセット
  const existingIngredientIds = useMemo(() => {
    return new Set(existingDisliked.map(d => d.ingredient_id));
  }, [existingDisliked]);

  // 選択可能な食材（既登録を除外）
  const availableItems = useMemo(() => {
    return items.filter(item => !existingIngredientIds.has(item.id));
  }, [items, existingIngredientIds]);

  const canSubmit = useMemo(() => {
    return !!selectedId && !!priority && reason.length <= 500;
  }, [selectedId, priority, reason]);

  const handleSubmit = async () => {
    setError(null);
    if (!selectedId) {
      setError('食材を選択してください');
      return;
    }
    if (!priority) {
      setError('優先度を選択してください');
      return;
    }
    if (reason.length > 500) {
      setError('理由は500文字以内で入力してください');
      return;
    }

    try {
      await onSubmit({
        ingredient_id: Number(selectedId),
        priority,
        reason: reason || undefined
      });
      // 成功時はリセット
      setSelectedId('');
      setPriority('low');
      setReason('');
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
    setPriority('low');
    setReason('');
    setSearch('');
    setError(null);
    onClose();
  };

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title="苦手な食材を追加">
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
            placeholder="例: セロリ"
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
          <label className="block text-sm text-gray-700 mb-1">
            優先度 <span className="text-red-500">*</span>
          </label>
          <select
            className="w-full px-3 py-2 border rounded"
            value={priority}
            onChange={(e) => setPriority(e.target.value as 'low' | 'medium' | 'high')}
          >
            {PRIORITY_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <p className="text-xs text-gray-500 mt-1">レシピ提案時の除外優先度を設定します</p>
        </div>

        <div>
          <label className="flex justify-between text-sm text-gray-700 mb-1">
            <span>理由（任意）</span>
            <span className="text-xs text-gray-500">{reason.length}/500</span>
          </label>
          <textarea
            className="w-full px-3 py-2 border rounded"
            rows={3}
            maxLength={500}
            placeholder="例: 苦味が苦手"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
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

export default AddDislikedModal;
