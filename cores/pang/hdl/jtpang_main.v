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
    Date: 20-5-2022 */

module jtpang_main(
    input              clk,
    input              rst,
    input              cpu_cen,

    // BUS sharing
    output      [17:0] main_addr,
    output             main_rnw,
    output             [7:0] cpu_dout,

    // Video configuration
    output  reg        flip,
    input              LVBL,
    input              dip_pause,

    // Object
    output  reg        scr_cs,
    output  reg        obj_cs,
    output  reg        pal_cs,
    input   [7:0]      pal_dout,
    input   [7:0]      scr_dout,
    // cabinet I/O
    input   [5:0]      joystick1,
    input   [5:0]      joystick2,
    input   [1:0]      start_button,
    input   [1:0]      coin_input,
    input              service,
    // DIP switches
    input    [7:0]     dipsw_a,
    input    [7:0]     dipsw_b,
    // NVRAM dump/restoration
    input  [RAM_AW-1:0] prog_addr,
    input  [7:0]        prog_data,
    output [7:0]        prog_din,
    input               prog_we,
    input               prog_ram,
    // Kabuki
    input               kabuki_we,
    input               kabuki_en,
    // ROM access
    output  reg        rom_cs,
    input       [ 7:0] rom_data,
    input              rom_ok
);

wire [7:0] dec_dout, cpu_dout;
wire       nvram_we, kabuki_we;
wire       m1_n, rd_n, mreq_n;
reg        ram_cs, rom_cs;

assign nvram_we = prog_ram & prog_we;

jtframe_kabuki u_kabuki(
    .clk        ( clk         ),    // Uses same clock as u_prom_we
    .m1_n       ( m1_n        ),
    .mreq_n     ( mreq_n      ),
    .rd_n       ( rd_n        ),
    .addr       ( A           ),
    .din        ( rom_data    ),
    .en         ( kabuki_en   ),
    // Decode keys
    .prog_data  ( prog_data   ),
    .prog_we    ( kabuki_we   ),
    .dout       ( dec_dout    )
);

jtframe_sysz80_nvram #(
    .RAM_AW     ( 12        ),
    .CLR_INT    ( 1         )
) u_cpu(
    .rst_n      ( rst_n     ),
    .clk        ( clk       ),
    .cen        ( cpu_cen   ),
    .cpu_cen    (           ),
    .int_n      ( int_n     ),
    .nmi_n      ( 1'b1      ),
    .busrq_n    ( 1'b1      ),
    .m1_n       ( m1_n      ),
    .mreq_n     ( mreq_n    ),
    .iorq_n     ( iorq_n    ),
    .rd_n       ( rd_n      ),
    .wr_n       ( wr_n      ),
    .rfsh_n     (           ),
    .halt_n     (           ),
    .busak_n    (           ),
    .A          ( A         ),
    .cpu_din    ( cpu_din   ),
    .cpu_dout   ( cpu_dout  ),
    .ram_dout   ( ram_dout  ),
    // NVRAM dump/restoration
    .prog_addr  ( prog_addr ),
    .prog_data  ( prog_data ),
    .prog_din   ( prog_din  ),
    .prog_we    ( nvram_we  ),
    // ROM access
    .ram_cs     ( ram_cs    ),
    .rom_cs     ( rom_cs    ),
    .rom_ok     ( rom_ok    )
);


endmodule