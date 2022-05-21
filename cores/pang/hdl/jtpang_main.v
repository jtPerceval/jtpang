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
    output      [19:0] main_addr,
    output             main_rnw,
    output      [ 7:0] cpu_dout,

    // Video configuration
    output  reg        flip,
    input              LVBL,
    input              dip_pause,

    // Object
    output  reg        attr_cs,
    output  reg        vram_cs,
    output  reg        pal_cs,
    input   [7:0]      attr_dout,
    input   [7:0]      pal_dout,
    input   [7:0]      vram_dout,
    // cabinet I/O
    input   [5:0]      joystick1,
    input   [5:0]      joystick2,
    input   [1:0]      start_button,
    input              coin,
    input              service,
    input              test,
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
    output       [19:0] rom_addr,
    output reg          rom_cs,
    input        [ 7:0] rom_data,
    input               rom_ok
);

wire [ 7:0] dec_dout, cpu_dout, sys_dout;
wire [15:0] A;
reg  [ 3:0] bank;
reg  [ 7:0] cpu_din;
wire        nvram_we, kabuki_we;
wire        m1_n, rd_n, wr_n, mreq_n, rfsh_n;
reg         ram_cs, rom_cs, cab_cs,
            fm_cs, oki_cs,
            oki_bank, pal_bank, obj_dma,
            eeprom_cs, eeprom_clk, eeprom_din;
wire        eeprom_dout;

assign nvram_we = prog_ram & prog_we;
assign sys_dout = { eeprom_dout, 3'b111, LVBL, 1'b1, test,
            1'b1 }; // Should be related to the IRQ source, whether
            // it was caused by LVBL or not

always @* begin
    rom_cs = !mreq_n && rfsh_n && A[15:14]!=2'b11;
    if( rom_cs ) begin
        rom_addr = { 6'd0, A[13:0] };
        if( A[15] )
            rom_addr[19:14] = 6'd2 + { 2'd0, bank };
        else
            rom_addr[14] = A[14];
    end
    ram_cs   = !mreq_n && rfsh_n && A[15:12]>=4'he;
    pal_cs   = !mreq_n && rfsh_n && A[15:12]==4'hc && !A[11];
    attr_cs  = !mreq_n && rfsh_n && A[15:12]==4'hc &&  A[11];
    vram_cs  = !mreq_n && rfsh_n && A[15:12]==4'hd;
    misc_cs  = !iorq_n && A[4:0]==0 && !wr_n;
    bank_cs  = !iorq_n && A[4:0]==2 && !wr_n;
    cab_cs = !iorq_n && A[4:0]<3  && !rd_n;
    obj_dma  = !iorq_n && A[4:0]==6;
    fm_cs    = !iorq_n && A[4:1]==1;
    oki_cs   = !iorq_n && A[4:0]==5;
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        bank      <= 0;
        flip      <= 0;
        char_en   <= 1;
        obj_en    <= 1;
        video_enb <= 0;
        eeprom_cs <= 0;
        eeprom_clk<= 0;
        eeprom_din<= 0;
    end else begin
        if( bank_cs ) bank <= cpu_dout[3:0];
        if( misc_cs ) begin
            // chip 11D takes bits 0,1,2,5
            // chip 12D takes bits 3,4,6,7
            // bit 0 = coin lock
            // bit 1 = coin counter
            // bit 6 is CHAR enable, but it goes
            // through a jumper. Pang! does not connect it
            flip      <= cpu_dout[2];
            video_enb <= cpu_dout[3];
            oki_bank  <= cpu_dout[4];
            pal_bank  <= cpu_dout[5];
            char_en   <= cpu_dout[6];
            obj_en    <= cpu_dout[7];
        end
        if( !iorq_n && !wr_n ) begin
            case( A[4:0] )
                5'h08: eeprom_cs  <= cpu_dout[0];
                5'h10: eeprom_clk <= cpu_dout[0];
                5'h18: eeprom_din <= cpu_dout[0];
            endcase
        end
    end
end

always @(posedge clk) begin
    case( A[1:0] ) begin
        0: cab_dout <= { coin, service, 2'b11,
            start_button[0], 1'b1, start_button[1], 1'b1 };
        1: cab_dout <= { joystick1[3:0], joystick1[5:4], 2'b11 };
        2: cab_dout <= { joystick2[3:0], joystick2[5:4], 2'b11 };
        default:;
    end
    cpu_din <=
        rom_cs  ? dec_dout  :
        ram_cs  ? ram_dout  :
        pal_cs  ? pal_dout  :
        attr_cs ? attr_dout :
        vram_cs ? vram_dout :
        fm_cs   ? fm_dout   :
        oki_cs  ? oki_dout  :
        sys_cs  ? sys_dout  :
        cab_cs  ? cab_dout  : 8'hff;
end

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