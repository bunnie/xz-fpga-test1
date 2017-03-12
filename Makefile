spitest.bin: spitest.v spitest.pcf spislave.v fifo.v spmi.v
	yosys -q -p "synth_ice40 -blif spitest.blif" spitest.v spislave.v fifo.v spmi.v
	arachne-pnr -d 1k -P vq100 -p spitest.pcf spitest.blif -o spitest.txt
	icebox_explain spitest.txt > spitest.ex
	icepack spitest.txt spitest.bin
	iceunpack spitest.bin spitest.asc
	icetime -mt -d hx1k spitest.asc

clean:
	rm -f spitest.blif spitest.txt spitest.ex spitest.bin
