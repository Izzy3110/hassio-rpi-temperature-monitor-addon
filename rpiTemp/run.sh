#!/usr/bin/with-contenv bashio
CorF=$(cat options.json |jq -r '.CorF')
until false; do 
  read cpuRawTemp</sys/class/thermal/thermal_zone0/temp #read instead of cat fpr process reductionread cpuRawTemp</sys/class/thermal/thermal_zone0/temp #read instead of cat fpr process reduction
  cpuTemp=$(( $cpuRawTemp / 1000 ))
  # 
  memRawFree=$(cat /proc/meminfo | grep MemFree | awk '{ print $2 }')
  memRawTotal=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')

  memFree=$(( $memRawFree / 1000 ))
  memTotal=$(( $memRawTotal / 1000 ))

  memFreePercent=$(( $memRawFree / $memRawTotal ))

  #
  unit="C"
  memUnit="Mb"
  memUnitPercentage="%"
  #

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

  curl -s -X POST -H "Content-Type: application/json"  -H "Authorization: Bearer $HASSIO_TOKEN" -d '{"state": "'$cpuTemp'", "attributes":  {"unit_of_measurement": "°'$unit'", "icon": "mdi:temperature-celsius", "friendly_name": "CPU Temperature"}}' http://hassio/homeassistant/api/states/sensor.cpu_temperature 2>/dev/null
  curl -s -X POST -H "Content-Type: application/json"  -H "Authorization: Bearer $HASSIO_TOKEN" -d '{"state": "'$memFree'", "attributes":  {"unit_of_measurement": "'$memUnit'", "icon": "mdi:memory", "friendly_name": "Memory Free"}}' http://hassio/homeassistant/api/states/sensor.mem_free 2>/dev/null
  curl -s -X POST -H "Content-Type: application/json"  -H "Authorization: Bearer $HASSIO_TOKEN" -d '{"state": "'$memFreePercent'", "attributes":  {"unit_of_measurement": "'$memUnitPercentage'", "icon": "mdi:memory", "friendly_name": "Memory Free - Percentage"}}' http://hassio/homeassistant/api/states/sensor.mem_free_percentage 2>/dev/null
  sleep 30;
done
