#!/bin/bash

color_col="0;31"
color_heading="0;33"
color_list="0;3"

cache_service=""

usage() {
  echo -n "$(basename $0) [SSH OPTIONS]
A simple bash script to output the status of a webserver.

Usage:
  $(basename $0)
    Display the status of the computer running the script.

  $(basename $0) foo@bar.com
    Open a SSH session to foo@bar.com and run the script there.

  $(basename $0) -i ~/.ssh/id_rsa foo@bar.com
    All options passed will be delegated to the ssh command.

  drush @production ssh < \$(which server-status)
    Run the command on a remote drush site alias.

Options:
  -h --help     Display this help and exit
";
}


colorize() {
  local heading="$(echo -e "$1" | head -1)"
  local content="$(echo -e "$1" | tail -n +2)"
  echo -e "\033[${color_col}m${heading}\033[0m"
  echo -e "\033[${color_list}m$content\033[0m"
}
heading() {
  local title=$1
  echo
  echo -e "\033[${color_heading}m$title"
  printf %80s |tr ' ' '='
  echo -e "\033[0m"
}
pad() {
  local length="$1"
  local left="$2"
  local right="${3}"
  local pad=$(printf '%0.1s' " "{1..40})
  echo -en "$left"
  printf '%*.*s' 0 $(( $length - ${#left} - ${#right})) "$pad"
  echo -en "$right"
}

########

cpu() {
  top -bn2 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}' | tail -1
}
process() {
  colorize "$(ps -eo pcpu,pmem,pid,user,args --columns 80 --sort -$1 | head -n 11)"
}
memory() {
  cat /proc/meminfo
}
ip() {
  dig +short myip.opendns.com @resolver1.opendns.com
}
general() {
  (
    local cpu_usage=$(cpu)
    local ip=$(ip)
    echo -e "$(memory)"
    echo -e "$(pad 27 "CPU:" "$cpu_usage")"
    echo -e "$(pad 27 "IP:" "${ip}")"
  ) | GREP_COLORS="mt=${color_col}:sl=${color_list}" \
      grep --color=auto '^[Mem|Swap]*[Free|Total]*[CPU]*[IP]*:'

  # echo "CPU:$(pad 20, "CPU:" "$usage")$usage"
    # separator="$(pad 40 "$service" "$status")"
}
zombie() {
  colorize "$(ps -eo stat,pcpu,pid,user,start,args --columns 80 | egrep '^STAT|Z' | grep -v egrep)"
}
disk() {
  colorize "$(df -h)"
}
ports() {
  local ports="$(netstat -lntup 2>/dev/null | awk '{ print gensub(/.*:([0-9]+)/, "\\1", "g", $4) "/" $1 "\t" gensub(/LISTEN/, "", "g", $6$7)  }' | tail -n +2)"
  colorize "$ports"
}

is_running() {
  local command="$1"
  local user="${2:-root}"
  [[ -z "$service_cache" ]] && service_cache="$(ps aux | tr -s ' ' | cut -d' ' -f 1,11-)"
  echo "$service_cache" | grep -E "^${user} ${command}" > /dev/null
  [[ $? -eq 0 ]] && echo "1" || echo "0"
}
services() {
  declare -A services
  services[apache]=$(is_running ".*(apache2|httpd)" "(apache|root)")
  services[sshd]=$(is_running "/usr/sbin/sshd")
  services[varnishd]=$(is_running "/usr/sbin/varnishd")
  services[pound]=$(is_running "/usr/sbin/pound")
  services[ufw]=$(is_running "/usr/sbin/ufw")
  services[cron]=$(is_running "(/usr/sbin/)?(crond|cron)")
  services[mysql]=$(is_running "/usr/.*/mysqld" "mysql")
  services[postfix]=$(is_running "/usr/.*/postfix")
  services[rsyslogd]=$(is_running ".*rsyslogd" "(root|syslog)")
  services[newrelic_daemon]=$(is_running "/usr/bin/newrelic-daemon")
  services[newrelic_sys]=$(is_running "/usr/sbin/nrsysmond" "newrelic")
  services[vnstat]=$(is_running "/usr/sbin/vnstat")
  local status=
  local running=

  for service in "${!services[@]}"; do
    running="${services[$service]}"
    ((running)) && status="\033[0;32mrunning\033[0m" || status="\033[0;31mdown\033[0m"
    echo -e "\033[${color_list}m$(pad 40 "$service" "$status")"
  done
}

case $1 in
  -h|--help) usage; exit 0 ;;
esac

if [[ $# -ne 0 ]]; then
  ssh $@ "bash -s" < $0
  exit
fi


heading "General"
general

heading "Disk space"
disk

heading "Services running"
services

heading "Open ports"
ports

heading "Top 10 | Process by CPU usage"
process "pcpu"

heading "Top 10 | Process by memory usage"
process "pmem"

heading "Zombie processes"
zombie
