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

module jtpang_colmix(
    input             rst,
    input             clk,
    input             clk24,

    input             pxl_cen,
    input             LHBL,
    input             LVBL,

    input      [ 7:0] obj_pxl,
    input      [10:0] ch_pxl,

    input             pal_bank,
    input             pal_cs,
    input             wr_n,
    input      [10:0] cpu_addr,
    input      [ 7:0] cpu_dout,
    output     [ 7:0] pal_dout,

    output reg [ 3:0] red,
    output reg [ 3:0] green,
    output reg [ 3:0] blue
);

reg  [10:0] pal_a;
wire [ 7:0] col_half;
reg         half;
reg  [ 3:0] nr,ng,nb;
wire        obj_blank, pal_we;

assign pal_we    = pal_cs & ~wr_n;
assign obj_blank = &obj_pxl[3:0];

always @(posedge clk) begin
    half <= ~half;
    if( !LVBL ) begin
        { red, green, blue } <= 0;
    end else begin
        if( pxl_cen ) begin
            half <= 0;
            { red, green, blue } <= { nr, ng, nb };
            pal_a <= obj_blank ? ch_pxl : { 3'h7, obj_pxl };
        end
        if( half )
            { ng, nb } <= col_half;
        else
            nr <= col_half[3:0];
    end
end

jtframe_dual_ram #(.aw(12)) u_dual_ram (
    // CPU
    .clk0  ( clk24      ),
    .data0 ( cpu_dout   ),
    .addr0 ( { cpu_addr[0], pal_bank, cpu_addr[10:1] } ),
    .we0   ( pal_we     ),
    .q0    ( pal_dout   ),
    // video
    .clk1  ( clk        ),
    .data1 ( 8'd0       ),
    .addr1 ( { half, pal_a } ),
    .we1   ( 1'b0       ),
    .q1    ( col_half   )
);

endmodule