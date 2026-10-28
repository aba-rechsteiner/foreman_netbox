# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    scope '(:apiv)', module: :v2, defaults: { apiv: 'v2' }, apiv: /v2/, constraints: ApiConstraints.new(version: 2, default: true) do
      constraints(id: %r{[^/]+}) do
        resources :hosts, only: [] do
          member do
            put :netbox_sync
          end
        end
      end
    end
  end
end
