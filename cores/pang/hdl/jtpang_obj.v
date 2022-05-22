/*  This file is part of JTPANG.
    JTPANG program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTPANG program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTPANG.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 22-5-2022 */

module jtpang_obj(
    input              rst,
    input              clk,
    input              pxl_cen,

    input      [ 8:0]  h,
    input      [ 8:0]  hf,
    input      [ 7:0]  vf,
    input              hs,
    input              flip,

    // DMA
    input              dma_go,     // triggers the DMA
    output reg         busrq,      // active high
    input              busak_n,
    input       [ 7:0] dma_din,
    output reg  [ 8:0] dma_addr,

    output reg  [16:0] rom_addr,
    input       [31:0] rom_data,
    output reg         rom_cs,
    input              rom_ok,

    output      [ 7:0] pxl
);

reg  dma_go_l, dma_we;

// DMA transfer
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        busrq    <= 0;
        dma_we   <= 0;
        dma_go_l <= 0;
        dma_addr <= 0;
    end else begin
        dma_go_l <= dma_go;
        if( dma_go & ~dma_go ) begin
            busrq    <= 1;
            dma_we   <= 0;
            dma_addr <= 0;
        end
        if( busrq && !busak_n && pxl_cen ) begin
            dma_we <= 1;
            if( dma_we ) begin
                dma_addr <=  dma_addr + 1'd1;
                if( &dma_addr ) begin
                    busrq  <= 0;
                    dma_we <= 0;
                end
            end
        end
    end
end

// Line drawing, max 32 objects per line
// 512 ticks in a line / 16 pixels per obj = 2^5 = 32
// The original design must use an intermmediate
// buffer like GnG, but having a faster clock, makes
// it unnecessary.
// Table objects = 2^(9-2)= 2^7
reg         hs_l, scan_cen, scan_done;
reg  [ 6:0] obj_cnt;
reg  [ 4:0] drawn, dr_pxl;
reg  [ 1:0] sub_cnt;
reg  [ 8:0] dr_xpos, buf_addr;
reg  [ 7:0] dr_ypos, ypos, ydiff, buf_data;
wire [ 7:0] scan_dout;
wire [ 8:0] scan_addr;
reg  [ 3:0] dr_pal, dr_vsub, cur_pal;
reg  [10:0] dr_code;
reg  [31:0] pxl_data;
reg         match, dr_start, dr_busy, buf_we;

assign buf_data  = { cur_pal, pxl_data[3:0] };
assign scan_addr = { obj_cnt, sub_cnt };

always @* begin
    ydiff = (vf+8'd2) - dr_ypos;
    match = ydiff < 16;
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        hs_l    <= 0;
        scan_cen <= 0;
        scan_done <= 0;
        obj_cnt   <= 0;
        sub_cnt   <= 0;
        dr_code   <= 0;
        dr_xpos   <= 0;
        dr_ypos   <= 0;
        dr_vsub   <= 0;
        dr_start  <= 0;
        drawn     <= 0;
    end else begin
        hs_l     <= hs;
        scan_cen <= ~scan_cen;
        dr_start <= 0;
        if( !hs && hs_l ) begin
            obj_cnt   <= 0;
            sub_cnt   <= 0;
            drawn     <= 0;
            scan_done <= 0;
        end
        if( scan_done && scan_cen ) begin
            if( sub_cnt!=3 ) sub_cnt <= sub_cnt + 1'd1;
            case( sub_cnt )
                0: dr_code[7:0] <= scan_dout;
                1: begin
                    dr_code[10:8] <= scan_dout[7:5];
                    dr_xpos[8]    <= scan_dout[4];
                    dr_pal        <= scan_dout[3:0];
                end
                2: dr_ypos <= scan_dout;
                3: begin
                    dr_xpos[7:0] <= scan_dout;
                    dr_vsub <= ydiff[3:0] ^ {4{flip}};
                    if( !match || !dr_busy ) begin
                        { scan_done, obj_cnt, sub_cnt } <= { 1'b0, obj_cnt, sub_cnt } + 1'd1;
                        if( match ) begin
                            dr_start <= 1;
                            drawn    <= drawn + 5'd1;
                            if( drawn==31 ) scan_done <= 1;
                        end
                    end
                end
            endcase
        end
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        dr_busy  <= 0;
        cur_pal  <= 0;
        pxl_data <= 0;
    end else begin
        if( dr_busy ) begin
            if( rom_ok && dr_pxl[3:0]==0 ) begin
                pxl_data    <= rom_data;
                rom_addr[1] <= 1;
                buf_we      <= 1;
            end else begin
                pxl_data <= pxl_data >> 4;
                buf_addr <= buf_addr + 9'd1;
                dr_pxl   <= dr_pxl + 4'd1;
                if( dr_pxl[3:0]==0 ) begin
                    buf_we <= 0;
                    dr_busy <= !dr_pxl[4];
                end
            end
        end else if( dr_start ) begin
            dr_busy  <= 1;
            rom_addr <= { dr_code, dr_vsub, 2'b0 };
            rom_cs   <= 1;
            dr_pxl   <= 0;
            buf_addr <= dr_xpos;
            buf_we   <= 0;
            cur_pal  <= dr_pal;
        end
    end
end

// DMA buffer
jtframe_dual_ram #(.aw(9)) u_table (
    // CPU
    .clk0  ( clk        ),
    .data0 ( dma_din    ),
    .addr0 ( dma_addr   ),
    .we0   ( dma_we     ),
    .q0    (            ),
    // Scan
    .clk1  ( clk        ),
    .data1 ( 8'd0       ),
    .addr1 ( scan_addr  ),
    .we1   ( 1'd0       ),
    .q1    ( scan_dout  )
);

jtframe_obj_buffer #(
    .FLIP_OFFSET( 9'd383-9'd511 )
) u_line (
    .clk     ( clk          ),
    .LHBL    ( hs           ),
    .flip    ( flip         ),
    .wr_data ( buf_data     ),
    .wr_addr ( buf_addr     ),
    .we      ( buf_we       ),
    .rd_addr ( h            ),
    .rd      ( pxl_cen      ),
    .rd_data ( pxl          )
);

endmodule