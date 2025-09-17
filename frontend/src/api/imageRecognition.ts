import apiClient from './client';

export interface ImageRecognitionRequest {
  image: File;
}

export interface ImageRecognitionResponse {
  success: boolean;
  recognized_ingredients: Array<{
    name: string;
    confidence: number;
  }>;
  message?: string;
}

export const imageRecognitionApi = {
  /**
   * 画像をアップロードして食材を認識する
   */
  async recognizeIngredients(image: File): Promise<ImageRecognitionResponse> {
    const formData = new FormData();
    formData.append('image', image);

    const response = await apiClient.post<ImageRecognitionResponse>(
      '/user_ingredients/recognize',
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );

    return response.data;
  },

  /**
   * 複数の画像をアップロードして食材を認識する
   */
  async recognizeMultipleIngredients(images: File[]): Promise<ImageRecognitionResponse> {
    const formData = new FormData();
    images.forEach((image, index) => {
      formData.append(`images[${index}]`, image);
    });

    const response = await apiClient.post<ImageRecognitionResponse>(
      '/user_ingredients/recognize_multiple',
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );

    return response.data;
  },
};