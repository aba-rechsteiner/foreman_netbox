# frozen_string_literal: true

module ForemanNetbox
  class VirtualMachineContract < Dry::Validation::Contract
    params do
      optional(:tenant).hash(ForemanNetbox::Params::TenantParams)
      optional(:ip_addresses).array(ForemanNetbox::Params::IpAddressParams)
      optional(:interfaces).array(ForemanNetbox::Params::InterfaceParams)

      required(:virtual_machine).filled(:hash) do
        required(:name).filled(:string)
        optional(:vcpus).maybe(:integer)
        optional(:memory).maybe(:integer)
        optional(:disk).maybe(:integer)
        optional(:tags).array(:string)
        optional(:status).filled(:string)
        optional(:custom_fields).filled(:hash)
      end

      optional(:virtual_disks).array(:hash) do
        required(:name).filled(:string)
        required(:size).filled(:integer)
      end

      required(:cluster).filled(:hash) do
        required(:name).filled(:string)
        optional(:tags).array(:string)
      end

      required(:cluster_type).filled(:hash) do
        required(:name).filled(:string)
        required(:slug).filled(:string)
      end
    end
  end
end
