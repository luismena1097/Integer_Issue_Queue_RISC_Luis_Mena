`timescale 1ns/1ps
`include "variables.sv"

module tb_integer_issue_queue;

    // Parámetros
    parameter CLK_PERIOD = 10; // ns

    // Señales
    logic clk, reset;

    // Señales de despacho
    logic          dispatch_enable;
    logic [31:0]   dispatch_rs_data;
    logic [5:0]    dispatch_rs_tag;
    logic          dispatch_rs_data_val;
    logic [31:0]   dispatch_rt_data;
    logic [5:0]    dispatch_rt_tag;
    logic          dispatch_rt_data_val;
    logic [2:0]    dispatch_opcode;
    logic [5:0]    dispatch_rd_tag;
    logic          issueque_full;

    // Señales CDB
    logic [5:0]    cdb_tag;
    logic [31:0]   cdb_data;
    logic          cdb_valid;

    // Señales de emisión
    logic          issueque_ready;
    logic [31:0]   issueque_rs_data;
    logic [31:0]   issueque_rt_data;
    logic [5:0]    issueque_rd_tag;
    logic [2:0]    issueque_opcode;
    logic          issueblk_done;

    // Instancia del DUT
    integer_issue_queue dut (
        .clk(clk), .reset(reset),
        .dispatch_enable(dispatch_enable),
        .dispatch_rs_data(dispatch_rs_data),
        .dispatch_rs_tag(dispatch_rs_tag),
        .dispatch_rs_data_val(dispatch_rs_data_val),
        .dispatch_rt_data(dispatch_rt_data),
        .dispatch_rt_tag(dispatch_rt_tag),
        .dispatch_rt_data_val(dispatch_rt_data_val),
        .dispatch_opcode(dispatch_opcode),
        .dispatch_rd_tag(dispatch_rd_tag),
        .issueque_full(issueque_full),
        .cdb_tag(cdb_tag),
        .cdb_data(cdb_data),
        .cdb_valid(cdb_valid),
        .issueque_ready(issueque_ready),
        .issueque_rs_data(issueque_rs_data),
        .issueque_rt_data(issueque_rt_data),
        .issueque_rd_tag(issueque_rd_tag),
        .issueque_opcode(issueque_opcode),
        .issueblk_done(issueblk_done)
    );

    // Generador de reloj
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $display("==== TESTBENCH PARA integer_issue_queue ====");
        clk = 0; reset = 1;
        dispatch_enable = 0;
        cdb_valid = 0;
        issueblk_done = 0;
        # (2*CLK_PERIOD);
        #5;
        reset = 0;
/*
        // Inserción: Instrucción 1. Ambos operandos válidos (debe estar lista en ciclo siguiente)
        @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'h11111111;
        dispatch_rs_tag  = 6'd1;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'h11111111;
        dispatch_rt_tag  = 6'd2;
        dispatch_rt_data_val = 0;
        dispatch_opcode  = 3'b010;
        dispatch_rd_tag  = 6'd10;

        @(negedge clk);
        dispatch_enable = 0;
        $display("\nC1: Insertada instrucción con operandos válidos.");

        // Inserción: Instrucción 2. Segundo operando no válido (espera por cdb)
        @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'h22222222;
        dispatch_rs_tag  = 6'd3;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'h00000000;
        dispatch_rt_tag  = 6'd20;
        dispatch_rt_data_val = 0; // Espera CDB
        dispatch_opcode  = 3'b001;
        dispatch_rd_tag  = 6'd11;

        @(negedge clk);
        dispatch_enable = 0;
        $display("\nC2: Insertada instrucción con rt_tag 20 pendiente de CDB.");

        // Inserta dos más (llenar la cola)
        repeat (2) begin
            @(negedge clk);
            dispatch_enable = 1;
            dispatch_rs_data = $random;
            dispatch_rs_tag  = $random % 64;
            dispatch_rs_data_val = 1;
            dispatch_rt_data = $random;
            dispatch_rt_tag  = $random % 64;
            dispatch_rt_data_val = 0;
            dispatch_opcode  = 3'b000;
            dispatch_rd_tag  = $random % 64;
            @(negedge clk);
            dispatch_enable = 0;
        end
        $display("\nC3-C4: Cola llena.");

        // Intenta insertar otra: NO debe entrar (Full)
        @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'hDEADBEEF;
        dispatch_rs_tag  = 6'd10;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'hFEEDFACE;
        dispatch_rt_tag  = 6'd11;
        dispatch_rt_data_val = 1;
        dispatch_opcode  = 3'b100;
        dispatch_rd_tag  = 6'd12;
        @(negedge clk);
        dispatch_enable = 0;
        $display("\nC5: Intento de inserción con cola llena.");

        // Simula CDB actualizando el segundo operando de la instrucción 2 (rt_tag 20)
        @(negedge clk);
        cdb_tag = 6'd20;
        cdb_data = 32'h22222222;
        cdb_valid = 1;
        @(negedge clk);
        cdb_valid = 0;
        $display("\nC6: Se publica CDB con tag 20 para instrucción pendiente.");

        // Emisión: ejecuta la instrucción lista (más abajo)
        @(negedge clk);
        if (issueque_ready) begin
            $display("C7: Emisión de instrucción lista.");
            $display("   rs=0x%h rt=0x%h rd_tag=%d opcode=%b", issueque_rs_data, issueque_rt_data, issueque_rd_tag, issueque_opcode);
            issueblk_done = 1;
        end
        @(negedge clk);
        issueblk_done = 0;
        
        // Muestreo: muestra la siguiente instrucción lista
        @(negedge clk);
        if (issueque_ready) begin
            $display("C8: Siguiente instrucción lista:");
            $display("   rs=0x%h rt=0x%h rd_tag=%d opcode=%b", issueque_rs_data, issueque_rt_data, issueque_rd_tag, issueque_opcode);
        end

        @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'h33333333;
        dispatch_rs_tag  = 6'd1;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'h33333333;
        dispatch_rt_tag  = 6'd2;
        dispatch_rt_data_val = 0;
        dispatch_opcode  = 3'b010;
        dispatch_rd_tag  = 6'd10;

        @(negedge clk);
        dispatch_enable = 0;
        $display("\nC9: Insertada instrucción con operandos válidos.");

        @(negedge clk);
        cdb_tag = 6'd2;
        cdb_data = 32'h22222222;
        cdb_valid = 1;
        @(negedge clk);
        cdb_valid = 0;

        @(negedge clk);
        if (issueque_ready) begin
            $display("C7: Emisión de instrucción lista.");
            $display("   rs=0x%h rt=0x%h rd_tag=%d opcode=%b", issueque_rs_data, issueque_rt_data, issueque_rd_tag, issueque_opcode);
            issueblk_done = 1;
        end
        @(negedge clk);
        issueblk_done = 0;
        // Finaliza test
        # (3*CLK_PERIOD);*/
        @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'h11111111;
        dispatch_rs_tag  = 6'd1;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'h11111111;
        dispatch_rt_tag  = 6'd2;
        dispatch_rt_data_val = 1;
        dispatch_opcode  = 3'b010;
        dispatch_rd_tag  = 6'd10;

        @(negedge clk);
        dispatch_enable = 0;
        $display("\nC1: Insertada instrucción con operandos válidos.");

        // Inserción: Instrucción 2. Segundo operando no válido (espera por cdb)
        @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'h22222222;
        dispatch_rs_tag  = 6'd3;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'h22222222;
        dispatch_rt_tag  = 6'd20;
        dispatch_rt_data_val = 0; 
        dispatch_opcode  = 3'b001;
        dispatch_rd_tag  = 6'd11;

        @(negedge clk);
        dispatch_enable = 0;
        $display("\nC2: Insertada instrucción con operandos válidos.");

                @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'h33333333;
        dispatch_rs_tag  = 6'd1;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'h33333333;
        dispatch_rt_tag  = 6'd2;
        dispatch_rt_data_val = 1;
        dispatch_opcode  = 3'b010;
        dispatch_rd_tag  = 6'd10;

        @(negedge clk);
        dispatch_enable = 0;
        $display("\nC3: Insertada instrucción con operandos válidos.");

        // Inserción: Instrucción 2. Segundo operando no válido (espera por cdb)
        @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'h44444444;
        dispatch_rs_tag  = 6'd3;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'h44444444;
        dispatch_rt_tag  = 6'd20;
        dispatch_rt_data_val = 1; 
        dispatch_opcode  = 3'b001;
        dispatch_rd_tag  = 6'd11;

        @(negedge clk);
        dispatch_enable = 0;
        $display("\nC4: Insertada instrucción con operandos válidos.");

        @(negedge clk);
        if (issueque_ready) begin
            $display("C7: Emisión de instrucción lista.");
            $display("   rs=0x%h rt=0x%h rd_tag=%d opcode=%b", issueque_rs_data, issueque_rt_data, issueque_rd_tag, issueque_opcode);
            issueblk_done = 1;
        end
        @(negedge clk);
        issueblk_done = 0;

        @(negedge clk);
        if (issueque_ready) begin
            $display("C7: Emisión de instrucción lista.");
            $display("   rs=0x%h rt=0x%h rd_tag=%d opcode=%b", issueque_rs_data, issueque_rt_data, issueque_rd_tag, issueque_opcode);
            issueblk_done = 1;
        end
        @(negedge clk);
        issueblk_done = 0;

        @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'h55555555;
        dispatch_rs_tag  = 6'd3;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'h55555555;
        dispatch_rt_tag  = 6'd20;
        dispatch_rt_data_val = 1; 
        dispatch_opcode  = 3'b001;
        dispatch_rd_tag  = 6'd11;

                @(negedge clk);
        dispatch_enable = 1;
        dispatch_rs_data = 32'h66666666;
        dispatch_rs_tag  = 6'd3;
        dispatch_rs_data_val = 1;
        dispatch_rt_data = 32'h66666666;
        dispatch_rt_tag  = 6'd20;
        dispatch_rt_data_val = 1; 
        dispatch_opcode  = 3'b001;
        dispatch_rd_tag  = 6'd11;

                @(negedge clk);
        issueblk_done = 1;
    end

    // Monitoreo de banderas en cada ciclo
    always @(posedge clk) begin
        $display("CLK %0t | ready=%b | full=%b", $time, issueque_ready, issueque_full);
    end

endmodule
 