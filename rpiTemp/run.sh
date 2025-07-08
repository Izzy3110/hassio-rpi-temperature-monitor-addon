#!/usr/bin/with-contenv bashio
CorF=$(cat options.json |jq -r '.CorF')
unit="C"
memUnit="Mb"
memUnitPercentage="%"

until false; do 

  read cpuRawTemp</sys/class/thermal/thermal_zone0/temp #read instead of cat fpr process reductionread cpuRawTemp</sys/class/thermal/thermal_zone0/temp #read instead of cat fpr process reduction
  
  # 
  # memRawFree=$(cat /proc/meminfo | grep MemFree | awk '{ print $2 }')
  memRawFree=$(grep MemAvailable /proc/meminfo | awk '{ print $2 }')
  memRawTotal=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')

  uptime_raw=$(awk '{print $1}' /proc/uptime)
  uptime_sec=${uptime_raw%.*}
  
  days=$(( uptime_sec/60/60/24 ))
  hours=$(( (uptime_sec/60/60)%24 ))
  minutes=$(( (uptime_sec/60)%60 ))
  seconds=$(( uptime_sec%60 ))
  
  cpuTemp=$(( $cpuRawTemp / 1000 ))

  memFree=$(( $memRawFree / 1000 ))
  memTotal=$(( $memRawTotal / 1000 ))
  memFreePercent=$(awk "BEGIN {printf \"%.2f\", ($memRawFree/$memRawTotal)*100}")

  if [ $CorF == "F" ]; then
    cpuTemp=$(( ( $cpuTemp *  9/5 ) + 32 ));
    unit="F"
  fi

  echo "Current CPU Temperature $cpuTemp °$unit"
  echo "Current Mem Free        $memFree $memUnit"
  echo "Current Mem Free (perc) $memFreePercent $memUnitPercentage"
  echo "Raw Values:"
  echo " - free                 $memRawFree Kb"
  echo " - total                $memRawTotal Kb"
  echo ""
  echo "Uptime: ${days}d ${hours}h ${minutes}m ${seconds}s"

  curl -s -X POST -H "Content-Type: application/json"  -H "Authorization: Bearer $HASSIO_TOKEN" -d '{"state": "'$cpuTemp'", "attributes":  {"unit_of_measurement": "°'$unit'", "icon": "mdi:temperature-celsius", "friendly_name": "CPU Temperature"}}' http://hassio/homeassistant/api/states/sensor.cpu_temperature 2>/dev/null
  curl -s -X POST -H "Content-Type: application/json"  -H "Authorization: Bearer $HASSIO_TOKEN" -d '{"state": "'$memFree'", "attributes":  {"unit_of_measurement": "'$memUnit'", "icon": "mdi:memory", "friendly_name": "Memory Free"}}' http://hassio/homeassistant/api/states/sensor.mem_free 2>/dev/null
  curl -s -X POST -H "Content-Type: application/json"  -H "Authorization: Bearer $HASSIO_TOKEN" -d '{"state": "'$memFreePercent'", "attributes":  {"unit_of_measurement": "'$memUnitPercentage'", "icon": "mdi:memory", "friendly_name": "Memory Free - Percentage"}}' http://hassio/homeassistant/api/states/sensor.mem_free_percentage 2>/dev/null
  sleep 30;
done
