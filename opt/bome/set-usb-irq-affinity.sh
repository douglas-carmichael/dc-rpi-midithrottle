#!/bin/bash

AFFINITY_MASK=2

grep -i 'xhci\|dwc2\|usb' /proc/interrupts | while read -r line; do
  IRQ=$(echo "$line" | awk '{print $1}' | sed 's/://')
  LABEL=$(echo "$line" | cut -d ':' -f 2- | xargs)
  echo "Setting IRQ $IRQ ($LABEL) to CPU affinity mask $AFFINITY_MASK"
  if ! echo $AFFINITY_MASK > /proc/irq/$IRQ/smp_affinity 2>/dev/null; then
    echo "Warning: Unable to set affinity for IRQ $IRQ ($LABEL)" >&2
  fi
done
