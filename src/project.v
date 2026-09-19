/* Kurimanju drinking - 16 frame VGA sprite animation, 30 fps average */
`default_nettype none
module tt_um_vga_example(
  input wire [7:0] ui_in, output wire [7:0] uo_out,
  input wire [7:0] uio_in, output wire [7:0] uio_out, output wire [7:0] uio_oe,
  input wire ena, input wire clk, input wire rst_n
);
  wire hsync, vsync, video_active; wire [9:0] pix_x, pix_y; wire [1:0] R,G,B;
  assign uo_out={hsync,B[0],G[0],R[0],vsync,B[1],G[1],R[1]};
  assign uio_out=8'b0; assign uio_oe=8'b0;
  wire _unused_ok=&{ena,ui_in,uio_in};
  hvsync_generator hvsync_gen(.clk(clk),.reset(~rst_n),.hsync(hsync),.vsync(vsync),.display_on(video_active),.hpos(pix_x),.vpos(pix_y));
  localparam [9:0] X0=10'd128, Y0=10'd48;
  wire inside_image=video_active&&(pix_x>=X0)&&(pix_x<X0+10'd384)&&(pix_y>=Y0)&&(pix_y<Y0+10'd384);
  wire [9:0] local_x=pix_x-X0, local_y=pix_y-Y0;
  wire [5:0] img_x=local_x[8:3], img_y=local_y[8:3];
  // Update the sprite only at the start of a VGA frame to avoid tearing.
  wire video_frame_tick=(pix_x==10'd0)&&(pix_y==10'd0);

  // 25 MHz / (800 * 525) = 1250/21 ~= 59.5238 VGA frames/second.
  // Desired animation rate is 30 fps = 630/21.
  // Therefore advance on 63 of every 125 VGA frame ticks:
  //   (1250/21) * (63/125) = 30 animation frames/second exactly on average.
  // Most sprites are held for 2 VGA frames; occasionally one is held for 1.
  reg [7:0] anim_phase;
  reg [3:0] anim_frame;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      anim_phase <= 8'd0;
      anim_frame <= 4'd0;
    end else if(video_frame_tick) begin
      // Equivalent to: phase += 63; if phase >= 125, phase -= 125 and advance.
      // Written this way so the accumulator never needs a wider temporary value.
      if(anim_phase >= 8'd62) begin
        anim_phase <= anim_phase - 8'd62;
        anim_frame <= (anim_frame==4'd15) ? 4'd0 : (anim_frame+4'd1);
      end else begin
        anim_phase <= anim_phase + 8'd63;
      end
    end
  end
  wire [5:0] image_rgb; kurimanju_anim_rom sprite_rom(.frame(anim_frame),.x(img_x),.y(img_y),.rgb(image_rgb));
  wire [5:0] rgb=inside_image?image_rgb:6'b0;
  assign R=video_active?rgb[5:4]:2'b0; assign G=video_active?rgb[3:2]:2'b0; assign B=video_active?rgb[1:0]:2'b0;
endmodule
module kurimanju_anim_rom(input wire [3:0] frame,input wire [5:0] x,input wire [5:0] y,output reg [5:0] rgb);
  reg [287:0] row;
  always @* begin
    row=288'b0;
    case(frame)
      4'd0: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a55555555555aaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaa9a55041451455551451051556aaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa55052596596596596596595540056aaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa540525965965965965965965965965415aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9542596596596596596596596596596595401555aaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa555555565965965965965965965965965965955969a956aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9a57efbe954965965965965965965965965965555ffefea56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaaaa56afbef9552596596596596596596596595557efbee95aaaaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaaaaafbefbea55565965965965965965955569fbefbef9556aaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbefbefaa955554555555555555555abefbefbefaa02aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95fbefbefbefbefbeeaaa69965969aaafbefbefbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefa556aaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9597efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbee9556afbefbefbefaa569fbefbefbefbefbe55aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95abefbefbefbefbea40555fbefbefbea95540abefbefbefbefbea56aaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbaebaebea94429fbefbefbef95555ebaebaebefbefbea55aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbeabaeaaaaafaaabefbefbefbefbeabaebaeaaaaafbefbea55aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbeaa59a5965ebefbefbeeaafbefbefbeaa59a5965ebefbe955aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbefaaebaeaaebefbefaa555a7efbefbefaaabaeaaebefbe556aaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbefbeebafbefbefbefbeaaaebefbefbefbeebaebefbefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefa956aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef956aaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa695fbefbefbefbefbefbefbefbefbefbefbefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa9557ffbefbefbefbefbefbefbefbefbefbefbefbefbefaa16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa555fbefbefbefbefbefbefbefbefbefbefbefbefbef9556aaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefba55aaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefa9abee95aaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa57eaaafbefbefbefbefbefbefbefbefbefbefbef9516afd56aaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaa9a97f56afbefbefbefbefbefbefbefbefbefbefbef95555a956aaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaa9a57faaafbefbefbefbefbefbefbefbefbefbefbef9569a55aaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaa56a565fbefbefbefbefbefbefbefbefbefbefbef95aaaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaa95555fbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbefbefbefbe555ebe555aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555669556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa69556aaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd1: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a5555555556aaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaa5554105145145145105155aaaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa54052596596596596596595441456aaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa540565965965965965965965965955015aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9542596596596596596596596596596595015555aaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa55554096596596596596596596596596596595556aa956aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa95a7afaa525965965965965965965965965965555ffefe96aaaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa9657efbea5496596596596596596596596595557efbea95aaaaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaaa6afbefa9515965965965965965965965555ebefbef956aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95ebefbefbea9551556596596596595551597efbefbefaa16aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaa695fbefbefbefbeaa5555554555555555abafbefbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbeeaaaaaabefbefbefbefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef955aaaaaaaa;
          6'd18: row = 288'haaaaaaaaaa95a7efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefaaabefbefbefbefaaabefbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95ebefbefbefbefbea9556afbefbefbef95555fbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95fbefbefbeebaebf555555fbefbefbea80540abefbafbefbefbe956aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94fbefbefbaebaebea9556afbefbefbefa9569fbaebaebafbefbe555aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbeaaaaaaaaafbefbefbefbefbefbefbeaaaaa69a6fbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeaa5aaa9a5ebefbefaaaa9abafbefbeea5aaaaa5abefbe55aaaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbefaaebaebafbefbefaaa69a7efbefbefbaebaebafbefbe56aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbefd556aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef95aaaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbefbefbefbefbefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa95a7ffbefbefbefbefbefbefbefbefbefbefbefbefbefea16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaaa95fbefbefbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbaabaf95aaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa57eaaafbefbefbefbefbefbefbefbefbefaa66a56af95aaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaa9a97f56afbefbefbefbefbefbefbefbefbee95aaa57ea95aaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaa9a57faaafbefbefbefbefbefbefbefbefbea95a9556a555aaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaa56a569fbefbefbefbefbefbefbefbefbef9556a555555aaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaa95555fbefbefbefbefbefbefbefbefbefa956a5aaa956aaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefaa56a5555556aaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefaa56a555555aaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbffbefbefbe555aa5555aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457fffa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555669556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd2: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a55569aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaa5555504145145104145556aaaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa540414965965965965965554015aaaaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa680425965965965965965965965954015aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9501596596596596596596596596596595055556aaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa6955409659659659659659659659659659659555159556aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9a56ae95565965965965965965965965965965955abefea56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa9657efba565965965965965965965965965965555fbea95aaaaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa56afbea9496596596596596596596596595557efbee956aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbefaa555965965965965965965965515fbefbefaa16aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95ebefbefbee95554565965965965555515a7efbefbefbe556aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa569fbefbefbefbeeaa955555555555569abefbefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbaebafbefbefbefbefbefbefbef956aaaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95abefbefbefbefbefaaabefbefbefbefaaa6afbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbea95565fbefbefbef95555fbefbefbefbefbe956aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbeebaebfa40555fbefbefbea80540abeebafbefbefbe955aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbefbaebaebaf9556afbefbefbefaa569fbaebaebafbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeaaaaa69a5fbefbefbefbefbefbefbfaaaaa69a5fbefbe556aaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbeea5aaaaa6ebefbefaaaa5abafbefbeea5aaaaa6abefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbefbaebaebafbefbefaaa6aabefbefbefbaebaebafbefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbefa956aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa16afbefbefbefbefbefbefbeebafbefbefbefbefbefbefbef956aaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbefbefaaaaaaaafbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa95abffbefbefbefbefbefbefbe96aaaaa95abefbefbefaa16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbe56aa95555abefbefbea856aaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaaa95fbefbefbefbefbefbefbe555555fd557ffbefaa15aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbe555bd5a9556afbef956aaaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa57e56afbefbefbefbefbefbea9a56a555aaafbef956aaaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaa9aabf56afbefbefbefbefbefbea9a595555ebeaaaf956aaaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaa9a57faa9fbefbefbefbefbefbee95555555569aaaf956aaaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaa555565fbefbefbefbefbefbefbeabafbefbefbef95aaaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaa95555fbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa85abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefaafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555557ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555669556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd3: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a55969aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaa555550414514510414555aaaaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa540414965965965965965554015aaaaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa680425965965965965965965965954015aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9501596596596596596596596596596595056aaaaaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa695540965965965965965965965965965965965015555aaaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9a56aa95965965965965965965965965965965955a7efaa56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa95abffea525965965965965965965965965965955fbef955aaaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa57afbe55596596596596596596596596596552afbef956aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbef95565965965965965965965965955a7efbefaa56aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95ebefbefbe95456596596596596596595556afbefbefbe556aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa569fbefbefbefaa555555555555555515555ebefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57afbefbefbefbefbeaaa555555565aaafbefbefbefbefbef956aaaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbefaaa6afbefbefbefaa56afbefbefbefbefbea56aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbefbefbea55555fbefbefbee95540abefbefbefbefbea55aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbefbaebaebfa80555fbefbefbee95555abeebafbefbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeebaebaeaafaaa7afbefbefbefaaa6aebaebaeaafbefbe556aaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbeaa5aa5965ebefbefbefbafbefbefbeaa5aa5965ebefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbeea6aaaaaaebefbefaaa55a7afbefbeea6abaaaaebefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbeebaebefbefbefbaaaaabefbefbefbeebaebefbefa956aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbef956aaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbeeaaaaaabafbefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa95abffbefbefbefbefbefba56aaaaa95fbefbefbefbefaa16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefaaaaaa95695abefbefbefbea856aaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaaa95fbefbefbefbefbefaa56a56aa94abefbefbefaa15aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefaa56aaaaac0abefbefbef956aaaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa57f56afbefbefbefbefaa695a9555596afbefbef956aaaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaa9aabf56afbefbefbefbefaa56a555a7ffbeebefbef956aaaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaa9a57faa9fbefbefbefbefbe555555565aa9abefbef956aaaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaa555565fbefbefbefbefbefaaaaaaaaaaafbefbef95aaaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaa95555fbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbeffffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffea55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555669556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd4: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa69a55569aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaa5555144145145104145556aaaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa5404159659659659659655544156aaaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa680425965965965965965965965954015aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9501596596596596596596596596596595056aaaaaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa6955409659659659659659659659659659659650155556aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9a56aa95965965965965965965965965965965955abefaa56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa95abffaa525965965965965965965965965965955fbefaa56aaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa57afbea5496596596596596596596596596552afbef956aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbefa9525965965965965965965965555abefbefaa16aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95ebefbefbea9551596596596596596555456afbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa569fbefbefbefbea5555551555551455556afbefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefaaaa9a69aaaabefbefbefbefbefbef955aaaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbea9556afbefbefbefaa565fbefbefbefbefbea56aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbefbefbf955555fbefbefbea95540abefbefbefbefbea55aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbefbaebaebfa95529fbefbefbef95555ebaebaebefbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeebaeaaaaafaaabefbefbefbefbeabeebaeaaaaafbefbe556aaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbeaa59a5965ebefbefbaeaafbefbefbeaa59a5965ebefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbefaaabaeaaebefbefaa55597efbefbefaaabaeaaebefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbeebaebefbefbefbeaaaebefbefbefbeebaebefbefa956aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbef956aaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbefaaaaaabafbefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa95abffbefbefbefbefbefba56aaaaa95fbefbefbefbefaa16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefaaaabaaaa95ebefbefbefbea856aaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaa695fbefbefbefbefbefaa56a555a95ebefbefbefaa15aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefaa02baaffc0a7efbefbef956aaaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa57f56afbefbefbefbefba55556a555a6afbefbef956aaaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaa9aabf56afbefbefbefbefbe56a55556affeeaafbef956aaaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaa9a57faa9fbefbefbefbefbe955555555a69a6afbef956aaaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaa555565fbefbefbefbefbefaaaaaabeabafbefbef95aaaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaa95555fbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbeffffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffea55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555669556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd5: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa69a55569aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaa5555144145145104145556aaaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa5404159659659659659655540156aaaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa680425965965965965965965965954015aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9501596596596596596596596596596595056aaaaaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaaa95540965965965965965965965965965965965015555aaaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9a56aa95965965965965965965965965965965955abefaa56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa95abffaa525965965965965965965965965965955fbef956aaaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa56afbea5496596596596596596596596596552afbef956aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbefa5525965965965965965965965554abefbefaa16aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95ebefbefbea9551596596596596596555456afbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa569fbefbefbefbea5555551555551555556afbefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefaaaa9a69aaaabefbefbefbefbefbef955aaaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbee9556afbefbefbefaa569fbefbefbefbefbea56aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbefbefbf955555fbefbefbea95540abefbefbefbefbea55aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbefbaebaebfa94529fbefbefbef95555ebaebaebefbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeebaeaaaaafaaabefbefbefbefbeabeebaeaaaaafbefbe556aaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbeaa59a5965ebefbefbaeaafbefbefbeaa59a5965ebefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbeeaaebaeaaebefbefaa95597efbefbefaaabaeaaebefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbeebaebefbefbefbeaaaebefbefbefbeebaebefbefa956aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbef956aaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbefbeaaaaa9ebefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa95abffbefbefbefbefbefbea95aaaaeaa7efbefbefbefea16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbea6aaaaaaa57efbefbefbea856aaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaa695fbefbefbefbefbefbea95a95aaa57efbefbefaa15aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbea85adafeb029abefbef956aaaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa57f56afbefbefbefbefbea95595695a6aabefbef956aaaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaa9aabf56afbefbefbefbefbef95a9501597efaaabef956aaaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaa9a57faa9fbefbefbefbefbefa9555569565aaaebef956aaaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaa555565fbefbefbefbefbefbeaaaebefbefbefbef95aaaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaa95555fbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbeffffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffea55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555669556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd6: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a55555555556aaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaa9a55041451455551451041556aaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a55052596596596596596595540056aaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa540565965965965965965965965965415aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9542596596596596596596596596596595401556aaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa5555409659659659659659659659659659659555559556aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9596afaa525965965965965965965965965965955fbefea56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa95a7efbe55596596596596596596596596596552afbef956aaaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa57afbef95565965965965965965965965954abefbef9556aaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbefbe55456596596596596596555456afbefbefaa12aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaa695fbefbefbefaa555555555555555555569fbefbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa56afbefbefbefbefbeaaaa69a69a69abafbefbefbefbefbee95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefa556aaaaaaa;
          6'd18: row = 288'haaaaaaaaaa95a7efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe55aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95ebefbefbefbefbea95a7afbefbefbefa956afbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbf555555fbefbefbea95550fbefbefbefbefbea55aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbaebaebfa50429fbefbefbea95555fbaebaebefbefbe955aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbeebaeaaaaafaaabefbefbefbeaaaabeebaeaaaaafbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeaa59a5965fbefbefbefaaa95569fbeaa5aa5965fbefbe55aaaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbeeaaebaaaaebefbefa9555abffeaabeeaaebaaaaebefbe56aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa9597efbefbeebaebefbefbefaa56aa9a69557efbeebaebefbefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefbea55a95aaa03afbefbefbefbefd556aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbea95a95fea56afbefbefbefbee95aaaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa695fbefbefbefbefbefbefbee9556a540555fbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa9557ffbefbefbefbefbefbefaa55501595596afbefbefea16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa565fbefbefbefbefbefbefba55556affeaa5a7efbea85aaaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaaa95fbefbefbefbefbefbefbeeaaf9596afbefbef9516aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afaafbefbefbefbefbefbefbefbeaa9a6afbef9556aaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa56aa95fbefbefbefbefbefbefbefbefbeaaafbefaa56aaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaaaa56af95abefbefbefbefbefbefbefbefbefbefbefa556aaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaaaa695fea97efbefbefbefbefbefbefbefbefbefbefd556aaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaaa95555abefbefbefbefbefbefbefbefbefbefbef956aaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaaaa555fbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbeffffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555a69556a55556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd7: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaa695555555555555aaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaa9555041451596595551441556aaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaa69aa9541056596596596596596596550056a555aaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaa9555554052596596596596596596596595555556556aaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaa95fbefbaa5555596596596596596555556afbefbf55aaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaa95a7efbefaaa5555555555555555596afbefbefaa56aaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaaa95a7efbefbefbefbaaaaaaaaaafbefbefbefbefaa02aaaaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaaaaaaafbefbefbefbefbefbefbefbefbefbefbefbefbea55aaaaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaaaaabefbefbefbefbefbefbefbefbefbefbefbefbefbef9556aaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefaa12aaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaa695fbefbefbefbefaaabefaaaaaabefaaa7efbefbefbefbe955aaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaa56afbefbefbefbea5556afaaaaaabea95555fbefbefbefbef95aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa57efbefbeebafbf540025fbeaaafea540555fbeebafbefbefa956aaaaaaa;
          6'd17: row = 288'haaaaaaaaaa95a7efbeebaebaebea9556aabefaa555aaa56affaebaebafbefaa56aaaaaaa;
          6'd18: row = 288'haaaaaaaaaa95abefbeaaaaa5966fbefbeabaa9517ffffa95aaaaa5965fbefba56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbeaa5aaaaaaebefbefaa545abfbeaaaa555aaaaaaebefbe55aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95ebefbefbaebaebefbefbefbef95aea555a9a555ebaebefbefbe55aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95ebefbefbefbefbefbefbefbefaa555a95555695ebefbefbefbea55aaaaaa;
          6'd22: row = 288'haaaaaaaaaa94ebefbefbefbefbefbefbefbefbea80a95555595ffefbefbefbe955aaaaaa;
          6'd23: row = 288'haaaaaaaaaa95ebefbefbefbefbefbefbefbefbefaa01554055597efbefbefbe555aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbea95540abe555ebefbefbe55aaaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbaf9597efa957efbefbe56aaaaaaa;
          6'd26: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefaa52afbe56afbefaa56aaaaaaa;
          6'd27: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbefbefbefbefbea95abea95fbefd556aaaaaaa;
          6'd28: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefaa57ef95abea95aaaaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa695fbefbefbefbefbefbefbefbefbefbefbefbe56afe9abf555aaaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefbeaaafbafa956aaaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaaaa555fbefbefbefbefbefbefbefbefbefbefbefbefbea45aaaaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaaa95fbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaa6aafbefbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56aeaafbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa56af95fbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaaaa5aafeaa7efbefbefbefbefbefbefbefbefbefbefaa56aaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaaaaa95abe57efbefbefbefbefbefbefbefbefbefbefaa56aaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaaa9a555a7efbefbefbefbefbefbefbefbefbefbef9556aaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaaaa695fbefbefbefbefbefbefbefbefbefbefbee95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555554457ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555559a69556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa69556aaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd8: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaa6955555555555556aaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaa9555041451596595551441556aaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaa9541056596596596596596596550056a69aaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaa55554052596596596596596596596595555555556aaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaa95abefbaa5555596596596596596555556afbefbf555aaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaa95abefbefbaa95555555555555555a6afbefbefaa55aaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaaa9597efbefbefbefbaaaaaaaaaafbefbefbefbefaa02aaaaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaaaaaaafbefbefbefbefbefbefbefbefbefbefbefbefbea55aaaaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaaaaabefbefbefbefbefbefbefbefbefbefbefbefbefbef9556aaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefaa12aaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaa695fbefbefbefbefaaabefaaaaaabefaaa7afbefbefbefbe955aaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaa56afbefbefbefbe55556afaaaaaabea95555fbefbefbefbef95aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa57efbefbeebaebf540025fbeaaaffe540555fbeebafbefbefa956aaaaaaa;
          6'd17: row = 288'haaaaaaaaaa95a7efbeebaebaebae9557aabefeaa5555a16affaebaebafbefaa56aaaaaaa;
          6'd18: row = 288'haaaaaaaaaa95abefbeaaaaa5965fbefbeabaa9502bfffa95aaaaa5965fbefba56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbeaa5aaaaaaebefbefaa544abffeba9a565aaaaaaebefbe55aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95ebefbefbaebaebefbefbefbef95bea555a9a555ebaebefbefbe55aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95ebefbefbefbefbefbefbefbefaa5aaaaabd5695ebefbefbefbea55aaaaaa;
          6'd22: row = 288'haaaaaaaaaa94ebefbefbefbefbefbefbefbefbea55a95555a95ffefbefbefbe955aaaaaa;
          6'd23: row = 288'haaaaaaaaaa95ebefbefbefbefbefbefbefbefbefa9015540555a7efbefbefbe555aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbea54540aba555fbefbefbe55aaaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefaaa95a7ff9557efbefbe56aaaaaaa;
          6'd26: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefaa52afbe56afbefaa56aaaaaaa;
          6'd27: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbefbefbefbefbea95ebea95fbefd556aaaaaaa;
          6'd28: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefaa57ef95abea95aaaaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa695fbefbefbefbefbefbefbefbefbefbefbefbe56afd5abf555aaaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefbeaaafaafa956aaaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaaaa555fbefbefbefbefbefbefbefbefbefbefbeebafbea45aaaaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaaa95fbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaa6aafbefbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56aeaafbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa56af95fbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaaaa5aafeaa7efbefbefbefbefbefbefbefbefbefbefaa56aaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaaaaa95abe57efbefbefbefbefbefbefbefbefbefbefaa56aaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaaa9a555a7efbefbefbefbefbefbefbefbefbefbef9556aaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaaaa695fbefbefbefbefbefbefbefbefbefbefbee85aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbf555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555554457ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555559a69556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd9: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a69a69aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaa555550410514510414555aaaaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa540414965965965965965554015aaaaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaaa80425965965965965965965965954015aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9501596596596596596596596596596594056aaaaaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa555540965965965965965965965965965965965015555aaaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9596aa95565965965965965965965965965965955a7afaa56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa95abffba565965965965965965965965965965955fbef956aaaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa57efbea9496596596596596596596596596556afbef956aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa99abefbefaa555965965965965965965965555abefbefa956aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95ebefbefbee9551556596596596595555456afbefbefbe556aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa569fbefbefbefbeaa9555554514515555a6afbefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57afbefbefbefbefbefbeeaaaaaaaafbefbefbefbefbefbef956aaaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95abefbefbefbefbefbeabefbefbefbefbeabafbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbef95555fbeeaaebefaa555abefbefbefbefbe956aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbefbefbea80540eaaaaaaaaf95540a7febefbefbefbea55aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbefbaebaebaf95555fbaaaaabafaa555abbebaebafbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeeaaeaaaa5ebeebefbefaafbefbefbeeaaaaaaa5ebefbe556aaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbeea59aa965abefbefaaa5556afbefbefa596a965abefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbefbaebaebaebefbefbe55557efbefbefbaabaebaebefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9657efbefbefbafbefbefbefbe55556aaa9fbefbefbafbefbefe956aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbea9556aaaaa7efbefbefbefbef956aaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbea95fffaaa57afbefbefbefbfa95aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa85abefbefbefbefbefbefbea6abd5aaa56afbefbefbefaa16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbea95a95fef569fbefbefbea955aaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaa555fbefbefbefbefbefbef95aaaa95555a69abefaa555aaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefaa555000aaaaaaabef9556aaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa56aa95fbefbefbefbefbefbe569555abefbefbefaa56aaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaaaa56af95abefbefbefbefbefbeaa5aaa565a69abefa956aaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaaaa695ffa57efbefbefbefbefbefbefbefbaeaaebefd556aaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaaa9556957efbefbefbefbefbefbefbefbefbefbef956aaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaaaa540abefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbf555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555a69556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd10: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa69aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaa695554510410514515556aaaaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa555414565965965965955510015aaaaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaaa9541596596596596596596596595001aaaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9a01496596596596596596596596596554056aaaaaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaaa95540565965965965965965965965965965965015555aaaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9a56aa9596596596596596596596596596596595556aeaa56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa95abffaa525965965965965965965965965965955fbefaa56aaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa57afbea9496596596596596596596596596556afbef956aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaaaaabefbefaa515965965965965965965965954abefbefa956aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95abefbefbea9551596596596596596555456afbefbefbe55aaaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa565fbefbefbefbea9555551555555455556afbefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbaaaaaaaaaaabefbefbefbefbefbef956aaaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbeebefbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbefa9569fbefbafbefaa555abefbefbefbefbe956aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbefbefbea80540aaaaaaaaafd555557ffbefbefbefbea55aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbefbaebaebef95515fbaaaaaaafaa515abfebaebefbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeeaaeaaaaaebeabefbefaafbefbeebafaaeaaaaaebefbe556aaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbeea59a6965abefbefaaaa9a6afbefbefa5966965abefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbefaaabaebaabefbefbe55556afbefbefbaabaebaebefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9557efbefbefbaebefbefbefbe95557efbefbefbefbaebefbefaa56aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa57afbefbefbefbefbefbefbea9597efbefbefbefbefbefbef955aaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbea95abefbefbefbefbefbefbea95aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa95abefbefbefbefbefbefbefaaabefbefbefaaebefbefba55aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaa9a56afbefbefbefbefbefbefaaebefbeaaa65557efbee9556aaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaa555fbefbefbefbefbefbefbefbefaa5aafffaaaffea95aaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa6aafbefbefbefbefbefbefbefbef95ffffeaa95aaafaaaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa56aaa9fbefbefbefbefbefbefbefa9aaa56a555aaafaaaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaaaa56aa95fbefbefbefbefbefbefbefaa57f6bfaa5ffea9aaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaaaa56afe5abefbefbefbefbefbefbefbe56a55555555556aaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaa695a95a7efbefbefbefbefbefbefbea55545555a95aaaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaa9a555fbefbefbefbefbefbefbefbee95a69abea95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbaabefbf555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefaafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555557ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555a69556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd11: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a55555555555aaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaa9a55041451455551451041556aaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a55052596596596596596595540056aaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa540565965965965965965965965965415aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9542596596596596596596596596596595401aaaaaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa5555409659659659659659659659659659659555555556aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa95abaf95565965965965965965965965965965955ebefba56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa95abefaa56596596596596596596596596596552afbefa556aaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa57efbea94965965965965965965965965954a7efbef9556aaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbefaa555965965965965965965955529fbefbefaa02aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaa695fbefbefbee95554555965965955555555abefbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa56afbefbefbefbeeaaa55555555555a6aabefbefbefbefbee95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef9556aaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9597efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe55aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95ebefbefbefbefbefaaabefbefbefbefaaa7efbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbe55556afaaaaaebea95555fbefbefbefbefbea55aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbeebafbe55502afaaaaaabea95555fbaebafbefbefbe955aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbeebaebaebea95a7efbaaaafbefa996aebaebaebefbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeaaa9a596afbefbefbeaaafbefbefbeaaaaa696afbefbe55aaaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbeaa5aaaaaafbefbef95555a7efbefbeaa5aaaaaafbefbe56aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa9597efbefbaebaebefbefbefa9015abefbefbefbaebaebefbefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefaa565ebefbefbefbefbefbefbefd556aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefaa555fbefbefbefbefbefbefbee95aaaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa695fbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa9557efbefbefbefbefbefbeaaafbefbefbaaaaabefbefaa16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa569fbefbefbefbefbefbefbefbefbea95aaa56afbea95aaaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaaaa5fbefbefbefbefbefbefbefbef95abffffaa9fbea9aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afaafbefbefbefbefbefbefbef95feaa9aa9456afaaaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa56aa95fbefbefbefbefbefbefbefaa56a56aaa9fbef9aaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaaaa56af95abefbefbefbefbefbefbefaa57f6bfa95aaa56aaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaaaa565feaa7efbefbefbefbefbefbefbe5555555555556aaaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaaa95555abefbefbefbefbefbefbefbea95695569f95aaaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaaaa555fbefbefbefbefbefbefbefbefa9a6aebfa95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefaafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbeffffbefbefbe555abe555aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555554457ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555a69556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa69556aaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd12: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a55555555556aaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaa9a55441051451451451041556aaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa55052596596596596596595540056aaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa540565965965965965965965965965415aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9542596596596596596596596596596595001aaaaaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa5555409659659659659659659659659659659555555555aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa95a6ae95565965965965965965965965965965955abefaa56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa95abefaa565965965965965965965965965965569fbefa556aaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa57efbea9496596596596596596596596595557efbef9556aaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbefaa555965965965965965965955515fbefbefaa12aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95fbefbefbee95554555965965965555515abefbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa56afbefbefbefbeeaaa5555555555596aabefbefbefbefbee95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbeebafbefbefbefbefbefbefbef9556aaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9597efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe55aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95abefbefbefbefbefaaabefbefbefbefaaa7efbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbe55556afbaaaaebea95555fbefbefbefbefbea55aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbeebafbf555029faaaaaabea80555fbeebafbefbefbe955aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbeebaebaebea9557afbaaaafbefa956afbaebaebafbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeaaaaa596afbefbefbeaaaebefbefbfaaaaa5965fbefbe55aaaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbeaa5aaaaaafbefbefa5555a7efbefbeaa5aaaaaafbefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa9597efbefbaebaebefbefbefaa415abefbefbefbaebaebefbefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefaa555abefbefbefbefbefbefbefd556aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefaa555abefbefbefbefbefbefbef95aaaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa695fbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa9557efbefbefbefbefbefbeaaafbefbefbeaaaabefbefaa16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbea95aaa56afbea95aaaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaa695fbefbefbefbefbefbefbefbef95abffffaa9fbea9aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afaafbefbefbefbefbefbefbef95feaaaaa9556afaaaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa56aa95fbefbefbefbefbefbefbefaa56a56a6a9fbef9aaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaaaa56af95abefbefbefbefbefbefbefaa57fabfa95aaa55aaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaaaa569feaa7efbefbefbefbefbefbefbe5555555555556aaaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaaa95555abefbefbefbefbefbefbefbea95655569e95aaaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaaaa555fbefbefbefbefbefbefbefbefa9a6aebfa95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefaafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbeffffbefbefbe555abe555aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffea55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555a69556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa69556aaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd13: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa69555555a6aaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaa5554105145145144105156aaaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa5405259659659659659659544156aaaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa540525965965965965965965965955015aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9502596596596596596596596596596595056aaaaaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa5555409659659659659659659659659659659555155556aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9596afaa525965965965965965965965965965955ebefaa56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa96a7efbe55596596596596596596596596596556afbefaa56aaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa56afbef95525965965965965965965965955a7efbef955aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbefbea5456596596596596596595556afbefbefaa16aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95fbefbefbefaaa55554555555555515569ebefbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa569fbefbefbefbefbeeaaa69a69a6aabafbefbefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef955aaaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefba56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95abefbefbefbefbefaa56afbefbefbefaa555fbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbefbefbea80555fbefbefbef95540abefbefbefbefbea56aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbefbaebaebfa95015fbefbefbef95555abfebaebefbefbe955aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbeebaeaaaaafaaabefbefbefbefbeabaebaeaaaaafbefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbeea5aa5955abefbefbafaaabafbefbeea5aa5965abefbe55aaaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbefaaabaaaaabefbefaa55556afbefbefaaabaaaaabefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbefbeebaebefbefbefbeabafbefbefbefbeebaebefbefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefbeaa9fbefbefbefbefbefbefbefe956aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef956aaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbefbefbefbefbefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa95a7ffbefbefbefbefbefbefbefbefbefbeaaaabefbefaa16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbea996aa56afbea856aaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaa695fbefbefbefbefbefbefbefbef95aaffffaa9ffea95aaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbefbef95fffaaaa95a69faaaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa56aaa5fbefbefbefbefbefbefbefaa56a56a569ebafaaaaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaaaa56af95fbefbefbefbefbefbefbefaa17fabfa95aaa69aaaaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaaaa569feaa7efbefbefbefbefbefbefbe5555555555555aaaaaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaaa95a95abefbefbefbefbefbefbefbea95695569e95aaaaaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaaaa555fbefbefbefbefbefbefbefbefa596aabea95aaaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefaafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbefbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555a69556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa69556aaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd14: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9555555555555aaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaa9555041451455555451041556aaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaa9541052596596596596596595540056aaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa540565965965965965965965965965415aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9542596596596596596596596596596594001555aaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa555550965965965965965965965965965965955aaaa956aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa95a7afaa52596596596596596596596596596556afbef95aaaaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa95a7efbea94965965965965965965965965954abefbea55aaaaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaaa7afbefaa55496596596596596596595556afbefbef956aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95fbefbefbefa9555515555555555555569fbefbefbefaa16aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaa555fbefbefbefbefaaaa9955555969aaafbefbefbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef955aaaaaaaa;
          6'd18: row = 288'haaaaaaaaaa95a7efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95ebefbefbefbefbeea9a7efbefbefbefa956afbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95fbefbefbefbefbe555569ffefbefbea95554fbefbefbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaa695fbefbefbaebaebf54002afbefbefbea95555fbaebaebefbefbe556aaaaaa;
          6'd23: row = 288'haaaaaaaaaa95fbefbeebaebaabafaaabefbefbefbefaaabeebaeaaaaafbefbe556aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95fbefbeaa69a5965fbefbefbeeaafbefbefbeaa59a5965ebefbe556aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95ebefbeea6eaaaaafbefbefa9955a7efbefbeeaaebaaaaebefbe55aaaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbefbaebaebefbefbefaaaaaebefbefbefbeebaebefbefaa56aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9557efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefd556aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbefbefbefbefbefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa95abffbefbefbefbefbefbefbefbefbefbefbefbefbefd556aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbea45aaaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaaa94ebefbefbefbefbefbefbefbefbefbefbefbef9502aaaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbef95a5aaaaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa57eaaafbefbefbefbefbefbefbefbefbefbefbef95aa9aaaaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaa9a57f56afbefbefbefbefbefbefbefbefbefbefbef95aaa6aaaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaa9a57faaafbefbefbefbefbefbefbefbefbefbefbef95aaa6aaaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaa56a565fbefbefbefbefbefbefbefbefbefbefbef95a95aaaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaa695555fbefbefbefbefbefbefbefbefbefbefbea94556aaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa95abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbffbefbefbe555ebe555aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaaaa555aaa55569555555555555a69556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      4'd15: begin
        case (y)
          6'd0: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd1: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd2: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd3: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd4: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd5: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a5555555556aaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd6: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaa5554105145145144105156aaaaaaaaaaaaaaaaaaaaaaa;
          6'd7: row = 288'haaaaaaaaaaaaaaaaaaaaaaaa5405259659659659659659544156aaaaaaaaaaaaaaaaaaaa;
          6'd8: row = 288'haaaaaaaaaaaaaaaaaaaaa540525965965965965965965965955015aaaaaaaaaaaaaaaaaa;
          6'd9: row = 288'haaaaaaaaaaaaaaaaaaa9502596596596596596596596596596594015556aaaaaaaaaaaaa;
          6'd10: row = 288'haaaaaaaaaaaaaaa555555565965965965965965965965965965555aa9a956aaaaaaaaaaa;
          6'd11: row = 288'haaaaaaaaaaaaa9a97aebe95496596596596596596596596596556afbefea56aaaaaaaaaa;
          6'd12: row = 288'haaaaaaaaaaaaa9a57efbefa5525965965965965965965965555abefbea95aaaaaaaaaaaa;
          6'd13: row = 288'haaaaaaaaaaaaaaa56afbefbea9555596596596596595555557afbefbef956aaaaaaaaaaa;
          6'd14: row = 288'haaaaaaaaaaaaa95abefbefbefbea95555555555555555a6afbefbefbefaa12aaaaaaaaaa;
          6'd15: row = 288'haaaaaaaaaaaaa95fbefbefbefbefbefbeaaaaaaabafbefbefbefbefbefbe555aaaaaaaaa;
          6'd16: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaa;
          6'd17: row = 288'haaaaaaaaaaaa57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef9556aaaaaaa;
          6'd18: row = 288'haaaaaaaaaa9597efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd19: row = 288'haaaaaaaaaa95abefbefbefbefbefaaabefbefbefbefaaabefbefbefbefbefba56aaaaaaa;
          6'd20: row = 288'haaaaaaaaaa95abefbefbefbefbea9556afbefbefbea95555fbefbefbefbefbe56aaaaaaa;
          6'd21: row = 288'haaaaaaaaaa95ebefbefbefbafbe555555ffefbefbea80554fbeebafbefbefbe55aaaaaaa;
          6'd22: row = 288'haaaaaaaaaa95ebefbefbaebaebea9556afbefbefbefa556affaebaebefbefbea55aaaaaa;
          6'd23: row = 288'haaaaaaaaaa94ebefbeaaaaaa9aafbefbefbefbefbefbefbfaaaaaa9aafbefbe955aaaaaa;
          6'd24: row = 288'haaaaaaaaaa95ebefbeaa5aa6965fbefbefaaaa9abefbefbeaa5aa69a5ebefbe555aaaaaa;
          6'd25: row = 288'haaaaaaaaaa95abefbefbaebaebafbefbefaaa69abefbefbefaaebaebafbefbe556aaaaaa;
          6'd26: row = 288'haaaaaaaaaa95abefbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbefbe55aaaaaaa;
          6'd27: row = 288'haaaaaaaaaa95a7efbefbefbefbefbefbefbeaaafbefbefbefbefbefbefbefaa56aaaaaaa;
          6'd28: row = 288'haaaaaaaaaa9a57efbefbefbefbefbefbefbefbefbefbefbefbefbefbefbefe556aaaaaaa;
          6'd29: row = 288'haaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbefbefbef95aaaaaaaaa;
          6'd30: row = 288'haaaaaaaaaaaa555fbefbefbefbefbefbefbefbefbefbefbefbefbefbefbf555aaaaaaaaa;
          6'd31: row = 288'haaaaaaaaaaaaa95a7ffbefbefbefbefbefbefbefbefbefbefbefbefbefea16aaaaaaaaaa;
          6'd32: row = 288'haaaaaaaaaaaaaaa56afbefbefbefbefbefbefbefbefbefbefbefbefbea856aaaaaaaaaaa;
          6'd33: row = 288'haaaaaaaaaaaaaaaa95fbefbefbefbefbefbefbefbefbefbefbefbefbea95aaaaaaaaaaaa;
          6'd34: row = 288'haaaaaaaaaaaaaaa56afbafbefbefbefbefbefbefbefbefbefbefbefbefea6aaaaaaaaaaa;
          6'd35: row = 288'haaaaaaaaaaaaaaa57fa6afbefbefbefbefbefbefbefbefbefbefbefa9aba56aaaaaaaaaa;
          6'd36: row = 288'haaaaaaaaaaaaa9aa7f56afbefbefbefbefbefbefbefbefbefbefbef95abe56aaaaaaaaaa;
          6'd37: row = 288'haaaaaaaaaaaaa9a57faa9fbefbefbefbefbefbefbefbefbefbefbef95faa56aaaaaaaaaa;
          6'd38: row = 288'haaaaaaaaaaaaaaa555569fbefbefbefbefbefbefbefbefbefbefbef955556aaaaaaaaaaa;
          6'd39: row = 288'haaaaaaaaaaaaaaaa95555fbefbefbefbefbefbefbefbefbefbefbea956aaaaaaaaaaaaaa;
          6'd40: row = 288'haaaaaaaaaaaaaaaaaaa85abefbefbefbefbefbefbefbefbefbefbe555aaaaaaaaaaaaaaa;
          6'd41: row = 288'haaaaaaaaaaaaaaaaaaa9557eebefbefbefbefbefbefbefbefbafaa02aaaaaaaaaaaaaaaa;
          6'd42: row = 288'haaaaaaaaaaaaaaaaaaa95abea95abefbefbefbffbefbefbe555abe556aaaaaaaaaaaaaaa;
          6'd43: row = 288'haaaaaaaaaaaaaaaaaaa95abffbe55555555555555555555457ffaa55aaaaaaaaaaaaaaaa;
          6'd44: row = 288'haaaaaaaaaaaaaaaaaaa9a555aaa55569555555555559a69556955556aaaaaaaaaaaaaaaa;
          6'd45: row = 288'haaaaaaaaaaaaaaaaaaaaaa9a5556aaaaaaaaaaaaaaaaaaaa6955aaaaaaaaaaaaaaaaaaaa;
          6'd46: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          6'd47: row = 288'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
          default: row = 288'b0;
        endcase
      end
      default: row=288'b0;
    endcase
    if(x<6'd48) rgb=row>>(x*6); else rgb=6'b0;
  end
endmodule
`default_nettype wire
