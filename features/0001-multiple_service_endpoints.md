- Feature Name: Multiple service endpoints
- Start Date: 2016-02-29

# Summary
[summary]: #summary

Add support for multiple service types per host on NCG.


# Motivation
[motivation]: #motivation

There are some cases in which we need to assign nagios checks on multiple service types that are running on the same host.
Those checks might have different parameters for each compination of host/service_type and should be retrieved from GOCDB accordingly.
NCG should be able to handle such cases.


# Detailed design
[design]: #detailed-design

##### Use case: Support of multiple service types (even same ones) per endpoint with different attributes, extensions and service groups. E.g: 

service endpoint: host => myhost.foo.gr/service_type => my_service_type_1 , URL => https://myhost.foo.gr/api/v2/pointer/1 , service_group => SERVICE1

service endpoint: host => myhost.foo.gr/service_type => my_service_type_1 , URL => https://myhost.foo.gr/api/v2/pointer/2 , service_group => SERVICE1_FOO

Use a dedicated service endpoint entry on GOCDB for each case

- Separation of attributes, extensions, groups per endpoint using the primary_key of each entry

- Ability to identify which service endpoint belongs to which service group. Same primary keys for a service group entry and a service endpoint.


##### Example of one host which belongs to two different service types:

```'myhost.foo.gr' => {
  'HOSTNAME' => 'myhost.foo.gr',
  'SERVICES' => {
    'myservice.foo' => {
      'ID' => {
        '25F8' => {
          'ATTRIBUTES' => {
            'myservice.foo_URL' => {
              'VALUE' => 'http://myhost.foo.gr:2811'
            },
            'myhost.foo.gr_HOSTDN' => {
              'VALUE' => 'CERTIFICATE_DN'
            }
          }
        }
      }
    },
    'myservice.foo2' => {
      'ID' => {
        '45V3' => {
          'ATTRIBUTES' => {
            'myservice.foo2_URL' => {
              'VALUE' => 'https://myhost.foo.gr:1247'
            }
          }
        }
      }
    }
  },
  'ADDRESS' => 'ip_address'
}
```
##### Example of two same service endpoints (same pairs of host/service_type):

```'myhost.foo.gr' => {
  'HOSTNAME' => 'myhost.foo.gr',
  'SERVICES' => {
    'myservice.foo' => {
      'ID' => {
        '352DF8' => {
          'ATTRIBUTES' => {
            'myservice.foo_URL' => {
              'VALUE' => 'https://myhost.foo.gr/api/v2/pointer/foo'
            }
          }
        },
        'AFTV42' => {
          'ATTRIBUTES' => {
            'myservice.foo_URL' => {
              'VALUE' => 'https://myhost.foo.gr/api/v2/pointer/'
            }
          }
        }
      }
    }
  },
  'ADDRESS' => 'ip_address'
}
```
# Drawbacks
[drawbacks]: #drawbacks

Multiple GOCDB entries in order to support complex scenarios. Might be difficult to maintain.


# Alternatives
[alternatives]: #alternatives

Use GOCDB's sub-endpoints feature per service endpoint

Disadvantages:

- The way in which ncg parses the URL attribute is not sufficient. With the current implementation if there are more than one URL values (including the URL from “Grid Information” section) only the last one will be stored.
- Service groups can't be assigned per sub-endpoint.
- Difficult to distinguish metrics per service endpoint when there are also sub-endpoints with service types that are different from the parent entry. This has to do with the way we assign metrics to service types in POEM.
