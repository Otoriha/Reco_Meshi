import apiClient from './client';

export interface ImageRecognitionResponse {
  success: boolean;
  recognized_ingredients: Array<{
    name: string;
    confidence: number;
  }>;
  message?: string;
  errors?: string[];
}

const sendRecognitionRequest = async (formData: FormData): Promise<ImageRecognitionResponse> => {
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
};

export const imageRecognitionApi = {
  /**
   * 単一画像で食材認識を実行する
   */
  async recognizeIngredients(image: File): Promise<ImageRecognitionResponse> {
    const formData = new FormData();
    formData.append('image', image);
    return sendRecognitionRequest(formData);
  },

  /**
   * 複数画像で食材認識を実行する
   */
  async recognizeMultipleIngredients(images: File[]): Promise<ImageRecognitionResponse> {
    const formData = new FormData();

    if (images.length === 1) {
      formData.append('image', images[0]);
    } else {
      images.forEach((image) => {
        formData.append('images[]', image);
      });
    }

    return sendRecognitionRequest(formData);
  },
};

export default imageRecognitionApi;
