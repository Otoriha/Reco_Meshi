require 'rails_helper'

RSpec.describe LineRichMenuService, type: :service do
  let(:service) { described_class.new }
  let(:line_channel_secret) { 'test_channel_secret' }
  let(:line_channel_access_token) { 'test_access_token' }
  # 公式SDK仕様に合わせて ApiClient と ApiBlobClient を分離
  let(:mock_client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }
  let(:mock_blob_client) { instance_double(Line::Bot::V2::MessagingApi::ApiBlobClient) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_SECRET').and_return(line_channel_secret)
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_ACCESS_TOKEN').and_return(line_channel_access_token)
    allow(ENV).to receive(:[]).with('LIFF_ID').and_return('test-liff-id')
    # V2対応: LINE Bot V2 Client を分離してモック
    allow(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(mock_client)
    allow(Line::Bot::V2::MessagingApi::ApiBlobClient).to receive(:new).and_return(mock_blob_client)
  end

  describe '#initialize' do
    it 'creates a LINE Bot V2 client with correct configuration' do
      expect(service.send(:client)).to eq(mock_client)
    end
  end

  describe '#create_rich_menu' do
    let(:rich_menu_id) { 'richmenu-test-id' }

    context 'when successful' do
      it 'creates a rich menu and returns the ID' do
        # 公式SDK：戻り値は RichMenuIdResponse オブジェクト
        success_response = double('RichMenuIdResponse', rich_menu_id: rich_menu_id)
        expect(mock_client).to receive(:create_rich_menu).with(rich_menu_request: anything).and_return(success_response)

        result = service.create_rich_menu

        expect(result).to eq(rich_menu_id)
      end
    end

    context 'when failed' do
      it 'logs error and returns nil' do
        # 公式SDK：例外は投げず、失敗時は rich_menu_id が nil
        failure_response = double('RichMenuIdResponse', rich_menu_id: nil)
        expect(mock_client).to receive(:create_rich_menu).with(rich_menu_request: anything).and_return(failure_response)
        expect(Rails.logger).to receive(:error)

        result = service.create_rich_menu

        expect(result).to be_nil
      end
    end

    context 'when exception occurs' do
      it 'logs error and returns nil' do
        expect(mock_client).to receive(:create_rich_menu).and_raise(StandardError.new('Network Error'))
        expect(Rails.logger).to receive(:error)

        result = service.create_rich_menu

        expect(result).to be_nil
      end
    end
  end

  describe '#set_rich_menu_image' do
    let(:rich_menu_id) { 'richmenu-test-id' }
    let(:image_path) { '/tmp/test_image.png' }

    before do
      # テスト用の一時ファイルを作成
      File.write(image_path, 'dummy image data')
    end

    after do
      # テスト後にファイルを削除
      File.delete(image_path) if File.exist?(image_path)
    end

    context 'when successful' do
      it 'uploads image via ApiBlobClient and returns true' do
        # 公式SDK：set_rich_menu_image は ApiBlobClient で実行（content_typeは不要）
        expect(mock_blob_client).to receive(:set_rich_menu_image).with(
          rich_menu_id: rich_menu_id,
          body: kind_of(String)
        )

        result = service.set_rich_menu_image(rich_menu_id, image_path)

        expect(result).to be true
      end
    end

    context 'when failed' do
      it 'logs error and returns false' do
        expect(mock_blob_client).to receive(:set_rich_menu_image).and_raise(StandardError.new('Upload Error'))
        expect(Rails.logger).to receive(:error)

        result = service.set_rich_menu_image(rich_menu_id, image_path)

        expect(result).to be false
      end
    end
  end

  describe '#set_default_rich_menu' do
    let(:rich_menu_id) { 'richmenu-test-id' }

    context 'when successful' do
      it 'sets default rich menu and returns true' do
        expect(mock_client).to receive(:set_default_rich_menu).with(rich_menu_id: rich_menu_id)

        result = service.set_default_rich_menu(rich_menu_id)

        expect(result).to be true
      end
    end

    context 'when failed' do
      it 'logs error and returns false' do
        expect(mock_client).to receive(:set_default_rich_menu).with(rich_menu_id: rich_menu_id).and_raise(StandardError.new('API Error'))
        expect(Rails.logger).to receive(:error)

        result = service.set_default_rich_menu(rich_menu_id)

        expect(result).to be false
      end
    end
  end

  describe '#get_rich_menu_list' do
    context 'when successful' do
      it 'returns list of rich menus' do
        # 公式SDK：戻り値は RichMenuListResponse（richmenus配列を持つ）
        rich_menu1 = double('RichMenuResponse', rich_menu_id: 'menu1')
        rich_menu2 = double('RichMenuResponse', rich_menu_id: 'menu2')
        success_response = double('RichMenuListResponse', richmenus: [rich_menu1, rich_menu2])
        expect(mock_client).to receive(:get_rich_menu_list).and_return(success_response)

        result = service.get_rich_menu_list

        expect(result).to eq([rich_menu1, rich_menu2])
      end
    end

    context 'when failed' do
      it 'logs error and returns empty array' do
        expect(mock_client).to receive(:get_rich_menu_list).and_raise(StandardError.new('API Error'))
        expect(Rails.logger).to receive(:error)

        result = service.get_rich_menu_list

        expect(result).to eq([])
      end
    end
  end

  describe '#delete_rich_menu' do
    let(:rich_menu_id) { 'richmenu-test-id' }

    context 'when successful' do
      it 'deletes rich menu and returns true' do
        expect(mock_client).to receive(:delete_rich_menu).with(rich_menu_id: rich_menu_id)

        result = service.delete_rich_menu(rich_menu_id)

        expect(result).to be true
      end
    end

    context 'when failed' do
      it 'logs error and returns false' do
        expect(mock_client).to receive(:delete_rich_menu).with(rich_menu_id: rich_menu_id).and_raise(StandardError.new('API Error'))
        expect(Rails.logger).to receive(:error)

        result = service.delete_rich_menu(rich_menu_id)

        expect(result).to be false
      end
    end
  end

  describe '#get_default_rich_menu_id' do
    let(:rich_menu_id) { 'richmenu-default-id' }

    context 'when default menu exists' do
      it 'returns the default rich menu ID' do
        # 公式SDK：メソッド名は get_default_rich_menu_id で RichMenuIdResponse を返す
        success_response = double('RichMenuIdResponse', rich_menu_id: rich_menu_id)
        expect(mock_client).to receive(:get_default_rich_menu_id).and_return(success_response)

        result = service.get_default_rich_menu_id

        expect(result).to eq(rich_menu_id)
      end
    end

    context 'when no default menu is set' do
      it 'returns nil' do
        expect(mock_client).to receive(:get_default_rich_menu_id).and_raise(StandardError.new('Not Found'))

        result = service.get_default_rich_menu_id

        expect(result).to be_nil
      end
    end
  end

  describe '#cancel_default_rich_menu' do
    context 'when successful' do
      it 'cancels default rich menu and returns true' do
        expect(mock_client).to receive(:cancel_default_rich_menu)

        result = service.cancel_default_rich_menu

        expect(result).to be true
      end
    end

    context 'when failed' do
      it 'logs error and returns false' do
        expect(mock_client).to receive(:cancel_default_rich_menu).and_raise(StandardError.new('API Error'))
        expect(Rails.logger).to receive(:error)

        result = service.cancel_default_rich_menu

        expect(result).to be false
      end
    end
  end

  describe '#cleanup_all_rich_menus' do
    it 'deletes all rich menus' do
      rich_menu1 = double('RichMenuResponse', rich_menu_id: 'menu1')
      rich_menu2 = double('RichMenuResponse', rich_menu_id: 'menu2')
      allow(service).to receive(:get_rich_menu_list).and_return([rich_menu1, rich_menu2])
      allow(service).to receive(:delete_rich_menu).with('menu1').and_return(true)
      allow(service).to receive(:delete_rich_menu).with('menu2').and_return(true)

      service.cleanup_all_rich_menus

      expect(service).to have_received(:delete_rich_menu).with('menu1')
      expect(service).to have_received(:delete_rich_menu).with('menu2')
    end
  end

  describe '#setup_default_rich_menu' do
    let(:rich_menu_id) { 'richmenu-test-id' }

    context 'when all operations succeed' do
      it 'sets up default rich menu successfully' do
        allow(service).to receive(:cleanup_all_rich_menus)
        allow(service).to receive(:create_rich_menu).and_return(rich_menu_id)
        allow(service).to receive(:set_default_rich_menu).and_return(true)

        result = service.setup_default_rich_menu

        expect(result).to be true
      end
    end

    context 'when rich menu creation fails' do
      it 'returns false' do
        allow(service).to receive(:cleanup_all_rich_menus)
        allow(service).to receive(:create_rich_menu).and_return(nil)

        result = service.setup_default_rich_menu

        expect(result).to be false
      end
    end
  end

  # create_rich_menu_objectのテスト（型確認）
  describe '#create_rich_menu_object (basic functionality)' do
    it 'creates RichMenuRequest object without error' do
      expect { service.send(:create_rich_menu_object) }.not_to raise_error
    end

    it 'returns RichMenuRequest object' do
      allow(Line::Bot::V2::MessagingApi::RichMenuRequest).to receive(:new).and_call_original
      
      result = service.send(:create_rich_menu_object)
      
      expect(Line::Bot::V2::MessagingApi::RichMenuRequest).to have_received(:new)
    end
  end
end