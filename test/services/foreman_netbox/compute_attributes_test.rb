# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanNetbox
  class ComputeAttributesTest < ActiveSupport::TestCase
    subject { ForemanNetbox::ComputeAttributes.call(host) }

    let(:compute_resource) { OpenStruct.new(type: compute_resource_type, name: 'compute-resource') }
    let(:host) do
      FactoryBot.build_stubbed(:host, :managed).tap do |host|
        host.stubs(:compute_resource).returns(compute_resource)
        host.stubs(:compute_object).returns(compute_object)
      end
    end

    setup do
      setup_default_netbox_settings
    end

    context 'with a VMware compute resource' do
      let(:compute_resource_type) { 'Foreman::Model::Vmware' }
      let(:compute_object) do
        OpenStruct.new(
          cpus: 2,
          memory_mb: 4096,
          volumes: [OpenStruct.new(name: 'Hard disk 1', size_gb: 20), OpenStruct.new(name: 'Hard disk 2', size_gb: 30)],
          cluster: 'vSphere Cluster'
        )
      end

      let(:virtual_disks) { [{ name: 'Hard disk 1', size: 20_000 }, { name: 'Hard disk 2', size: 30_000 }] }

      it { assert_equal({ vcpus: 2, memory: 4096, disk: 50_000, virtual_disks: virtual_disks, cluster: 'vSphere Cluster' }, subject) }

      context 'when the Netbox disk base unit is 1024' do
        setup do
          Setting[:netbox_disk_base_unit] = 1024
        end

        it { assert_equal 51_200, subject[:disk] }
        it { assert_equal [20_480, 30_720], subject[:virtual_disks].pluck(:size) }
      end
    end

    context 'with a Libvirt compute resource' do
      let(:compute_resource_type) { 'Foreman::Model::Libvirt' }
      let(:compute_object) do
        OpenStruct.new(
          cpus: 4,
          memory_size: 8_388_608, # KiB
          volumes: [OpenStruct.new(name: 'vm-disk1.qcow2', capacity: 40), OpenStruct.new(name: 'vm-disk2.qcow2', capacity: 10)] # GB
        )
      end

      it do
        assert_equal({ vcpus: 4, memory: 8192, disk: 50_000, cluster: 'compute-resource',
                       virtual_disks: [{ name: 'vm-disk1.qcow2', size: 40_000 }, { name: 'vm-disk2.qcow2', size: 10_000 }] }, subject)
      end
    end

    context 'with a Proxmox compute resource' do
      let(:compute_resource_type) { 'ForemanFogProxmox::Proxmox' }
      let(:compute_object) do
        OpenStruct.new(
          cpus: 2,
          maxmem: 2_147_483_648, # bytes
          volumes: [
            stub(id: 'scsi0', size: '32', hard_disk?: true),
            stub(id: 'scsi1', size: '1T', hard_disk?: true),
            stub(size: nil, hard_disk?: false), # cdrom
          ]
        )
      end

      it do
        assert_equal({ vcpus: 2, memory: 2048, disk: 1_056_000, cluster: 'compute-resource',
                       virtual_disks: [{ name: 'scsi0', size: 32_000 }, { name: 'scsi1', size: 1_024_000 }] }, subject)
      end
    end

    context 'with volumes without or with the same name' do
      let(:compute_resource_type) { 'Foreman::Model::Vmware' }
      let(:compute_object) do
        OpenStruct.new(volumes: [OpenStruct.new(name: 'disk', size_gb: 1), OpenStruct.new(name: 'disk', size_gb: 2), OpenStruct.new(size_gb: 3)])
      end

      it 'makes the names of the virtual disks unique' do
        assert_equal ['disk', 'disk (2)', 'Disk 3'], subject[:virtual_disks].pluck(:name)
      end
    end

    context 'without volumes' do
      let(:compute_resource_type) { 'Foreman::Model::Vmware' }
      let(:compute_object) { OpenStruct.new(cpus: 1, volumes: []) }

      it { assert_equal({ vcpus: 1, virtual_disks: [] }, subject) }
    end

    context 'with an unsupported compute resource' do
      let(:compute_resource_type) { 'Foreman::Model::EC2' }
      let(:compute_object) { OpenStruct.new(flavor_id: 't3.micro') }

      it { assert_empty subject }
    end

    context 'when the compute object does not match the compute resource type' do
      let(:compute_resource_type) { 'Foreman::Model::Vmware' }
      let(:compute_object) do
        Class.new do
          def cpus
            2
          end
        end.new
      end

      it 'does not raise an error' do
        assert_empty subject
      end
    end

    context 'when the compute object can not be loaded' do
      let(:compute_resource_type) { 'Foreman::Model::Libvirt' }
      let(:compute_object) { nil }

      setup do
        host.stubs(:compute_object).raises(StandardError, 'Connection refused')
      end

      it 'does not raise an error' do
        assert_empty subject
      end
    end
  end
end
