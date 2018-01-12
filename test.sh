#!/bin/bash

for i in {ROOT_,BOOT_}{PART,LABEL,SUBVOL}; do
	echo $i
done                       #"ROOT_PART BOOT_PART ROOT_LABEL BOOT_LABEL ROOT_SUBVOL BOOT_SUBVOL
