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

module jtpang_game(
    input           rst,
    input           clk,
    input           rst24,
    input           clk24,
    output          pxl2_cen,   // 12   MHz
    output          pxl_cen,    //  6   MHz
    output   [3:0]  red,
    output   [3:0]  green,
    output   [3:0]  blue,
    output          LHBL,
    output          LVBL,
    output          HS,
    output          VS,
    // cabinet I/O
    input   [ 1:0]  start_button,
    input   [ 1:0]  coin_input,
    input   [ 8:0]  joystick1,
    input   [ 8:0]  joystick2,

    // SDRAM interface
    input           downloading,
    output          dwnld_busy,

    // Bank 0: allows R/W
    output   [21:0] ba0_addr,
    output   [21:0] ba1_addr,
    output   [21:0] ba2_addr,
    output   [21:0] ba3_addr,
    output   [ 3:0] ba_rd,
    input    [ 3:0] ba_ack,
    input    [ 3:0] ba_dst,
    input    [ 3:0] ba_dok,
    input    [ 3:0] ba_rdy,

    input    [15:0] data_read,

    // RAM/ROM LOAD
    input   [24:0]  ioctl_addr,
    input   [ 7:0]  ioctl_dout,
    input           ioctl_wr,
    output  [21:0]  prog_addr,
    output  [15:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output  [ 1:0]  prog_ba,
    output          prog_we,
    output          prog_rd,
    input           prog_ack,
    input           prog_dok,
    input           prog_dst,
    input           prog_rdy,
    // DIP switches
    input   [31:0]  status,
    input   [31:0]  dipsw,
    input           service,
    input           dip_pause,
    output          dip_flip,
    input           dip_test,
    input   [ 1:0]  dip_fxlevel, // Not a DIP on the original PCB
    // Sound output
    output  signed [15:0] snd,
    output          sample,
    output          game_led,
    input           enable_psg,
    input           enable_fm,
    // Debug
    input   [3:0]   gfx_en,
    input   [7:0]   debug_bus,
    output  [7:0]   debug_view
);

wire [3:0] n;
wire [3:0] m;
wire [3:0] cen24;
wire       pcm_cen, fm_cen, cpu_cen;

assign { fm_cen, cpu_cen } = cen[1:0];
assign pcm_cen = cen[3];

// CPU and sound use the 24 MHz clock
jtframe_frac_cen #(.W(4), .WC(4)) u_cen24(
    .clk  ( clk24  ),
    .n    ( 4'd1   ),
    .m    ( 4'd3   ),
    .cen  ( cen24  ),
    .cenb (        )
);

// CPU bus
wire [7 :0] cpu_dout, pcm_dout, fm_dout;
wire        fm_cs, pcm_cem, // pcm_cs reserved for SDRAM
            wr_n;
// SDRAM
wire [17:0] pcm_addr;
wire [ 7:0] pcm_data;
wire        pcm_ok;

jtpang_snd u_snd (
    .rst        ( rst24         ),
    .clk        ( clk24         ),
    .fm_cen     ( fm_cen        ),
    .pcm_cen    ( pcm_cen       ),
    .cpu_dout   ( cpu_dout      ),
    .wr_n       ( wr_n          ),
    .a0         ( cpu_addr[0]   ),
    .fm_dout    ( fm_dout       ),
    .fm_cs      ( fm_cs         ),
    .pcm_dout   ( pcm_dout      ),
    .pcm_cs     ( pcm_ce        ),

    .enable_fm  ( enable_fm     ),
    .enable_psg ( enable_psg    ),

    .rom_addr   ( pcm_addr      ),
    .rom_data   ( pcm_data      ),
    .rom_ok     ( pcm_ok        ),

    .peak       ( game_led      ),
    .sample     ( sample        ),
    .snd        ( snd           )
);



endmodule