server-status.sh
================
A simple bash script to output the status of a web server (our web servers).

Displays:
- Memory Usage
- Swap Usage
- CPU Usage
- External IP
- Filesystem disk space
- Running services (relevant services)
- Open ports
- Top 10 processes by CPU usage
- Top 10 processes by RAM usage
- Zombie processes

### Installation

```sh
make install
```

### Usage

```
server-status [SSH OPTIONS]
A simple bash script to output the status of a webserver.

Usage:
  server-status
    Display the status of the computer running the script.

  server-status foo@bar.com
    Open a SSH session to foo@bar.com and run the script there.

  server-status -i ~/.ssh/id_rsa foo@bar.com
    All options passed will be delegated to the ssh command.

  drush @production ssh < $(which server-status)
    Run the command on a remote drush site alias.

Options:
  -h --help     Display this help and exit
```

![Screenshot](http://i.imgur.com/IdK4HI3.png?1)
