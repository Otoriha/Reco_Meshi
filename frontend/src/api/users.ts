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
}

export interface UpdateProfileData {
  name: string;
}

export interface UpdateSettingsData {
  default_servings?: number;
  recipe_difficulty?: 'easy' | 'medium' | 'hard';
  cooking_time?: number;
  shopping_frequency?: string;
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

export const changeEmail = async (data: ChangeEmailData): Promise<MessageResponse> => {
  const response = await apiClient.post('/users/change_email', { email_change: data });
  return response.data;
};
