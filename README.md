# ForemanNetbox

[<img src="https://raw.githubusercontent.com/dm-drogeriemarkt/.github/refs/heads/main/assets/dmtech-open-source-badge.svg">](https://www.dmtech.de/)

This is a plugin for Foreman that introduces integration with [NetBox](https://netbox.readthedocs.io)

## Compatibility

| Foreman Version | Netbox Version | Plugin Version |
| --------------- | -------------- | -------------- |
| <3.13           | 2.8            | 1.0            |
| <3.13           | 2.11           | 1.1            |
| <3.13           | 3.3            | 1.2            |
| >=3.13          | 3.5            | 2.0            |
| >=5.0           | >=4.7          | 3.x            |

## Installation

See [How to Install a Plugin](https://theforeman.org/plugins/)
for how to install Foreman plugins.

The gem name is "foreman_netbox".

If your Foreman bundle uses Faraday < 2 (the Debian/Ubuntu packages pin `faraday < 2`), also add the `faraday_middleware` gem next to `foreman_netbox` in `bundler.d`, as netbox-client-ruby requires it with Faraday 1.

## Configuration

After installation of the plugin you can find its settings under Administer/Settings/Netbox tab:

| Setting                        | Description                                                                                  |
| ------------------------------ | -------------------------------------------------------------------------------------------- |
| `netbox_url`                   | URL where the Netbox UI is reachable, e.g. `https://netbox.example.com`                      |
| `netbox_api_url`               | URL where the Netbox API is reachable, only needed if it is not `<netbox_url>/api`           |
| `netbox_api_token`             | Netbox API token, see below                                                                  |
| `netbox_orchestration_enabled` | If enabled, every change of a Foreman host object will be synced with your Netbox instance   |
| `netbox_skip_site_update`      | Do not update the site of devices that already have a site in Netbox                         |
| `netbox_disk_base_unit`        | Megabytes per gigabyte for VM disk sizes, should match `DISK_BASE_UNIT` of Netbox            |
| `netbox_periodic_sync`         | Periodically synchronize hosts (disabled, hourly or daily), see below                        |

Netbox 4.5 introduced v2 API tokens. Enter them in the form `nbt_<key>.<token>`, which is the value Netbox shows after creating the token (without the `Bearer` prefix). Legacy v1 tokens still work, but are deprecated by Netbox and will be removed in Netbox 5.0. The token needs permissions to view, add, change and delete devices, device roles, device types, manufacturers, sites, interfaces, MAC addresses, IP addresses, tenants, tags, virtual machines, clusters, cluster types and virtual machine interfaces.

Hosts without a compute resource are synchronized as devices, hosts on VMware, Libvirt and Proxmox compute resources as virtual machines. The Netbox cluster of a virtual machine is the vSphere cluster for VMware and the name of the compute resource for Libvirt and Proxmox. Hosts on other compute resources can not be synchronized, the reason is shown in the Netbox status of the host.

Netbox stores virtual machine disk sizes in megabytes. The plugin converts the disk size from Foreman (gigabytes) using the `netbox_disk_base_unit` setting, which defaults to 1000 like `DISK_BASE_UNIT` in Netbox. Set it to 1024 if your Netbox uses `DISK_BASE_UNIT = 1024`.

The synchronization status of a host is shown in the Netbox card on the Details tab of the host details page (and in the Netbox tab of the legacy host page).

## Synchronization

Managed hosts are synchronized with Netbox:

* **On changes**: if `netbox_orchestration_enabled` is set, a host is synchronized when it is created, updated or deleted in Foreman (UI, API, Hammer) and its Netbox data changed. Fact uploads and changes of inherited parameters do not update the host itself, use the periodic synchronization for them.
* **Manually**: with the action *Synchronize with Netbox* in the menu of the host details page, which needs the permission `netbox_sync_hosts` (part of the Manager role, run `foreman-rake db:seed` after installing the plugin to add it), or via the API with `PUT /api/hosts/:id/netbox_sync`.
* **With the rake task** `foreman_netbox:sync`, e.g. after installing the plugin or changing the mapping:

  ```
  # all managed hosts
  foreman-rake foreman_netbox:sync
  # only hosts matching a Foreman search
  foreman-rake foreman_netbox:sync HOSTS='hostgroup = web'
  # only hosts with changes, hosts that were never synchronized and hosts that failed to synchronize
  foreman-rake foreman_netbox:sync ONLY_CHANGED=true
  ```

* **Periodically**: if `netbox_periodic_sync` is set to hourly or daily, the Foreman cron jobs (`foreman-rake cron:hourly` / `cron:daily`, installed by the Foreman packages) synchronize hosts with changes, hosts that were never synchronized and hosts that failed to synchronize.

## Mapping Foreman data to Netbox

The values sent to Netbox can be changed with Foreman parameters. Like all Foreman parameters they can be set globally, per organization, location, host group, operating system, domain, subnet or host, the most specific one wins. Parameter values can contain ERB (if the setting "Interpolate ERB in parameters" is enabled), e.g. `<%= @host.operatingsystem %>`.

| Netbox field                    | Default                                                            | Foreman parameter     |
| ------------------------------- | ------------------------------------------------------------------ | --------------------- |
| Tenant                          | Owner of the host                                                  | `netbox_tenant`       |
| Site (devices)                  | Location name, or the location parameter `netbox_site`             | `netbox_site`         |
| Device role (devices)           | `SERVER`                                                           | `netbox_device_role`  |
| Device type (devices)           | Fact `productname` or `dmi::product::name`                         | `netbox_device_type`  |
| Manufacturer (devices)          | Fact `manufacturer` or `dmi::manufacturer`                         | `netbox_manufacturer` |
| Cluster (virtual machines)      | vSphere cluster (VMware), compute resource name (Libvirt, Proxmox) | `netbox_cluster`      |
| Cluster type (virtual machines) | Depends on the compute resource type                               | `netbox_cluster_type` |
| Status                          | Not changed (Netbox default `active`)                              | `netbox_status`       |
| Custom field `<name>`           | Not changed                                                        | `netbox_cf_<name>`    |

Missing tenants, sites, device roles, device types, manufacturers, clusters and cluster types are created in Netbox. The status has to be a Netbox status value (e.g. `planned`, `staged`, `active`, `offline`), custom fields have to exist in Netbox.

If an IP address of a host already exists in Netbox without being assigned (e.g. reserved in Netbox), it is assigned to the interface of the host instead of creating a new one.

## Integration tests

The easiest way to start Netbox is to use [netbox-docker](https://github.com/netbox-community/netbox-docker). netbox-docker creates a v2 API token for the superuser if `SUPERUSER_API_KEY` (12 characters) and `SUPERUSER_API_TOKEN` are set, see [.github/workflows/foreman_plugin_netbox.yml](.github/workflows/foreman_plugin_netbox.yml). To run integration tests provide `FOREMAN_NETBOX_URL` and `FOREMAN_NETBOX_TOKEN` variables, eg.

```
$ FOREMAN_NETBOX_URL=http://0.0.0.0:8000 FOREMAN_NETBOX_TOKEN=nbt_0123456789ab.0123456789abcdef0123456789abcdef01234567 bundle exec rake test:foreman_netbox
```

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) 2019 dmTECH GmbH, [dmtech.de](https://www.dmtech.de/)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

