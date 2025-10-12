import { describe, it, expect, vi, beforeEach } from 'vitest'
import { imageRecognitionApi } from '../src/api/imageRecognition'
import { apiClient } from '../src/api/client'

vi.mock('../src/api/client', () => ({
  apiClient: {
    post: vi.fn(),
  },
}))

describe('imageRecognitionApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('recognizeIngredients', () => {
    it('単一画像で食材認識APIを呼び出す', async () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      const mockResponse = {
        success: true,
        recognized_ingredients: [
          { name: 'トマト', confidence: 0.95 },
          { name: 'きゅうり', confidence: 0.88 },
        ],
      }

      vi.mocked(apiClient.post).mockResolvedValueOnce({ data: mockResponse })

      const result = await imageRecognitionApi.recognizeIngredients(mockFile)

      expect(apiClient.post).toHaveBeenCalledTimes(1)
      expect(apiClient.post).toHaveBeenCalledWith(
        '/user_ingredients/recognize',
        expect.any(FormData),
        {
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        }
      )
      expect(result).toEqual(mockResponse)
    })

    it('FormDataに画像が正しく追加される', async () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      const mockResponse = {
        success: true,
        recognized_ingredients: [],
      }

      let capturedFormData: FormData | undefined

      vi.mocked(apiClient.post).mockImplementationOnce((url, data) => {
        capturedFormData = data as FormData
        return Promise.resolve({ data: mockResponse })
      })

      await imageRecognitionApi.recognizeIngredients(mockFile)

      expect(capturedFormData).toBeInstanceOf(FormData)
      expect(capturedFormData?.get('image')).toBe(mockFile)
    })

    it('API呼び出しエラー時にエラーを投げる', async () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      const mockError = new Error('Network error')

      vi.mocked(apiClient.post).mockRejectedValueOnce(mockError)

      await expect(imageRecognitionApi.recognizeIngredients(mockFile)).rejects.toThrow('Network error')
    })
  })

  describe('recognizeMultipleIngredients', () => {
    it('単一画像の場合はimageキーで送信', async () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      const mockResponse = {
        success: true,
        recognized_ingredients: [{ name: 'にんじん', confidence: 0.92 }],
      }

      let capturedFormData: FormData | undefined

      vi.mocked(apiClient.post).mockImplementationOnce((url, data) => {
        capturedFormData = data as FormData
        return Promise.resolve({ data: mockResponse })
      })

      await imageRecognitionApi.recognizeMultipleIngredients([mockFile])

      expect(capturedFormData).toBeInstanceOf(FormData)
      expect(capturedFormData?.get('image')).toBe(mockFile)
      expect(capturedFormData?.has('images[]')).toBe(false)
    })

    it('複数画像の場合はimages[]キーで送信', async () => {
      const mockFile1 = new File(['test1'], 'test1.jpg', { type: 'image/jpeg' })
      const mockFile2 = new File(['test2'], 'test2.jpg', { type: 'image/jpeg' })
      const mockResponse = {
        success: true,
        recognized_ingredients: [
          { name: 'キャベツ', confidence: 0.89 },
          { name: 'レタス', confidence: 0.85 },
        ],
      }

      vi.mocked(apiClient.post).mockResolvedValueOnce({ data: mockResponse })

      const result = await imageRecognitionApi.recognizeMultipleIngredients([mockFile1, mockFile2])

      expect(apiClient.post).toHaveBeenCalledTimes(1)
      expect(result).toEqual(mockResponse)
    })

    it('APIからエラーレスポンスが返る場合', async () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      const mockResponse = {
        success: false,
        recognized_ingredients: [],
        message: '画像の認識に失敗しました',
        errors: ['ファイルサイズが大きすぎます'],
      }

      vi.mocked(apiClient.post).mockResolvedValueOnce({ data: mockResponse })

      const result = await imageRecognitionApi.recognizeMultipleIngredients([mockFile])

      expect(result.success).toBe(false)
      expect(result.message).toBe('画像の認識に失敗しました')
      expect(result.errors).toEqual(['ファイルサイズが大きすぎます'])
    })
  })
})
