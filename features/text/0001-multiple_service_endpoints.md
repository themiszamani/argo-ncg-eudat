- Feature Name: Multiple service endpoints
- Start Date: 2016-02-29

# Summary
[summary]: #summary

Add support for multiple service types per host on NCG.


# Motivation
[motivation]: #motivation

There are some cases in which we need to assign nagios checks on multiple service types that are running on the same host.
Those checks might have different parameters for each combination of host/service_type and should be retrieved from GOCDB accordingly.
NCG should be able to handle such cases.


# Detailed design
[design]: #detailed-design

##### Use case: Support of multiple service types (even same ones) per endpoint with different attributes, extensions and service groups. E.g: 

```
service endpoint: host => epic.grnet.gr/service_type => b2handle.handle.api , URL => https://epic.grnet.gr/api/v2/handles/foo , service_group => B2HANDLE

service endpoint: host => epic.grnet.gr/service_type => b2handle.handle.api , URL => https://epic.grnet.gr/api/v2/handles/ , service_group => B2HANDLE
```

###### Use a dedicated service endpoint entry on GOCDB for each case.

- Separation of attributes, extensions, groups per endpoint using the primary_key of each entry. To retrieve the primary key we parse the XML response from the GOCDB API
and store the value of the XML element `PRIMARY_KEY`.

The following example is a representation of the structure we use to store the information we gather from the GOCDB for each service endpoint.

##### 1) Example of one host which belongs to two different service types:

```
'epic.grnet.gr' => {
  'HOSTNAME' => 'epic.grnet.gr',
  'SERVICES' => {
    'b2handle.handle.api' => {
      'ID' => {
        '25F8' => {
          'ATTRIBUTES' => {
            'b2handle.handle.api_URL' => {
              'VALUE' => 'https://epic.grnet.gr/api/v2/handles/'
            },
            'b2handle.handle.api_HOSTDN' => {
              'VALUE' => 'CERTIFICATE_DN'
            }
          },
          'EXTENSIONS' => {
             [...]
          }
        }
      }
    },
    'b2handle.handle.resolver' => {
      'ID' => {
        '45V3' => {
          'ATTRIBUTES' => {
            'b2handle.handle.api_URL' => {
              'VALUE' => 'https://epic.grnet.gr'
            }
          }
        }
      }
    }
  },
  'ADDRESS' => 'ip_address'
}
```

##### 2) Example of two same service endpoints (same pairs of host/service_type):

```
'epic.grnet.gr' => {
  'HOSTNAME' => 'epic.grnet.gr',
  'SERVICES' => {
    'b2handle.handle.api' => {
      'ID' => {
        '352DF8' => {
          'ATTRIBUTES' => {
            'b2handle.handle.api_URL' => {
              'VALUE' => 'https://epic.grnet.gr/api/v2/handles/'
            }
          }
        },
        'AFTV42' => {
          'ATTRIBUTES' => {
            'b2handle.handle.api_URL' => {
              'VALUE' => 'https://epic.grnet.gr/api/v2/handles/foo'
            }
          }
        }
      }
    }
  },
  'ADDRESS' => 'ip_address'
}
```

The service_type ID can be used also in the Nagios service configurations (as a unique indentifier in service_description) in order to distinguish multiple same service checks for a specific host. E.g:

```
define service{
        [...]
        host_name                       epic.grnet.gr
        servicegroups                   local, SITE_GRNET_b2handle.handle.api, SERVICE_b2handle.handle.api
        service_description             eu.eudat.b2handle.handle.api-TCP-ID --url https://epic.grnet.gr/api/v2/handles/
                _service_uri     epic.grnet.gr
        _metric_name     eu.eudat.b2handle.handle.api-TCP-ID
        _service_flavour     b2handle.handle.api
        [...]
}
define service{
        [...]
        host_name                       epic.grnet.gr
        servicegroups                   local, SITE_GRNET_b2handle.handle.api, SERVICE_b2handle.handle.api
        service_description             eu.eudat.b2handle.handle.api-TCP-ID --url https://epic.grnet.gr/api/v2/handles/foo
                _service_uri     epic.grnet.gr
        _metric_name     eu.eudat.b2handle.handle.api-TCP-ID
        _service_flavour     b2handle.handle.api
        [...]
}
```

In the example above we have two same service_endpoints (host/service_type) that we want to monitor by using one specific check with different parameters. In order to prevent Nagios handle this as a duplicate definition we include the ID in the `service_description` variable. The ID refers to the GOCDB entry with the specific parameter eg. assuming that we follow the example 2 we gave a few lines above the ID in the first definition would be `352DF8` whereas the second one whould be `AFTV42`.

# Drawbacks
[drawbacks]: #drawbacks

Multiple GOCDB entries in order to support complex scenarios. Might be difficult to maintain.


# Alternatives
[alternatives]: #alternatives

###### Use GOCDB's sub-endpoints feature per service endpoint.

Disadvantages:

- The way in which ncg parses the URL attribute is not sufficient. With the current implementation if there are more than one URL values (including the URL from “Grid Information” section) only the last one will be stored.
- Service groups can't be assigned per sub-endpoint.
- Difficult to distinguish metrics per service endpoint when there are also sub-endpoints with service types that are different from the parent entry. This has to do with the way we assign metrics to service types in POEM.

