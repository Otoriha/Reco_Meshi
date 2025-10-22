import { apiClient } from './client';

export interface LineAccount {
  displayName?: string;
  linkedAt?: string;
}

export interface UserProfile {
  name: string;
  email: string;
  provider: string;
  lineAccount?: LineAccount;
}

export interface UserSettings {
  default_servings: number;
  recipe_difficulty: 'easy' | 'medium' | 'hard';
  cooking_time: number;
  shopping_frequency: string;
  inventory_reminder_enabled: boolean;
  inventory_reminder_time: string; // HH:MM形式
}

export interface UpdateProfileData {
  name: string;
}

export interface UpdateSettingsData {
  default_servings?: number;
  recipe_difficulty?: 'easy' | 'medium' | 'hard';
  cooking_time?: number;
  shopping_frequency?: string;
  inventory_reminder_enabled?: boolean;
  inventory_reminder_time?: string;
}

export interface ChangePasswordData {
  current_password: string;
  new_password: string;
  new_password_confirmation: string;
}

export interface ChangeEmailData {
  email: string;
  current_password: string;
}

export interface MessageResponse {
  message: string;
}

export interface ChangeEmailResponse {
  message: string;
  unconfirmedEmail: string;
}

export interface ConfirmEmailResponse {
  message: string;
  email: string;
}

export const getUserProfile = async (): Promise<UserProfile> => {
  const response = await apiClient.get('/users/profile');
  return response.data;
};

export const updateUserProfile = async (data: UpdateProfileData): Promise<MessageResponse> => {
  const response = await apiClient.patch('/users/profile', { profile: data });
  return response.data;
};

export const getUserSettings = async (): Promise<UserSettings> => {
  const response = await apiClient.get('/users/settings');
  return response.data;
};

export const updateUserSettings = async (data: UpdateSettingsData): Promise<MessageResponse> => {
  const response = await apiClient.patch('/users/settings', { settings: data });
  return response.data;
};

export const changePassword = async (data: ChangePasswordData): Promise<MessageResponse> => {
  const response = await apiClient.post('/users/change_password', { password: data });
  return response.data;
};

export const changeEmail = async (data: ChangeEmailData): Promise<ChangeEmailResponse> => {
  const response = await apiClient.post('/users/change_email', { email_change: data });
  // snake_case → camelCase 変換
  return {
    message: response.data.message,
    unconfirmedEmail: response.data.unconfirmed_email,
  };
};

// メールアドレス確認API
export const confirmEmail = async (confirmationToken: string): Promise<ConfirmEmailResponse> => {
  const response = await apiClient.get('/auth/confirmation', {
    params: {
      confirmation_token: confirmationToken,
    },
  });
  // snake_case → camelCase 変換
  return {
    message: response.data.message,
    email: response.data.email,
  };
};
