## About fully qualified domain names (FQDNs)
A fully qualified domain name (FQDN) is the complete domain name for a specific computer, or host, on the Internet. The FQDN consists of two parts: the hostname and the domain name. For example, an FQDN for a hypothetical mail server might be `mymail.somecollege.edu`. The hostname is `mymail`, and the host is located within the domain `somecollege.edu`.

In this example, `.edu` is the top-level domain (TLD). This is similar to the root directory on a typical workstation, where all other directories (or folders) originate. (Within the `.edu` TLD, Indiana University Bloomington has been assigned the `indiana.edu` domain, and has authority to create subdomains within it.)

The same applies to web addresses. For example, `www.indiana.edu` is the FQDN on the web for IU. In this case, `www` is the name of the host in the `indiana.edu` domain.

When connecting to a host (using an SSH client, for example), you must specify the FQDN. The DNS server then resolves the hostname to its IP address by looking at its DNS table. The host is contacted and you receive a login prompt.
