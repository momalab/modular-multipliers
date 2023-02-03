simSetSimulator "-vcssv" -exec "./vcs_out/simv" -args " " -uvmDebug on
debImport "-i" "-simflow" "-dbdir" "./vcs_out/simv.daidir"
srcTBInvokeSim
debExit
Window
verdiDockWidgetMaximize -dock windowDock_nWave_3
verdiDockWidgetRestore -dock windowDock_nWave_3
srcHBSelect "montgomery_mul_tb.montgomery_mul" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "montgomery_mul_tb.montgomery_mul"
wvRenameGroup -win $_nWave3 {G1} {montgomery_mul}
wvAddSignal -win $_nWave3 "/montgomery_mul_tb/montgomery_mul/clk" \
           "/montgomery_mul_tb/montgomery_mul/rst_n" \
           "/montgomery_mul_tb/montgomery_mul/enable_p" \
           "/montgomery_mul_tb/montgomery_mul/a\[127:0\]" \
           "/montgomery_mul_tb/montgomery_mul/b\[127:0\]" \
           "/montgomery_mul_tb/montgomery_mul/m\[127:0\]" \
           "/montgomery_mul_tb/montgomery_mul/m_size\[9:0\]" \
           "/montgomery_mul_tb/montgomery_mul/y\[127:0\]" \
           "/montgomery_mul_tb/montgomery_mul/done_irq_p"
wvSetPosition -win $_nWave3 {("montgomery_mul" 0)}
wvSetPosition -win $_nWave3 {("montgomery_mul" 9)}
wvSetPosition -win $_nWave3 {("montgomery_mul" 9)}
wvGetSignalOpen -win $_nWave3
wvGetSignalSetScope -win $_nWave3 "/montgomery_mul_tb"
wvGetSignalSetScope -win $_nWave3 "/montgomery_mul_tb/montgomery_mul"
wvSetPosition -win $_nWave3 {("montgomery_mul" 34)}
wvSetPosition -win $_nWave3 {("montgomery_mul" 34)}
wvAddSignal -win $_nWave3 -clear
wvAddSignal -win $_nWave3 -group {"montgomery_mul" \
{/montgomery_mul_tb/montgomery_mul/clk} \
{/montgomery_mul_tb/montgomery_mul/rst_n} \
{/montgomery_mul_tb/montgomery_mul/enable_p} \
{/montgomery_mul_tb/montgomery_mul/a\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/b\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/m\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/m_size\[9:0\]} \
{/montgomery_mul_tb/montgomery_mul/y\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/done_irq_p} \
{/montgomery_mul_tb/montgomery_mul/a\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/a_loc\[129:0\]} \
{/montgomery_mul_tb/montgomery_mul/b\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/b_loc_red\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/b_loc_red_2\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/bxn\[1:1\]} \
{/montgomery_mul_tb/montgomery_mul/bxn_all\[255:0\]} \
{/montgomery_mul_tb/montgomery_mul/clk} \
{/montgomery_mul_tb/montgomery_mul/done_irq_p} \
{/montgomery_mul_tb/montgomery_mul/done_irq_p_loc} \
{/montgomery_mul_tb/montgomery_mul/done_irq_p_loc_d} \
{/montgomery_mul_tb/montgomery_mul/enable_p} \
{/montgomery_mul_tb/montgomery_mul/j\[31:0\]} \
{/montgomery_mul_tb/montgomery_mul/m\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/m_size\[9:0\]} \
{/montgomery_mul_tb/montgomery_mul/mxn\[0:1\]} \
{/montgomery_mul_tb/montgomery_mul/mxn_done} \
{/montgomery_mul_tb/montgomery_mul/rst_n} \
{/montgomery_mul_tb/montgomery_mul/y\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/y_1\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/y_loc\[128:0\]} \
{/montgomery_mul_tb/montgomery_mul/y_loc_accum\[129:0\]} \
{/montgomery_mul_tb/montgomery_mul/y_loc_red\[127:0\]} \
{/montgomery_mul_tb/montgomery_mul/yxn\[0:1\]} \
{/montgomery_mul_tb/montgomery_mul/yxn_done_1} \
}
wvAddSignal -win $_nWave3 -group {"G2" \
}
wvSelectSignal -win $_nWave3 {( "montgomery_mul" 10 11 12 13 14 15 16 17 18 19 \
           20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 )} 
wvSetPosition -win $_nWave3 {("montgomery_mul" 34)}
srcTBRunSim
wvGetSignalClose -win $_nWave3
verdiDockWidgetMaximize -dock windowDock_nWave_3
srcTBSimBreak
wvZoomAll -win $_nWave3
wvZoomAll -win $_nWave3
wvZoomAll -win $_nWave3
wvZoomAll -win $_nWave3
wvZoomAll -win $_nWave3
wvZoomAll -win $_nWave3
wvSetCursor -win $_nWave3 50333081814.260872 -snap {("montgomery_mul" 12)}
debExit
