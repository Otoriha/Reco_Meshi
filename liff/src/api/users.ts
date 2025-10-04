import { apiClient } from './client';

export interface UserProfile {
  name: string;
  email: string;
  provider: string;
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
