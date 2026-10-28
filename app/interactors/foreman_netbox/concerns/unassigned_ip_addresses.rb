# frozen_string_literal: true

module ForemanNetbox
  module Concerns
    module UnassignedIpAddresses
      # Netbox rejects duplicate IP addresses in the global table, so an IP address that already exists
      # without assignment (e.g. reserved in Netbox or left over from a deleted interface) is reused.
      # Filtering without prefix length matches the address regardless of its prefix length.
      def find_unassigned_ip_address(address)
        ForemanNetbox::Api.client
                          .ipam
                          .ip_addresses
                          .filter(address: address.split('/').first)
                          .find { |ip_address| ip_address['vrf'].nil? && ip_address['assigned_object_id'].nil? }
      end
    end
  end
end
