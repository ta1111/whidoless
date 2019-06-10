module sdcard_top
(
    input CLOCK_50,RESET,
	 output SD_NCS, 
	 output SD_CLK,
	 input SD_DOUT,
	 output SD_DI,
	 input [9:0]img_id,
	 input [9:0]block_id,
	 input r, // 拉高表示开始读，done了之后需要手动拉低。
	 output reg done, // 高电平表示已经读好了。
	 output reg[4095:0]data
);

    parameter SEC = 32'd24832;

    reg rd;
	 reg [7:0]dout;
	 reg dout_avail;
	 reg dout_taken;
	 reg [31:0]addr;

	 wire sd_error;
	 wire sd_busy;
	 wire [2:0]sd_error_code;
	 wire [1:0]sd_type;
	 wire [7:0]sd_fsm;
	 
	 always @(*) begin
	     addr = 32'd24832 + img_id * 32'd856 + block_id;
    end
	 
	 reg [9:0]count;
	 
	 always @(posedge CLOCK_50) begin
	     if (!RESET) begin
				rd <= 0;
				count <= 0;
				done <= 0;
				dout_taken <= 0;
				data <= 4096'b0;
		  end
		  else begin
		      if (done) begin
				    if (!r) begin
					     done <= 0;
					 end
				end
		      else if (rd) begin
				    if (!count[9]) begin
						 if (dout_taken) begin
							  dout_taken <= 0;
						 end
						 else if (dout_avail) begin
						     data[4095:4088] <= dout;
							  data[4087:0] <= data[4095:8];
						     count <= count + 1;
							  dout_taken <= 1;
						 end
					 end
					 else begin
							rd <= 0;
							count <= 0;
							dout_taken <= 0;
							done <= 1;
					 end
				end
				else if (r && sd_fsm == 8'h11) begin
			       rd <= 1;
				end
		  end
	 end

    sd_controller SD(
	     .cs(SD_NCS),
		  .mosi(SD_DI),
		  .miso(SD_DOUT),
		  .sclk(SD_CLK),
		  .card_present(1),
		  .card_write_prot(1),
		  .rd(rd),
		  .rd_multiple(0),
		  .dout(dout),
		  .dout_avail(dout_avail),
		  .dout_taken(dout_taken),
		  .wr(0),
		  .wr_multiple(0),
		  .din(8'b0),
		  .din_valid(0),
		  .din_taken(),
		  .addr(addr),
		  .erase_count(8'b0),
		  .sd_error(sd_error),
		  .sd_busy(sd_busy),
		  .sd_error_code(sd_error_code),
		  .reset(~RESET),
		  .clk(CLOCK_50),
		  .sd_type(sd_type),
		  .sd_fsm(sd_fsm)
	 );
				
endmodule
