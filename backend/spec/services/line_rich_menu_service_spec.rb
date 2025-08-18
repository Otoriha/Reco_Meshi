require 'rails_helper'

RSpec.describe LineRichMenuService, type: :service do
  let(:service) { described_class.new }
  let(:line_channel_secret) { 'test_channel_secret' }
  let(:line_channel_access_token) { 'test_access_token' }
  let(:mock_client) { instance_double(Line::Bot::Client) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_SECRET').and_return(line_channel_secret)
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_ACCESS_TOKEN').and_return(line_channel_access_token)
    allow(Line::Bot::Client).to receive(:new).and_return(mock_client)
  end

  describe '#initialize' do
    it 'creates a LINE Bot client with correct configuration' do
      expect(service.send(:client)).to eq(mock_client)
    end
  end

  describe '#create_rich_menu' do
    let(:rich_menu_id) { 'richmenu-test-id' }
    let(:success_response) { double('response', code: '200', body: { richMenuId: rich_menu_id }.to_json) }
    let(:error_response) { double('response', code: '400', body: 'Error') }

    context 'when successful' do
      it 'creates a rich menu and returns the ID' do
        expect(mock_client).to receive(:create_rich_menu).and_return(success_response)
        
        result = service.create_rich_menu
        expect(result).to eq(rich_menu_id)
      end
    end

    context 'when failed' do
      it 'logs error and returns nil' do
        expect(mock_client).to receive(:create_rich_menu).and_return(error_response)
        expect(Rails.logger).to receive(:error).with("Failed to create rich menu: Error")
        
        result = service.create_rich_menu
        expect(result).to be_nil
      end
    end
  end

  describe '#set_rich_menu_image' do
    let(:rich_menu_id) { 'richmenu-test-id' }
    let(:image_path) { '/tmp/test_image.png' }
    let(:success_response) { double('response', code: '200') }
    let(:error_response) { double('response', code: '400', body: 'Error') }

    before do
      # Mock file operations
      allow(File).to receive(:open).and_yield(StringIO.new('test image data'))
    end

    context 'when successful' do
      it 'uploads image and returns true' do
        expect(mock_client).to receive(:create_rich_menu_image).and_return(success_response)
        
        result = service.set_rich_menu_image(rich_menu_id, image_path)
        expect(result).to be true
      end
    end

    context 'when failed' do
      it 'logs error and returns false' do
        expect(mock_client).to receive(:create_rich_menu_image).and_return(error_response)
        expect(Rails.logger).to receive(:error).with("Failed to upload rich menu image: Error")
        
        result = service.set_rich_menu_image(rich_menu_id, image_path)
        expect(result).to be false
      end
    end
  end

  describe '#set_default_rich_menu' do
    let(:rich_menu_id) { 'richmenu-test-id' }
    let(:success_response) { double('response', code: '200') }
    let(:error_response) { double('response', code: '400', body: 'Error') }

    context 'when successful' do
      it 'sets default rich menu and returns true' do
        expect(mock_client).to receive(:set_default_rich_menu).with(rich_menu_id).and_return(success_response)
        
        result = service.set_default_rich_menu(rich_menu_id)
        expect(result).to be true
      end
    end

    context 'when failed' do
      it 'logs error and returns false' do
        expect(mock_client).to receive(:set_default_rich_menu).with(rich_menu_id).and_return(error_response)
        expect(Rails.logger).to receive(:error).with("Failed to set default rich menu: Error")
        
        result = service.set_default_rich_menu(rich_menu_id)
        expect(result).to be false
      end
    end
  end

  describe '#get_rich_menu_list' do
    let(:rich_menus) { [{ 'richMenuId' => 'test-id-1' }, { 'richMenuId' => 'test-id-2' }] }
    let(:success_response) { double('response', code: '200', body: { richmenus: rich_menus }.to_json) }
    let(:error_response) { double('response', code: '400', body: 'Error') }

    context 'when successful' do
      it 'returns list of rich menus' do
        expect(mock_client).to receive(:get_rich_menu_list).and_return(success_response)
        
        result = service.get_rich_menu_list
        expect(result).to eq(rich_menus)
      end
    end

    context 'when failed' do
      it 'logs error and returns empty array' do
        expect(mock_client).to receive(:get_rich_menu_list).and_return(error_response)
        expect(Rails.logger).to receive(:error).with("Failed to get rich menu list: Error")
        
        result = service.get_rich_menu_list
        expect(result).to eq([])
      end
    end
  end

  describe '#delete_rich_menu' do
    let(:rich_menu_id) { 'richmenu-test-id' }
    let(:success_response) { double('response', code: '200') }
    let(:error_response) { double('response', code: '400', body: 'Error') }

    context 'when successful' do
      it 'deletes rich menu and returns true' do
        expect(mock_client).to receive(:delete_rich_menu).with(rich_menu_id).and_return(success_response)
        
        result = service.delete_rich_menu(rich_menu_id)
        expect(result).to be true
      end
    end

    context 'when failed' do
      it 'logs error and returns false' do
        expect(mock_client).to receive(:delete_rich_menu).with(rich_menu_id).and_return(error_response)
        expect(Rails.logger).to receive(:error).with("Failed to delete rich menu: Error")
        
        result = service.delete_rich_menu(rich_menu_id)
        expect(result).to be false
      end
    end
  end

  describe '#get_default_rich_menu_id' do
    let(:rich_menu_id) { 'richmenu-test-id' }
    let(:success_response) { double('response', code: '200', body: { richMenuId: rich_menu_id }.to_json) }
    let(:not_found_response) { double('response', code: '404') }

    context 'when default menu exists' do
      it 'returns the default rich menu ID' do
        expect(mock_client).to receive(:get_default_rich_menu).and_return(success_response)
        
        result = service.get_default_rich_menu_id
        expect(result).to eq(rich_menu_id)
      end
    end

    context 'when no default menu is set' do
      it 'returns nil' do
        expect(mock_client).to receive(:get_default_rich_menu).and_return(not_found_response)
        
        result = service.get_default_rich_menu_id
        expect(result).to be_nil
      end
    end
  end

  describe '#cancel_default_rich_menu' do
    let(:success_response) { double('response', code: '200') }
    let(:error_response) { double('response', code: '400', body: 'Error') }

    context 'when successful' do
      it 'cancels default rich menu and returns true' do
        expect(mock_client).to receive(:cancel_default_rich_menu).and_return(success_response)
        
        result = service.cancel_default_rich_menu
        expect(result).to be true
      end
    end

    context 'when failed' do
      it 'logs error and returns false' do
        expect(mock_client).to receive(:cancel_default_rich_menu).and_return(error_response)
        expect(Rails.logger).to receive(:error).with("Failed to cancel default rich menu: Error")
        
        result = service.cancel_default_rich_menu
        expect(result).to be false
      end
    end
  end

  describe '#cleanup_all_rich_menus' do
    let(:rich_menus) do
      [
        { 'richMenuId' => 'test-id-1' },
        { 'richMenuId' => 'test-id-2' }
      ]
    end

    it 'deletes all rich menus' do
      expect(service).to receive(:get_rich_menu_list).and_return(rich_menus)
      expect(service).to receive(:delete_rich_menu).with('test-id-1')
      expect(service).to receive(:delete_rich_menu).with('test-id-2')
      expect(Rails.logger).to receive(:info).with("Cleaned up 2 rich menus")
      
      service.cleanup_all_rich_menus
    end
  end

  describe '#setup_default_rich_menu' do
    let(:rich_menu_id) { 'richmenu-test-id' }

    context 'when all operations succeed' do
      it 'sets up default rich menu successfully' do
        expect(service).to receive(:cleanup_all_rich_menus)
        expect(service).to receive(:create_rich_menu).and_return(rich_menu_id)
        expect(service).to receive(:set_default_rich_menu).with(rich_menu_id).and_return(true)
        
        result = service.setup_default_rich_menu
        expect(result).to be true
      end
    end

    context 'when rich menu creation fails' do
      it 'returns false' do
        expect(service).to receive(:cleanup_all_rich_menus)
        expect(service).to receive(:create_rich_menu).and_return(nil)
        
        result = service.setup_default_rich_menu
        expect(result).to be false
      end
    end
  end

  describe '#create_rich_menu_object' do
    it 'creates a valid rich menu object' do
      rich_menu_object = service.send(:create_rich_menu_object)
      
      expect(rich_menu_object).to include(
        size: { width: 2500, height: 1686 },
        selected: false,
        name: "レコめしメニュー",
        chatBarText: "メニューを開く"
      )
      
      expect(rich_menu_object[:areas]).to be_an(Array)
      expect(rich_menu_object[:areas].length).to eq(5)
      
      # Check first area (recipe request)
      first_area = rich_menu_object[:areas][0]
      expect(first_area[:bounds]).to eq({ x: 0, y: 0, width: 833, height: 843 })
      expect(first_area[:action][:type]).to eq("postback")
      expect(first_area[:action][:data]).to eq("recipe_request")
    end
  end
end