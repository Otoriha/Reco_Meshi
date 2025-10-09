import React, { useState, useEffect } from 'react';
import Modal from '../ui/Modal';
import { SEVERITY_OPTIONS } from '../../constants/settings';
import type { AllergyIngredient } from '../../types/allergy';

type Props = {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: { severity?: 'mild' | 'moderate' | 'severe'; note?: string }) => Promise<void>;
  allergy: AllergyIngredient | null;
};

const EditAllergyModal: React.FC<Props> = ({ isOpen, onClose, onSubmit, allergy }) => {
  const [severity, setSeverity] = useState<'mild' | 'moderate' | 'severe'>('mild');
  const [note, setNote] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (allergy) {
      setSeverity(allergy.severity);
      setNote(allergy.note || '');
    }
  }, [allergy]);

  const handleSubmit = async () => {
    setError(null);
    if (note.length > 500) {
      setError('備考は500文字以内で入力してください');
      return;
    }

    try {
      await onSubmit({
        severity,
        note: note || undefined
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

  if (!allergy) return null;

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title="アレルギー食材を編集">
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
            value={allergy.ingredient.name}
            disabled
          />
        </div>

        <div>
          <label className="block text-sm text-gray-700 mb-1">
            重症度 <span className="text-red-500">*</span>
          </label>
          <select
            className="w-full px-3 py-2 border rounded"
            value={severity}
            onChange={(e) => setSeverity(e.target.value as 'mild' | 'moderate' | 'severe')}
          >
            {SEVERITY_OPTIONS.map(option => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm text-gray-700 mb-1 flex justify-between">
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

export default EditAllergyModal;
