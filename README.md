
# dockerapp_adrapi

This module installs the ADRAPI (Active Directory Rest API) using the docker and the dockerapp series structure.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with dockerapp_adrapi](#setup)
    * [What dockerapp_adrapi affects](#what-dockerapp_adrapi-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with dockerapp_adrapi](#beginning-with-dockerapp_adrapi)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This module installs the ADRAPI (Active Directory Rest API) using the docker and the dockerapp series structure.

## Setup

### What dockerapp_adrapi affects **OPTIONAL**

This module installs docker and depends on stdlib. It also creates a series of directories under /srv


### Setup Requirements **OPTIONAL**

This module depends on the following modules:

- dockerapp
- stdlib
- concat

### Beginning with dockerapp_adrapi


## Usage

The basic use is 

```
include dockerapp_adrapi 
````

All the parameters are described in [doc/REFERENCES.md](https://github.com/ffquintella/puppet-dockerapp_adrapi/blob/master/doc/REFERENCES.md)


## Limitations

TBD

## Development

We try to keep our modules as tested as possible and follow the lint sugestion. So before submitting any pull request, please run the unit tests and validation


