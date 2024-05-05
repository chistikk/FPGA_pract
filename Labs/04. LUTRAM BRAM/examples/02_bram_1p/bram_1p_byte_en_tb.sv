// в модуле сначало идет заполнение памяти fill_data()
//                            затем чтение requset_read()         3 раза
//                            затем запись requset_replace_byte() 3 раза

module bram_1p_byte_en_tb();

  localparam int NB_COL        = 2;
  localparam int COL_WIDTH     = 8;
  localparam int RAM_ADDR_BITS = 3;
  localparam int RAM_DEPTH     = 2**RAM_ADDR_BITS;

  logic                                clk_i;
  logic [ RAM_ADDR_BITS      - 1 : 0 ] addr_i;
  logic [ (NB_COL*COL_WIDTH) - 1 : 0 ] data_i;
  logic [ (NB_COL*COL_WIDTH) - 1 : 0 ] data_o;
  logic [  NB_COL            - 1 : 0 ] we_i;
  logic                                en_i;

  bram_1p_byte_en # (
    .NB_COL       ( NB_COL        ),
    .COL_WIDTH    ( COL_WIDTH     ),
    .RAM_ADDR_BITS( RAM_ADDR_BITS )
  )
  bram_1p_byte_en_inst (
    .clk_i  ( clk_i  ),
    .addr_i ( addr_i ),
    .we_i   ( we_i   ),
    .en_i   ( en_i   ),
    .data_i ( data_i ),
    .data_o ( data_o )
  );
//------------------------------------------------- clk_i
initial begin
  clk_i = 1'b0;
  forever begin
    clk_i = ~clk_i; #5;
  end
end
//------------------------------------------------- WRITE MODULE
int p;
event end_of_fill;

initial begin
  #10;
  p = 0;
  we_i = '0;

  repeat(RAM_DEPTH)begin  // заполнение памяти
    fill_data(); #5;
    p = p + 1;
  end

  ->end_of_fill;
  wait(end_of_read.triggered) // ждем окончания чтения

  #10;                        // запись в память
  requset_replace_byte();
  #30;
  requset_replace_byte();
  #30;
  requset_replace_byte();
  #30;
  $finish;
end

task fill_data();
  @(posedge clk_i)
    we_i   = '1;
    en_i   = '1;
    addr_i = p;
    data_i = $urandom_range(0, 2**(NB_COL*COL_WIDTH) - 1);
  #5; @(posedge clk_i)
    en_i = '0;
    we_i = '0;
endtask

int temp;
task requset_replace_byte();
  @(posedge clk_i)
    addr_i     = $urandom_range(0, RAM_DEPTH    );
    temp       = $urandom_range(0, NB_COL    - 1);
    we_i[temp] = '1;
    en_i       = '1;
    data_i     = $urandom_range(0, 2**(NB_COL*COL_WIDTH) - 1);
  #5; @(posedge clk_i)
    en_i = '0;
    we_i = '0;
endtask
//------------------------------------------------- READ MODULE
event end_of_read;
initial begin
  wait(end_of_fill.triggered)     // ждем окончания заполнения памяти
  #10;                            // чтение из памяти
  requset_read();
  #30;
  requset_read();
  #30;
  requset_read();
  #30;
  ->end_of_read;
end

task requset_read();
  @(posedge clk_i)
    en_i   = 1'b1;
    addr_i = $urandom_range(0, RAM_DEPTH - 1);
  #5; @(posedge clk_i);
    en_i   = 1'b0;
endtask

endmodule
