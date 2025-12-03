typedef enum bit[6:0]{ 
    R_TYPE = 7'b0110011, 
    I_TYPE = 7'b0010011, 
    S_TYPE = 7'b0100011,
    B_TYPE = 7'b1100011, 
    J_TYPE = 7'b1101111, 
    U_TYPE = 7'b0010111, 
    JALR   = 7'b1100111,
    LW     = 7'b0000011,
    LUI    = 7'b0110111
} Opcode_enum;

typedef struct packed {
   logic [31:0] rs1_data;  
   logic [31:0] rs2_data;  
   logic rs1_data_valid;   
   logic rs2_data_valid;  
   logic [5:0] rs1_tag;    
   logic [5:0] rs2_tag;   
   logic [5:0] rd_tag;     
} queue_data;

 typedef struct packed {
    queue_data common_data;
    logic [6:0] opcode;
    logic [2:0] func3;
    logic [6:0] func7;
 } int_queue_data;

 typedef struct packed {
    queue_data common_data;
    logic [31:0] imm;
    logic load_or_store_signal;
    logic [2:0] func3;
 } lw_sw_queue_data;

typedef struct packed {
   logic        valid;
   logic [2:0]  opcode;
   logic [5:0]  rd_tag;
   logic [5:0]  rs_tag;
   logic [31:0] rs_data;
   logic        rs_val;
   logic [5:0]  rt_tag;
   logic [31:0] rt_data;
   logic        rt_val;
} entry_issue_queue_t;