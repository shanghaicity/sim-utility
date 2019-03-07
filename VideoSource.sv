/*******************************************************************************
* ### verilog-HDL patgen File Header ###
* Project      : VOLGA
* Module Name  : VideoSource.sv
* Abstract     :
* Keywords     :
* history      :
* Rev. DATE            AUTHOR          COMMENT
* 0.1  2019.03.06      wang.hao        first release
*******************************************************************************/
`timescale 1ns/100ps
package SimUtil;
  class VideoSource #(p_lane_num);
    /*
    * Output signals
    */
    bit [p_lane_num-1:0]       vsync = 1;
    bit [p_lane_num-1:0]       hsync;
    bit [p_lane_num-1:0]       de   = 0;
    bit [p_lane_num-1:0][39:0] data = 0;
    bit [p_lane_num-1:0][23:0] ctl  = 0;
    /*
    * Members variables
    */
    bit clk;
    int fp;
    int frame = 2;
    int hact = 16;
    int vact = 2;
    int vsw = 2;
    int vbp = 2;
    int vfp = 2;
    int hsw = 10;
    int hbp = 5;
    int hfp = 5;
    event e_frame;
    event e_line;

    /*
    * Description
    *   Constructor, called when new object created.
    * Parameters
    *   color: r, g, b. Used to read input file 
    */
    function new(string fn);
      fp = $fopen(fn, "r");
    endfunction

    /*
    * Start output video signal and data
    */
    task Play();
      for(int i=0; i<frame; i++)
        PlayFrame(i);
      $fclose(fp);
      $finish;
    endtask

    /*
    * Play one frame
    */
    task PlayFrame(int fc);
      //$display("play frame %d", fc);
      GenVsync();
    endtask

    /*
    * Generator Vsync
    */
    task GenVsync();
      //$display("Start Generate Vsync");
      vsync = 0;
      fork
        begin
          WaitLine(vsw);
          vsync = 1;
        end
      join_none
      // wait vblank back porch lines
      repeat(vbp) begin 
        WaitLine(1);
      end
      // wait vactive lines
      repeat(vact) begin
        fork
          WaitLine(1);
          GenDe();
        join
      end
      // wait vblank front porch lines
      repeat(vfp) begin 
        WaitLine(1);
      end
    endtask

    /*
    * Generator Hsync
    */
    task GenHsync();
      //$display("Start Generate Hsync");
      hsync = 0;
      WaitPixel(hsw);
      hsync = 1;
    endtask

    /*
    * Generator DE
    */
    task GenDe();
      //$display("Start Generate DE");
      // wait hblank back porch
      WaitPixel(hbp);
      de = 1;
      repeat(hact) begin
        // Read in data
        ReadData();
      end
      de = 0;
      // wait hblank front porch
      WaitPixel(hfp);
    endtask

    /*
    * Read in pixel data from file
    */
    task ReadData();
      int ret;
      for(int i=0; i<p_lane_num; i++) begin
        ret = $fscanf(fp, "%h", data[i]);
        if (ret != 1) begin
          $display("some mistake in reading files");
          $fclose(fp);
          $finish;
        end
      end
      WaitPixel(1);
    endtask

    /*
    * Description 
    *   Wait line
    * Parameter
    *   n: The number of lines to wait
    */
    task WaitLine(int n);
      fork
        WaitPixel((hbp+hact+hfp)*n);
        GenHsync();
      join
    endtask

    /*
    * Description 
    *   Wait pixels
    *   This task maybe used by GenHsync and Gen WaitLine at the same time,
    *   so automatic is need
    * Parameter
    *   n: The number of lines to wait
    */
    task automatic WaitPixel(int n);
      if (n>0)
        repeat(n)
          @(posedge clk);
    endtask

  endclass
endpackage: SimUtil
