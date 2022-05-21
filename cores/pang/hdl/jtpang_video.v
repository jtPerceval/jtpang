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

module jtpang_video(
    input           rst,
    input           clk,
    input           clk24,

    output          pxl2_cen,   // 16   MHz
    output          pxl_cen,    //  8   MHz
    output          LHBL,
    output          LVBL,
    output          HS,
    output          VS,

    // CPU interface
    input           pal_bank,
    input           pal_cs,
    input           wr_n,
    input    [10:0] cpu_addr,
    input    [ 7:0] cpu_dout,
    output   [ 7:0] pal_dout,

    output   [3:0]  red,
    output   [3:0]  green,
    output   [3:0]  blue,

    input    [3:0]  gfx_en
);

wire [7:0] obj_pxl;
wire [10:0] ch_pxl;


// Video uses the 48 MHz clock
jtframe_frac_cen #(.W(2), .WC(4)) u_cen48(
    .clk  ( clk    ),
    .n    ( 4'd1   ),
    .m    ( 4'd3   ),
    .cen  ( {pxl_cen, pxl2_cen} ),
    .cenb (        )
);

jtpang_colmix i_jtpang_colmix (
    .rst     (rst     ),
    .clk     (clk     ),
    .clk24   (clk24   ),

    .pxl_cen (pxl_cen ),
    .LHBL    (LHBL    ),
    .LVBL    (LVBL    ),

    .obj_pxl (obj_pxl ),
    .ch_pxl  (ch_pxl  ),

    .pal_bank(pal_bank),
    .pal_cs  (pal_cs  ),
    .wr_n    (wr_n    ),
    .cpu_addr(cpu_addr),
    .cpu_dout(cpu_dout),
    .pal_dout(pal_dout),

    .red     (red     ),
    .green   (green   ),
    .blue    (blue    )
);


endmodule