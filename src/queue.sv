/*
    Description: Integer Issue Queue
    Author: Luis Alberto Mena Gonzalez
*/

`include "variables.sv"
module integer_issue_queue #(
    parameter DEPTH = 4
) (
    input  logic          clk,
    input  logic          reset,

    // Signals to dispatcher
    input  logic          dispatch_enable,  //1 = Dispatcher wants to write a new instruction
    //RS1
    input  logic [31:0]   dispatch_rs_data,
    input  logic [5:0]    dispatch_rs_tag,
    input  logic          dispatch_rs_data_val,
    //RS2
    input  logic [31:0]   dispatch_rt_data,
    input  logic [5:0]    dispatch_rt_tag,
    input  logic          dispatch_rt_data_val,
    //Opcode for the ALU
    input  logic [2:0]    dispatch_opcode,
    //RD TAG
    input  logic [5:0]    dispatch_rd_tag,
    output logic          issueque_full,

    //CDB Signals
    input  logic [5:0]    cdb_tag,
    input  logic [31:0]   cdb_data,
    input  logic          cdb_valid,

    //Signals to unit
    output logic          issueque_ready,
    output logic [31:0]   issueque_rs_data,
    output logic [31:0]   issueque_rt_data,
    output logic [5:0]    issueque_rd_tag,
    output logic [2:0]    issueque_opcode,
    input  logic          issueblk_done    // Issued-instruction done
);

    entry_issue_queue_t queue [DEPTH];

    logic [DEPTH-1:0] instruction_ready;        //To track valid of each instruction of the queue

    logic [2:0] shift_after_issue;

    //If the 4 slots of the queue have a valid instruction, the queue is full. Also using done signal to prevent losing a cycle between queue full and an instruction going to the execution unit
    assign issueque_full = queue[0].valid & queue[1].valid & queue[2].valid & queue[3].valid & !issueblk_done;

    //Shift and update of the queue
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i=0; i<DEPTH; i++) begin
                queue[i] <= 'b0;
            end
        end else begin
            //Adding the instruction from the dispatcher while the queue is not full
            if (dispatch_enable && !issueque_full) begin
                for (int i=DEPTH-1; i>0; i--) begin
                    queue[i] <= queue[i-1];     //Shift to make room for the new instruction into the first slot of the queue
                end
                //Adding the new instruction to the queue
                queue[0].valid   <= 1'b1;
                queue[0].rd_tag  <= dispatch_rd_tag;
                queue[0].opcode  <= dispatch_opcode;
                queue[0].rs_data <= dispatch_rs_data;
                queue[0].rs_tag  <= dispatch_rs_tag;
                queue[0].rs_val  <= dispatch_rs_data_val;
                queue[0].rt_data <= dispatch_rt_data;
                queue[0].rt_tag  <= dispatch_rt_tag;
                queue[0].rt_val  <= dispatch_rt_data_val;
            end
            else if (issueblk_done && issueque_ready) begin
                for (int i=shift_after_issue; i<DEPTH-1; i++) begin
                    queue[i] <= queue[i+1];
                end
                queue[DEPTH-1] <= 'b0;
            end
            // CDB Data Update
            if (cdb_valid) begin
                for (int i=0; i<DEPTH; i++) begin
                    if (queue[i].valid) begin           //If there is a valid instruction in the queue, we can check if the cdb data is for any of the instructions
                        if (!queue[i].rs_val && queue[i].rs_tag == cdb_tag) begin  //If rs1 valid = 0 and rs1 tag = cdb tag update rs1 data with CDB data
                            queue[i].rs_data <= cdb_data;
                            queue[i].rs_val  <= 1'b1;
                        end
                        if (!queue[i].rt_val && queue[i].rt_tag == cdb_tag) begin //If rs2 valid = 0 and rs2 tag = cdb tag update rs2 data with CDB data
                            queue[i].rt_data <= cdb_data;
                            queue[i].rt_val  <= 1'b1;
                        end
                    end
                end
            end
        end
    end
    //Check for any instruction ready to be executed
    always_comb begin
        for (int i=0; i<DEPTH; i++) begin
            if (instruction_ready[i]) begin
                issueque_rs_data  = queue[i].rs_data;
                issueque_rt_data  = queue[i].rt_data;
                issueque_rd_tag   = queue[i].rd_tag;
                issueque_opcode   = queue[i].opcode;
                shift_after_issue = i;
            end
        end
    end
    //Any of the instructions in the queue is ready to be executed
    assign issueque_ready    = |instruction_ready;
    //In case the entry of the queue is valid and RS1 & RS2 are valid, the instruction is ready to go to the execution units
    assign instruction_ready[0] = queue[0].valid && queue[0].rs_val && queue[0].rt_val;
    assign instruction_ready[1] = queue[1].valid && queue[1].rs_val && queue[1].rt_val;
    assign instruction_ready[2] = queue[2].valid && queue[2].rs_val && queue[2].rt_val;
    assign instruction_ready[3] = queue[3].valid && queue[3].rs_val && queue[3].rt_val;

endmodule
 