# frozen_string_literal: true

module ForemanNetbox
  # Reads the virtual machine attributes for Netbox (vcpus, memory in MB, disk in MB, virtual disks and cluster)
  # from the compute object of a host, every compute resource provider has its own representation of them.
  class ComputeAttributes
    BYTES_PER_MEGABYTE = 1024**2
    BYTES_PER_GIGABYTE = 1024**3
    SIZE_UNITS = %w[K M G T P].freeze

    def self.call(host)
      new(host).call
    end

    def initialize(host)
      @host = host
    end

    def call
      compute_object = host.compute_object
      return {} unless compute_object

      attributes = case host.compute_resource&.type
                   when 'Foreman::Model::Vmware' then vmware(compute_object)
                   when 'Foreman::Model::Libvirt' then libvirt(compute_object)
                   when 'ForemanFogProxmox::Proxmox' then proxmox(compute_object)
                   else {}
                   end

      volumes = attributes.delete(:volumes)
      attributes.merge!(disks(volumes)) if volumes
      attributes.compact
    rescue StandardError => e
      # a host must still be saveable if its compute object can not be read
      ::Foreman::Logging.logger('foreman_netbox/import')
                        .warn("Could not read the compute attributes of #{host.name} for Netbox: #{e}")
      {}
    end

    private

    attr_reader :host

    # Netbox stores disk sizes in megabytes, the names of virtual disks have to be unique per virtual machine
    def disks(volumes)
      base_unit = Setting[:netbox_disk_base_unit]
      names = Hash.new(0)
      virtual_disks = volumes.each_with_index.map do |volume, index|
        name = volume[:name].presence || "Disk #{index + 1}"
        names[name] += 1
        name = "#{name} (#{names[name]})" if names[name] > 1

        { name: name, size: volume[:size_gb].to_i * base_unit }
      end

      {
        disk: (virtual_disks.sum { |virtual_disk| virtual_disk[:size] } if virtual_disks.any?),
        virtual_disks: virtual_disks,
      }
    end

    def vmware(server)
      {
        vcpus: server.cpus,
        memory: server.memory_mb,
        volumes: server.volumes&.map { |volume| { name: volume.name, size_gb: volume.size_gb } },
        cluster: server.cluster,
      }
    end

    # fog-libvirt reports the memory in KiB and the volume capacity in GB
    def libvirt(server)
      {
        vcpus: server.cpus,
        memory: server.memory_size && (server.memory_size / 1024),
        volumes: server.volumes&.map { |volume| { name: volume.name, size_gb: volume.capacity.to_i } },
        cluster: host.compute_resource.name,
      }
    end

    # fog-proxmox reports the memory in bytes and disk sizes either in GB or with a unit, e.g. '512M'
    def proxmox(server)
      {
        vcpus: server.cpus,
        memory: server.maxmem && (server.maxmem.to_i / BYTES_PER_MEGABYTE),
        volumes: server.volumes&.select(&:hard_disk?)&.map { |disk| { name: disk.id, size_gb: proxmox_disk_size_gb(disk.size) } },
        cluster: host.compute_resource.name,
      }
    end

    def proxmox_disk_size_gb(size)
      value, unit = size.to_s.match(/\A(\d+)([KMGTP]?)\z/)&.captures
      return 0 unless value
      return value.to_i if unit.empty?

      value.to_i * (1024**(SIZE_UNITS.index(unit) + 1)) / BYTES_PER_GIGABYTE
    end
  end
end
