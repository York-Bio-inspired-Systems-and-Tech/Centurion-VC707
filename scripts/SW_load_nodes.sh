#!/bin/sh
bitstring_filename=$1
output_filename=$2
MMI_filename=$3
node_filename=$4

exec updatemem --force --meminfo $MMI_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --data $node_filename --proc node_0 --proc node_1 --proc node_2 --proc node_3 --proc node_4 --proc node_5 --proc node_6 --proc node_7 --proc node_8 --proc node_9 --proc node_10 --proc node_11 --proc node_12 --proc node_13 --proc node_14 --proc node_15 --proc node_16 --proc node_17 --proc node_18 --proc node_19 --proc node_20 --proc node_21 --proc node_22 --proc node_23 --proc node_24 --proc node_25 --proc node_26 --proc node_27 --proc node_28 --proc node_29 --proc node_30 --proc node_31 --proc node_32 --proc node_33 --proc node_34 --proc node_35 --proc node_36 --proc node_37 --proc node_38 --proc node_39 --proc node_40 --proc node_41 --proc node_42 --proc node_43 --proc node_44 --proc node_45 --proc node_46 --proc node_47 --proc node_48 --proc node_49 --proc node_50 --proc node_51 --proc node_52 --proc node_53 --proc node_54 --proc node_55 --proc node_56 --proc node_57 --proc node_58 --proc node_59 --proc node_60 --proc node_61 --proc node_62 --proc node_63 --bit $bitstring_filename --out $output_filename



#puts -nonewline "updatemem --force --meminfo centurion_VC707.mmi "
#for {set i 0} {$i < 64} {incr i} {
#       puts -nonewline "--data $node_filename "
#}
#for {set i 0} {$i < 64} {incr i} {
#       puts -nonewline "--proc node_${i} "
#}
#puts "--bit pcie_bd_wrapper.bit --out download.bit"

