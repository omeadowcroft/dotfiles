#!/usr/bin/env bash
# Pip-Boy stats for Waybar: prints {"text":..,"tooltip":..}
out() { printf '{"text":"%s","tooltip":"%s"}\n' "$1" "$2"; }
case "$1" in
  hp)  # CPU headroom = 100 - usage, sampled over 0.4 s
    read -r _ a b c d e f g h _ < /proc/stat; t1=$((a+b+c+d+e+f+g+h)); i1=$((d+e))
    sleep 0.4
    read -r _ a b c d e f g h _ < /proc/stat; t2=$((a+b+c+d+e+f+g+h)); i2=$((d+e))
    dt=$((t2-t1)); [ "$dt" -le 0 ] && dt=1
    hp=$(( 100 * (i2-i1) / dt ))
    out "HP $hp/100" "CPU headroom: $((100-hp))% in use" ;;
  ap)  # free RAM / total, GiB
    read -r tot av < <(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%d %d", t/1048576+0.5, a/1048576}' /proc/meminfo)
    out "AP $av/$tot" "RAM: ${av} GiB free of ${tot} GiB" ;;
  xp)  # disk used / total on /, GB
    read -r used size < <(df -BG --output=used,size / | awk 'NR==2{gsub("G","");print $1, $2}')
    out "XP $used/$size" "Disk /: ${used} GB used of ${size} GB" ;;
  rad) # GPU temperature
    src="GPU"
    t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
    if [ -z "$t" ]; then  # no NVIDIA (e.g. laptop): AMD GPU hwmon, then CPU package temp
      for f in /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input; do
        [ -r "$f" ] && { t=$(( $(cat "$f") / 1000 )); break; }
      done
    fi
    if [ -z "$t" ]; then
      src="CPU"
      for z in /sys/class/thermal/thermal_zone*; do
        case "$(cat "$z/type" 2>/dev/null)" in
          x86_pkg_temp|TCPU|k10temp|cpu*) t=$(( $(cat "$z/temp") / 1000 )); break ;;
        esac
      done
    fi
    [ -z "$t" ] && t="--"
    out "☢ RAD $t/100" "$src temperature: ${t}°C" ;;
esac
