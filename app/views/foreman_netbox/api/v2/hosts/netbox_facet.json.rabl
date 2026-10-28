# frozen_string_literal: true

child(@facet => :netbox_facet_attributes) do
  attributes :url, :synchronized_at, :synchronization_error
end
