This manual contains reference information about all of the configuration directives that can be included in a conf/server.xml file.

## The HTTP Connector
### Attributes
#### Common Attributes

Attribute | Description
------------ | -------------
port | The TCP port number on which this Connector will create a server socket and await incoming connections.

#### Standard Implementation
Attribute | Description
------------ | -------------
address | For servers with more than one IP address, this attribute specifies which address will be used for listening on the specified port. By default, this port will be used on all IP addresses associated with the server.