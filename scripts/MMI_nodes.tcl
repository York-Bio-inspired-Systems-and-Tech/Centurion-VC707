set num_cores 64
set RAM_len [expr {32 * 1024}]
set RAM_num_per_core 8
set RAM_d_width {32 / ${RAM_num_per_core}}

puts "Building MMI file for ${num_cores} cores"

set filename [get_property DIRECTORY [current_project]]
append filename "/centurion_VC707_nodes.mmi"

# open the filename for writing
set fileout [open $filename "w"]

puts $fileout "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
puts $fileout "<MemInfo Version=\"1\" Minor=\"0\">\n"

for {set i 0} {$i < $num_cores} {incr i} {
    #puts "I inside first loop: $i"
        puts $fileout "<Processor Endianness=\"Little\" InstPath=\"node_${i}\">"
        puts $fileout " <AddressSpace Name=\"local_BRAM\" Begin=\"0\" End=\"[expr {$RAM_len - 1}]\">"
        puts $fileout "  <BusBlock>"

        #fetch the BRAMs from the database
        set BRAM_list [get_cells -hierarchical -filter " PRIMITIVE_TYPE == BMEM.BRAM.RAMB36E1 && NAME =~  \"*mcs_node_inst*\" && NAME =~  \"*PE_gen[$i]*\" "]

        #puts "${BRAM_list}"
        #set BRAM_list_ordered [lsort -decreasing $BRAM_list]
        #puts "${BRAM_list_ordered}"

        for {set j 0} {$j < 4} {incr j} {
                #puts "${BRAM_inst}"
                set BRAM_inst [lindex $BRAM_list [expr [expr $j * 2] +1]]

                set placement [lindex [split [get_sites -of_objects $BRAM_inst] {_} ] 1 ]
                set bmm_lsb [expr [expr [expr $j * 2] + 1] * $RAM_d_width]
                set bmm_msb [expr $bmm_lsb + [expr $RAM_d_width -1]]
                puts $fileout "   <BitLane MemType=\"RAMB32\" Placement=\"$placement\">"
                puts $fileout "     <DataWidth MSB=\"${bmm_msb}\" LSB=\"${bmm_lsb}\"/>"
                puts $fileout "     <AddressRange Begin=\"0\" End=\"[expr {$RAM_len / 4}]\"/>"
                puts $fileout "     <Parity ON=\"false\" NumBits=\"0\"/>"
                puts $fileout "   </BitLane>"

                set BRAM_inst [lindex $BRAM_list [expr $j * 2]]
                set placement [lindex [split [get_sites -of_objects $BRAM_inst] {_} ] 1 ]
                set bmm_lsb [expr [expr $j * 2] * $RAM_d_width]
                set bmm_msb [expr $bmm_lsb + [expr $RAM_d_width -1]]
                puts $fileout "   <BitLane MemType=\"RAMB32\" Placement=\"$placement\">"
                puts $fileout "     <DataWidth MSB=\"${bmm_msb}\" LSB=\"${bmm_lsb}\"/>"
                puts $fileout "     <AddressRange Begin=\"0\" End=\"[expr {$RAM_len / 4}]\"/>"
                puts $fileout "     <Parity ON=\"false\" NumBits=\"0\"/>"
                puts $fileout "   </BitLane>"

        }

        puts $fileout "  </BusBlock>"
        puts $fileout " </AddressSpace>"
        puts $fileout "</Processor>"
        puts $fileout "\n\n"
}

puts $fileout "<Config>"
puts $fileout "  <Option Name=\"Part\" Val=\"[get_property PART [current_project ]]\"/>"
puts $fileout "</Config>"
puts $fileout "</MemInfo>"
close $fileout
