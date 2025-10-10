import React, { useState, useEffect } from 'react';
import Modal from '../ui/Modal';
import { PRIORITY_OPTIONS } from '../../constants/settings';
import type { DislikedIngredient, DislikedIngredientUpdateData } from '../../types/disliked';

type Props = {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: DislikedIngredientUpdateData) => Promise<void>;
  disliked: DislikedIngredient | null;
};

const EditDislikedModal: React.FC<Props> = ({ isOpen, onClose, onSubmit, disliked }) => {
  const [priority, setPriority] = useState<'low' | 'medium' | 'high'>('low');
  const [reason, setReason] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (disliked) {
      setPriority(disliked.priority);
      setReason(disliked.reason || '');
    }
  }, [disliked]);

  const handleSubmit = async () => {
    setError(null);
    if (reason.length > 500) {
      setError('理由は500文字以内で入力してください');
      return;
    }

    try {
      await onSubmit({
        priority,
        reason: reason || undefined
      });
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
        setError(error?.message || '更新に失敗しました');
      }
    }
  };

  const handleClose = () => {
    setError(null);
    onClose();
  };

  if (!disliked) return null;

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title="苦手な食材を編集">
      <div className="space-y-3">
        {error && (
          <div className="text-sm text-red-600 bg-red-50 border border-red-200 p-2 rounded whitespace-pre-line">
            {error}
          </div>
        )}

        <div>
          <label className="block text-sm text-gray-700 mb-1">食材</label>
          <input
            type="text"
            className="w-full px-3 py-2 border rounded bg-gray-100"
            value={disliked.ingredient.name}
            disabled
          />
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
            className="px-4 py-2 bg-blue-600 text-white rounded"
            onClick={handleSubmit}
          >
            更新
          </button>
        </div>
      </div>
    </Modal>
  );
};

export default EditDislikedModal;
