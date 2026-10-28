# frozen_string_literal: true

module ForemanNetbox
  class CachedNetboxParameters
    def self.call(host)
      new(host).call
    end

    def initialize(host)
      @host = host
      @is_compute = host.netbox_virtual_machine?
      @data = host.netbox_facet.raw_data&.deep_symbolize_keys || {}
      @result = {}
    end

    def call
      additional_params = is_compute ? ForemanNetbox::NetboxFacet::VIRTUAL_MACHINE_PARAMS : ForemanNetbox::NetboxFacet::DEVICE_PARAMS
      (ForemanNetbox::NetboxFacet::COMMON_PARAMS + additional_params).map { |key| send("read_#{key}") }

      result
    end

    private

    attr_reader :host, :data, :is_compute
    attr_accessor :result

    # status and custom fields are only compared if they are mapped by Foreman parameters
    def mapped_status_and_custom_fields(object_data)
      custom_field_names = host.netbox_custom_fields.keys.map(&:to_sym)

      {
        status: (object_data.dig(:status, :value) if host.netbox_host_param(:status)),
        custom_fields: (object_data.fetch(:custom_fields, {}).slice(*custom_field_names) if custom_field_names.any?),
      }
    end

    def read_interfaces
      return unless data.key?(:interfaces)

      result[:interfaces] = data.fetch(:interfaces, {}).fetch(:results, []).map do |interface|
        interface.slice(:name, :mac_address)
                 .merge(type: interface[:type]&.slice(:value))
                 .compact
      end
    end

    def read_ip_addresses
      return unless data.key?(:ip_addresses)

      result[:ip_addresses] = data.fetch(:ip_addresses, {}).fetch(:results, []).map do |ip_address|
        ip_address.slice(:address)
                  .merge(interface: (ip_address[:assigned_object] || {}).slice(:name))
      end
    end

    def read_virtual_machine
      return unless data.key?(:virtual_machine)

      virtual_machine = data.fetch(:virtual_machine, {})
      # with virtual disks, Netbox calculates the disk size of the virtual machine itself
      attributes = data.key?(:virtual_disks) ? %i[name vcpus memory] : %i[name vcpus memory disk]
      result[:virtual_machine] = virtual_machine.slice(*attributes)
                                                .merge(mapped_status_and_custom_fields(virtual_machine))
                                                .compact
    end

    def read_virtual_disks
      return unless data.key?(:virtual_disks)

      result[:virtual_disks] = data.fetch(:virtual_disks, {}).fetch(:results, []).map do |virtual_disk|
        virtual_disk.slice(:name, :size)
      end
    end

    def read_tenant
      return unless data.key?(:tenant)

      result[:tenant] = data.fetch(:tenant, {}).slice(:name, :slug)
    end

    def read_cluster
      return unless data.key?(:cluster)

      result[:cluster] = data.fetch(:cluster, {}).slice(:name)
    end

    def read_cluster_type
      return unless data.key?(:cluster_type)

      result[:cluster_type] = data.fetch(:cluster_type, {}).slice(:name, :slug)
    end

    def read_device
      return unless data.key?(:device)

      device = data.fetch(:device, {})
      result[:device] = device.slice(:name, :serial)
                              .merge(mapped_status_and_custom_fields(device))
                              .compact
                              .reject { |k, v| k == :serial && v.blank? }
    end

    def read_device_role
      return unless data.key?(:device_role)

      result[:device_role] = data.fetch(:device_role, {}).slice(:name, :slug)
    end

    def read_device_type
      return unless data.key?(:device_type)

      result[:device_type] = data.fetch(:device_type, {}).slice(:model, :slug)
    end

    def read_manufacturer
      return unless data.key?(:manufacturer)

      result[:manufacturer] = data.fetch(:manufacturer, {}).slice(:name, :slug)
    end

    def read_site
      return unless data.key?(:site)

      result[:site] = data.fetch(:site, {}).slice(:name, :slug)
    end
  end
end
