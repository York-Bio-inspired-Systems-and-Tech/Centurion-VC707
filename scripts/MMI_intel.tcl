set num_cores 64
set RAM_len [expr {1024}]

puts "Building MMI file for ${num_cores} Intel Picoblazes"

set filename [get_property DIRECTORY [current_project]]
append filename "/centurion_VC707_intel.mmi"

# open the filename for writing
set fileout [open $filename "w"]

puts $fileout "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
puts $fileout "<MemInfo Version=\"1\" Minor=\"0\">\n"

for {set i 0} {$i < $num_cores} {incr i} {
    #puts "I inside first loop: $i"
        puts $fileout "<Processor Endianness=\"Little\" InstPath=\"intel_${i}\">"
        puts $fileout " <AddressSpace Name=\"local_BRAM\" Begin=\"0\" End=\"[expr {$RAM_len - 1}]\">"
        puts $fileout "  <BusBlock>"

        #fetch the BRAMs from the database
        set BRAM_list [get_cells -hierarchical -filter " PRIMITIVE_TYPE == BMEM.BRAM.RAMB18E1 && NAME =~  \"*intel_picoblaze_BRAM*\" && NAME =~  \"*PE_gen[$i]*\" "]

        puts "${BRAM_list}"
        #set BRAM_list_ordered [lsort -decreasing $BRAM_list]
        #puts "${BRAM_list_ordered}"

        for {set j 0} {$j < 1} {incr j} {
                #puts "${BRAM_inst}"
                set BRAM_inst [lindex $BRAM_list [expr [expr $j * 2] ]]

                set placement [lindex [split [get_sites -of_objects $BRAM_inst] {_} ] 1 ]
                set bmm_lsb 0
                set bmm_msb 17
                puts $fileout "   <BitLane MemType=\"RAMB32\" Placement=\"$placement\">"
                puts $fileout "     <DataWidth MSB=\"${bmm_msb}\" LSB=\"${bmm_lsb}\"/>"
                puts $fileout "     <AddressRange Begin=\"0\" End=\"[expr {$RAM_len}]\"/>"
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
