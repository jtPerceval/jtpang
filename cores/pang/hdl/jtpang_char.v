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
    Date: 21-5-2022 */

// The object table is stored here too
// This is better than the way other CAPCOM
// hardware does it: to store it in the CPU RAM
// The benefit is that the DMA does not steal CPU
// time, but CHAR time during blank, so it's
// basically free
module jtpang_char(
    input           rst,
    input           clk,
    input           clk24,

    input   [ 8:0]  h,
    input   [ 8:0]  hf,
    input   [ 8:0]  vf,
    input           hs,
    input           flip,

    input           vram_msb,
    input           vram_cs,
    input           wr_n,
    input    [11:0] cpu_addr,
    input    [ 7:0] cpu_dout,
    output   [ 7:0] vram_dout,

    output   [17:0] rom_addr,
    input    [31:0] rom_data,
    output          rom_cs,

    output   [10:0] pxl
);

wire [ 7:0] code_dout, pal_dout;
wire        vram_we;
wire [12:0] scan_addr;
reg  [ 7:0] code_lsb;
reg  [31:0] pxl_data;
reg  [ 6:0] pal, nx_pal;
reg         hflip, nx_hflip;

assign vram_we   = vram_cs & ~wr_n;
assign scan_addr = { 1'b0, vf[7:3], hf[8:3], h[0] };
assign rom_cs    = ~hs;
assign pxl       = { pal, hflip ? pxl_data[31:28] : pxl_data[3:0] };

always @(posedge clk, posedge rst) begin
    if( rst ) begin
    end else if(pxl_cen) begin
        case( { hf[2:1], h[0] } )
            0: code_lsb <= code_dout;
            1: begin
                rom_addr <= { code_dout, code_lsb, vf[2:0], 1'b0 };
                { nx_hflip, nx_pal } <= att_out;
            end
        endcase
        if( {hf[2:1],h[0]}==1 ) begin
            pxl_data <= rom_data;
            { hflip, pal } <= { nx_hflip^~flip, nx_pal };
        end else
            pxl_data <= cur_hflip ? pxl_data << 4 : pxl_data >> 4;
    end
end

// Upper half = objects, lower half = tile map
jtframe_dual_ram #(.aw(13)) u_vram (
    // CPU
    .clk0  ( clk24      ),
    .data0 ( cpu_dout   ),
    .addr0 ( { vram_msb, cpu_addr } ),
    .we0   ( attr_we    ),
    .q0    ( attr_dout  ),
    // Scan
    .clk1  ( clk        ),
    .data1 ( 8'd0       ),
    .addr1 ( scan_addr  ),
    .we1   ( 1'd0       ),
    .q1    ( pal_dout   )
);

jtframe_dual_ram #(.aw(11)) u_attr (
    // CPU
    .clk0  ( clk24      ),
    .data0 ( cpu_dout   ),
    .addr0 ( cpu_addr[10:0]   ),
    .we0   ( vram_we    ),
    .q0    ( vram_dout  ),
    // Scan
    .clk1  ( clk        ),
    .data1 ( 8'd0       ),
    .addr1 ( scan_addr[11:1]  ),
    .we1   ( 1'd0       ),
    .q1    ( code_dout  )
);

endmodule