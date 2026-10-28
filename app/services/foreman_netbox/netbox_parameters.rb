# frozen_string_literal: true

module ForemanNetbox
  # rubocop:disable Metrics/ClassLength
  class NetboxParameters
    UNKNOWN = 'Unknown'
    DEFAULT_INTERFACE_TYPE = 'virtual'
    CLUSTER_TYPES = {
      'Foreman::Model::Vmware': {
        name: 'VMware ESXi',
        slug: 'vmware-esxi',
      },
      'Foreman::Model::Libvirt': {
        name: 'Libvirt',
        slug: 'libvirt',
      },
      'ForemanFogProxmox::Proxmox': {
        name: 'Proxmox VE',
        slug: 'proxmox-ve',
      },
    }.freeze
    DEVICE_ROLE = {
      name: 'SERVER',
      slug: 'server',
    }.freeze

    def self.call(host)
      new(host).call
    end

    def initialize(host)
      @host = host
    end

    def call
      additional_params = host.netbox_virtual_machine? ? ForemanNetbox::NetboxFacet::VIRTUAL_MACHINE_PARAMS : ForemanNetbox::NetboxFacet::DEVICE_PARAMS

      (ForemanNetbox::NetboxFacet::COMMON_PARAMS + additional_params).map do |param|
        send(param)
      end.reduce({}, :merge)
    end

    private

    attr_accessor :host

    delegate :netbox_facet, to: :host
    delegate :cached_netbox_params, to: :netbox_facet

    def netbox_compute_attributes
      @netbox_compute_attributes ||= ForemanNetbox::ComputeAttributes.call(host)
    end

    # status and custom fields are only sent to Netbox if they are set by Foreman parameters
    def status_and_custom_fields
      {
        status: host.netbox_host_param(:status),
        custom_fields: host.netbox_custom_fields.symbolize_keys.presence,
      }
    end

    def tenant
      name = host.netbox_host_param(:tenant)

      {
        tenant: {
          name: name || host.owner&.netbox_tenant_name,
          slug: name&.parameterize || host.owner&.netbox_tenant_slug,
        },
      }
    end

    def device
      {
        device: {
          name: host.name,
          serial: host.facts.deep_symbolize_keys[:serialnumber].presence,
        }.merge(status_and_custom_fields).compact,
      }
    end

    def device_role
      name = host.netbox_host_param(:device_role)

      {
        device_role: name ? { name: name, slug: name.parameterize } : DEVICE_ROLE,
      }
    end

    def device_type
      model = host.netbox_host_param(:device_type) ||
              host.facts.deep_symbolize_keys[:productname] || host.facts.deep_symbolize_keys[:'dmi::product::name'] || UNKNOWN

      {
        device_type: {
          model: model,
          slug: model.parameterize,
        },
      }
    end

    def manufacturer
      name = host.netbox_host_param(:manufacturer) ||
             host.facts.deep_symbolize_keys[:manufacturer] || host.facts.deep_symbolize_keys[:'dmi::manufacturer'] || UNKNOWN
      # keep the slug of an existing manufacturer, which might have been found by its name
      cached_manufacturer = cached_netbox_params.fetch(:manufacturer, {})

      {
        manufacturer: {
          name: name,
          slug: (cached_manufacturer[:slug] if cached_manufacturer[:name] == name) || name.parameterize,
        },
      }
    end

    def site
      name = host.netbox_host_param(:site) || host.location&.netbox_site_name

      {
        site: {
          name: name,
          slug: name&.parameterize,
        },
      }
    end

    def interfaces
      {
        interfaces: host.interfaces.map do |interface|
          identifier = interface.identifier.present? && interface.identifier
          mac_address = interface.mac&.upcase

          {
            name: identifier || (mac_address && "Interface #{mac_address}"),
            mac_address: mac_address,
            # Netbox virtual machine interfaces do not have a type
            type: ({ value: DEFAULT_INTERFACE_TYPE } unless host.netbox_virtual_machine?),
          }.compact
        end,
      }
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def ip_addresses
      {
        ip_addresses: host.interfaces.map do |interface|
          [
            interface.ip && interface.subnet && "#{interface.ip}/#{interface.subnet.cidr}",
            interface.ip6 && interface.subnet6 && "#{interface.ip6}/#{interface.subnet6.cidr}",
          ].compact.map do |ip_address|
            identifier = interface.identifier.present? && interface.identifier
            mac_address = interface.mac&.upcase

            {
              address: ip_address,
              interface: {
                name: identifier || (mac_address && "Interface #{mac_address}"),
              },
            }
          end
        end.flatten,
      }
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def virtual_machine
      attributes = netbox_compute_attributes.slice(:vcpus, :memory)
      # with virtual disks, Netbox calculates the disk size of the virtual machine itself
      attributes[:disk] = netbox_compute_attributes[:disk] unless netbox_compute_attributes.key?(:virtual_disks)

      {
        virtual_machine: attributes.merge(name: host.name).merge(status_and_custom_fields).compact,
      }
    end

    def virtual_disks
      {
        virtual_disks: netbox_compute_attributes[:virtual_disks],
      }.compact
    end

    def cluster
      {
        cluster: {
          name: host.netbox_host_param(:cluster) || netbox_compute_attributes[:cluster],
        }.compact,
      }
    end

    def cluster_type
      name = host.netbox_host_param(:cluster_type)
      type = host.compute_resource&.type&.to_sym

      {
        cluster_type: name ? { name: name, slug: name.parameterize } : CLUSTER_TYPES.fetch(type, nil),
      }
    end
  end
  # rubocop:enable Metrics/ClassLength
end
