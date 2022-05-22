/*  This file is part of JTPANG.
    JTPANG program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    ( at your option) any later version.

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
    input           flip,

    // CPU interface
    input           pal_bank,
    input           pal_cs,
    input           vram_msb,
    input           vram_cs,
    input           attr_cs,
    input           wr_n,
    input    [11:0] cpu_addr,
    input    [ 7:0] cpu_dout,
    output   [ 7:0] vram_dout,
    output   [ 7:0] attr_dout,
    output   [ 7:0] pal_dout,

    // DMA
    input           dma_go,
    input           busak_n,
    output          busrq,

    // ROM
    output   [17:0] char_addr,
    input    [31:0] char_data,
    output          char_cs,

    output   [16:0] obj_addr,
    input    [31:0] obj_data,
    output          obj_cs,
    input           obj_ok,

    output   [3:0]  red,
    output   [3:0]  green,
    output   [3:0]  blue,

    input    [3:0]  gfx_en
);

wire [ 7:0] obj_pxl;
wire [10:0] char_pxl;
wire [ 7:0] vf;
wire [ 8:0] dma_addr, v, h, hf;

assign vf = v[7:0]^{8{flip}};
assign hf = h^{9{flip}};

// Video uses the 48 MHz clock
jtframe_frac_cen #( .W( 2), .WC( 4)) u_cen48(
    .clk     ( clk          ),
    .n       ( 4'd1         ),
    .m       ( 4'd3         ),
    .cen     ( {pxl_cen, pxl2_cen} ),
    .cenb    (              )
);

jtframe_vtimer #(
    .HB_START ( 9'd383      ),
    .HB_END   ( 9'd511      ),
    .HS_START ( 9'd384+9'd64),
    .VB_END   ( 9'd271      ),  // 32 blank lines
    .VS_START ( 9'd260      )
) u_vtimer (
    .clk      ( clk         ),
    .pxl_cen  ( pxl_cen     ),
    .vdump    ( v           ),
    .vrender  (             ),
    .vrender1 (             ),
    .H        ( h           ),
    .Hinit    (             ),
    .Vinit    (             ),
    .LHBL     ( LHBL        ),
    .LVBL     ( LVBL        ),
    .HS       ( HS          ),
    .VS       ( VS          )
);

jtpang_char u_char (
    .rst      ( rst         ),
    .clk      ( clk         ),
    .clk24    ( clk24       ),
    .pxl_cen  ( pxl_cen     ),

    .h        ( h           ),
    .hf       ( hf          ),
    .vf       ( vf          ),
    .hs       ( HS          ),
    .flip     ( flip        ),

    .vram_msb ( vram_msb    ),
    .attr_cs  ( attr_cs     ),
    .vram_cs  ( vram_cs     ),
    .wr_n     ( wr_n        ),
    .cpu_addr ( cpu_addr    ),
    .cpu_dout ( cpu_dout    ),
    .vram_dout( vram_dout   ),
    .attr_dout( attr_dout   ),

    // DMA
    .busak_n  ( busak_n     ),
    .dma_addr ( dma_addr    ),

    .rom_addr ( char_addr   ),
    .rom_data ( char_data   ),
    .rom_cs   ( char_cs     ),
    .pxl      ( char_pxl    )
);

jtpang_obj u_obj (
    .rst      ( rst         ),
    .clk      ( clk         ),
    .pxl_cen  ( pxl_cen     ),
    .h        ( h           ),
    .hf       ( hf          ),
    .vf       ( vf[7:0]     ),
    .hs       ( HS          ),
    .flip     ( flip        ),

    .dma_go   ( dma_go      ),
    .busrq    ( busrq       ),
    .busak_n  ( busak_n     ),
    .dma_din  ( vram_dout   ),
    .dma_addr ( dma_addr    ),

    .rom_addr ( obj_addr    ), // TODO: Check connection ! Signal/port not matching : Expecting logic [16:0]  -- Found logic [17:0]
    .rom_data ( obj_data    ),
    .rom_cs   ( obj_cs      ),
    .rom_ok   ( obj_ok      ),
    .pxl      ( obj_pxl     )
);

jtpang_colmix u_colmix (
    .rst      ( rst         ),
    .clk      ( clk         ),
    .clk24    ( clk24       ),

    .pxl_cen  ( pxl_cen     ),
    .LHBL     ( LHBL        ),
    .LVBL     ( LVBL        ),

    .obj_pxl  ( obj_pxl     ),
    .ch_pxl   ( char_pxl    ),

    .pal_bank ( pal_bank    ),
    .pal_cs   ( pal_cs      ),
    .wr_n     ( wr_n        ),
    .cpu_addr ( cpu_addr[10:0] ),
    .cpu_dout ( cpu_dout    ),
    .pal_dout ( pal_dout    ),

    .red      ( red         ),
    .green    ( green       ),
    .blue     ( blue        )
);

endmodule