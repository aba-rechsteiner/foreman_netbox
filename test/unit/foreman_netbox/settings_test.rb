# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanNetbox
  class SettingsTest < ActiveSupport::TestCase
    describe 'netbox_disk_base_unit' do
      it 'defaults to the Netbox default' do
        assert_equal 1000, Setting[:netbox_disk_base_unit]
      end

      it 'accepts 1024' do
        assert Foreman.settings.set_user_value('netbox_disk_base_unit', '1024').valid?
      end

      it 'rejects other values' do
        setting = Foreman.settings.set_user_value('netbox_disk_base_unit', '1023')

        assert_not setting.valid?
        assert_includes setting.errors[:value], 'Netbox disk base unit must be 1000 or 1024'
      end
    end
  end
end
