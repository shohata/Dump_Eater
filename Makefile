DUMP := byte.txt
IN := tdata.mem tkeep.mem tuser.mem tvalid.mem tlast.mem
SRC := tb_arp_reply.v tb_mac_filter.v tb_udp_echo_back.v tb_udp_echo_back_replacing_A_with_B.v tb_axis_broadcaster.v tb_axis_switch.v tb_path_through.v tb_stream_manager.v
EXE := ${SRC:.v=.out}
WAVE := ${SRC:.v=.vcd}
OUT := ${SRC:.v=.mem}

all: ${OUT};

%.v: ${IN};

%.out: %.v
	iverilog -Wall $^ -o $@

%.mem: %.out
	./$^

clean:
	${RM} ${IN} ${EXE} ${WAVE} ${OUT}

tdata.mem: ${DUMP}
	sed '$$a \\' $^ | python3 tdata.py | python3 4to1.py > $@

tkeep.mem: ${DUMP}
	sed '$$a \\' $^ | python3 tkeep.py | python3 4to1.py > $@

tuser.mem: ${DUMP}
	sed '$$a \\' $^ | python3 tuser.py | python3 2to1.py > $@

tvalid.mem: ${DUMP}
	sed '$$a \\' $^ | python3 tvalid.py  > $@

tlast.mem: ${DUMP}
	sed '$$a \\' $^ | python3 tlast.py  > $@
