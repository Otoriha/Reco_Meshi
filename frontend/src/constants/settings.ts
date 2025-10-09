export const DIFFICULTY_OPTIONS = [
  { value: 'easy', label: 'かんたん' },
  { value: 'medium', label: 'ふつう' },
  { value: 'hard', label: 'むずかしい' }
] as const;

export const COOKING_TIME_OPTIONS = [
  { value: 15, label: '15分以内' },
  { value: 30, label: '30分以内' },
  { value: 60, label: '1時間以内' },
  { value: 999, label: '時間制限なし' }
] as const;

export const SHOPPING_FREQUENCY_OPTIONS = [
  { value: '毎日', label: '毎日' },
  { value: '2-3日に1回', label: '2-3日に1回' },
  { value: '週に1回', label: '週に1回' },
  { value: 'まとめ買い', label: 'まとめ買い' }
] as const;

export const SEVERITY_OPTIONS = [
  { value: 'mild', label: '軽度' },
  { value: 'moderate', label: '中程度' },
  { value: 'severe', label: '重度' }
] as const;
