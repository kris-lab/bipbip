copperegg_agents
================
Agent to collect server metrics and send them to the [CopperEgg RevealMetrics](http://copperegg.com/) platform.
Plugins for different metrics available in the `plugin/`-directory.
Will spawn a child process for every plugin and server you tell it to monitor.

Configure and run
-----------------
Pass the path to your configuration file to `copperegg_agents` using the `-c` command line argument.
```sh
copperegg_agents -c /etc/copperegg_agents/copperegg_agents.yml
```

The configuration file should list the services you want to collect for, and the servers for each of them, e.g.:
```yml
loglevel: INFO
copperegg:
  apikey: YOUR_APIKEY
  frequency: 15

services:
  -
    plugin: Memcached
    hostname: localhost
    port: 11211
  -
    plugin: Mysql
    hostname: localhost
    port: 3306
    username: root
    password: root
  -
    plugin: Gearman
    hostname: localhost
    port: 4730    
```

Include configuration
---------------------
In your configuration you can specify a directory to include service configurations from:
```
include: services.d/
```
This will include files from `/etc/copperegg_agents/services.d/` and load them into the `services` configuration.

You could then add a file `/etc/copperegg_agents/services.d/memcached.yml`:
```yml
plugin: Memcached
hostname: localhost
port: 11211
```
