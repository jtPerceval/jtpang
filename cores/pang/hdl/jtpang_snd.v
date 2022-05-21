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

module jtpang_snd(
    input              clk,
    input              rst,
    input              cpu_cen,
    input              fm_cen,

    // CPU interface
    input        [7:0] cpu_dout,
    input              wr_n,

    input              a0,
    output       [7:0] fm_dout,
    input              fm_cs,

    output       [7:0] pcm_dout,
    input              pcm_cs,

    // ROM interface
    output      [17:0] rom_addr,
    input       [ 7:0] rom_data,
    input              rom_ok,

    output             peak,
    output             sample,
    output signed [15:0] snd
);

localparam [7:0] FM_GAIN  = 8'h10,
                 PCM_GAIN = 8'h03;

jtopll u_topll (
    .rst   ( rst        ),
    .clk   ( clk        ),
    .cen   ( fm_cen     ),
    .din   ( cpu_dout   ),
    .addr  ( a0         ),
    .cs_n  ( ~fm_cs     ),
    .wr_n  ( wr_n       ),
    .dout  ( fm_dout    ),
    .snd   ( snd        ),
    .sample( sample     )
);

jt6295 u_pcm (
    .rst     ( rst      ),
    .clk     ( clk      ),
    .cen     ( cpu_cen  ),
    .ss      ( 1'b1     ),
    .wrn     ( wr_n     ),
    .din     ( cpu_dout ),
    .dout    ( pcm_dout ),
    .rom_addr( rom_addr ),
    .rom_data( rom_data ),
    .rom_ok  ( rom_ok   ),
    .sound   ( sound    ),
    .sample  (          )
);


jtframe_mixer u_mixer(
    .rst  ( rst         ),
    .clk  ( clk         ),
    .cen  ( cpu_cen     ),
    .ch0  ( fm_dout     ),
    .ch1  ( pcm_dout    ),
    .ch2  (             ),
    .ch3  (             ),
    .gain0( FM_GAIN     ),
    .gain1( PCM_GAIN    ),
    .gain2( 8'd0        ),
    .gain3( 8'd0        ),
    .mixed( snd         ),
    .peak ( peak        )
);


endmodule