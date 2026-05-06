`timescale 1ns / 1ps
module ALU_rtl_design #(parameter N = 4)
(OPA,OPB,CIN,CLK,RST,CMD,CE,MODE,INP_VALID,COUT,OFLOW,RES,G,E,L,ERR);


  input [N-1:0] OPA,OPB;
  input CLK,RST,CE,MODE,CIN;
  input [3:0] CMD;
  input [1:0] INP_VALID;
  output reg [2*N-1:0] RES = {2*N{1'b0}};
  output reg COUT = 1'b0;
  output reg OFLOW = 1'b0;
  output reg G = 1'b0;
  output reg E = 1'b0;
  output reg L = 1'b0;
  output reg ERR = 1'b0;


  reg [N-1:0] OPA_1, OPB_1;
  reg [1:0] count=2'b00;
  reg signed [N:0] temp;
  
  
    always@(posedge CLK or posedge RST)
      begin
         if(RST)
          begin
            RES<={2*N{1'b0}};
            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;
          end
          
        else if(CE)                   
         begin
         if(MODE)
         begin
           RES<={2*N{1'b0}};
           COUT<=1'b0;
           OFLOW<=1'b0;
           G<=1'b0;
           E<=1'b0;
           L<=1'b0;
           ERR<=1'b0;
          case(CMD)             
           4'b0000:     
            begin
             if(INP_VALID == 2'd3)
              begin 
               RES <= OPA+OPB ;           
               {COUT, RES[N-1:0]} <= {1'b0, OPA} + {1'b0, OPB};
              end
             else
               ERR<=1'b1;
            end
	   4'b0001:             
            begin
             if(INP_VALID == 2'd3)
              begin
               OFLOW<=(OPA<OPB)?1:0;
               RES<=OPA-OPB;
              end
             else
               ERR<=1'b1;
             end
           4'b0010:             
            begin
             if(INP_VALID == 2'd3)
              begin
              RES <= OPA+OPB+CIN ;  
               {COUT,RES[N-1:0]} <= OPA+OPB+CIN;
              end
             else
               ERR <= 1'b1;
             end
           4'b0011:             
           begin
            if(INP_VALID == 2'd3)
             begin
              OFLOW<=(OPA<OPB)?1:0;
              RES<=OPA-OPB-CIN;
             end
            else
              ERR <= 1'b1;
            end

           4'b0100:
           begin
           if(INP_VALID == 2'd1 || 2'd3)
            RES<=OPA+1;    
           else
            ERR<=1'b1;
           end
           
           4'b0101:
           begin
           if(INP_VALID == 2'd1 || 2'd3)
           RES<=OPA-1;    
           else
           ERR<=1'b1;
           end
           
           4'b0110:
           begin
           if(INP_VALID == 2'd2 || 2'd3)
           RES<=OPB+1;    
           else
           ERR<=1'b1;
           end
           
           4'b0111:
           begin
           if(INP_VALID == 2'd2 || 2'd3)
           RES<=OPB-1;    
           else
           ERR<=1'b1;
           end
           
           4'b1000:              
           begin
           if(INP_VALID == 2'd3)
           begin
            RES<={2*N{1'b0}};
            if(OPA==OPB)
             begin
               E<=1'b1;
               G<=1'b0;
               L<=1'b0;
             end
            else if(OPA>OPB)
             begin
               E<=1'b0;
               G<=1'b1;
               L<=1'b0;
             end
            else 
             begin
               E<=1'b0;
               G<=1'b0;
               L<=1'b1;
             end
           end
           else
           ERR<=1'b1;
           end
           
          4'b1001:
begin
    if (INP_VALID == 2'd3)
    begin
        case(count)

            2'd0:
            begin
                
                OPA_1 <= OPA + 1;
                OPB_1 <= OPB + 1;
                count <= 2'd1;
            end

            2'd1:
            begin
                count <= 2'd2;
            end

            2'd2:
            begin
                RES   <= OPA_1 * OPB_1;
                count <= 2'd0;
            end

        endcase
    end
    else
    begin
        ERR   <= 1'b1;
        count <= 0;
    end
end
           
           4'b1010:
begin
    if (INP_VALID == 2'd3)
    begin
        case(count)

            2'd0:
            begin
                OPA_1 <= OPA << 1;
                OPB_1 <= OPB;
                count <= 2'd1;
            end

            2'd1:
            begin
                count <= 2'd2;
            end

            2'd2:
            begin
                RES   <= OPA_1 * OPB_1;
                count <= 2'd0;
            end

        endcase
    end
    else
    begin
        ERR   <= 1'b1;
        count <= 0;
    end
end  
           
                     
           4'b1011:   
           begin
           if(INP_VALID == 2'd3)
           begin
           temp = $signed(OPA) + $signed(OPB);
           RES  <= temp;
           OFLOW <= (OPA[N-1] == OPB[N-1]) && (temp[N-1] != OPA[N-1]);
           end
           else
           ERR <= 1'b1;
           end
           
           4'b1100:   
           begin
           if(INP_VALID == 2'd3)
           begin
           temp = $signed(OPA) - $signed(OPB);
           RES <= temp;
           OFLOW <= (OPA[N-1] != OPB[N-1]) && (temp[N-1] != OPA[N-1]);
           end
           else
           ERR <= 1'b1;
           end
           
           default:   
            begin
            RES<={2*N{1'b0}};
            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;
           end
          endcase
         end

        else          
        begin 
           RES<=9'b0;
           COUT<=1'b0;
           OFLOW<=1'b0;
           G<=1'b0;
           E<=1'b0;
           L<=1'b0;
           ERR<=1'b0;
           case(CMD)    
             4'b0000:
             begin
             if(INP_VALID == 2'd3)
             RES<={{N{1'b0}},OPA&OPB};     
             else
             ERR <= 1'b1;
             end
             
             4'b0001:
             begin
             if(INP_VALID == 2'd3)
             RES<={{N{1'b0}},~(OPA&OPB)};  
             else
             ERR <= 1'b1;
             end
             
             4'b0010:
             begin
             if(INP_VALID == 2'd3)
             RES<={{N{1'b0}},OPA|OPB};     
             else
             ERR <= 1'b1;
             end
             
             4'b0011:
             begin
             if(INP_VALID == 2'd3)
             RES<={{N{1'b0}},~(OPA|OPB)};  
             else
             ERR <=1'b1;
             end
             
             4'b0100:
             begin
             if(INP_VALID == 2'd3)
             RES<={{N{1'b0}},OPA^OPB};     
             else
             ERR <= 1'b1;
             end
             
             4'b0101:
             begin
             if(INP_VALID == 2'd3)
             RES<={{N{1'b0}},~(OPA^OPB)};  
             else
             ERR <= 1'b1;
             end
             
             4'b0110:
             begin
             if(INP_VALID == 2'd1 || 2'd3)
             RES<={{N{1'b0}},~OPA};        
             else
             ERR <= 1'b1;
             end
             
             4'b0111:
             begin
             if(INP_VALID == 2'd2 || 2'd3)
             RES<={{N{1'b0}},~OPB};        
             else
             ERR <= 1'b1;
             end
             
             4'b1000:
             begin
             if(INP_VALID == 2'd1 || 2'd3)
             RES<={{N{1'b0}},OPA>>1};      
             else
             ERR <= 1'b1;
             end
             
             4'b1001:
             begin
             if(INP_VALID == 2'd1 || 2'd3)
             RES<={{N{1'b0}},OPA<<1};      
             else
             ERR <= 1'b1;
             end
             
             4'b1010:
             begin
             if(INP_VALID == 2'd2 || 2'd3)
             RES<={{N{1'b0}},OPB>>1};      
             else
             ERR <= 1'b1;
             end
             
             4'b1011:
             begin
             if(INP_VALID == 2'd2 || 2'd3)
             RES<={{N{1'b0}},OPB<<1};      
             else
             ERR <= 1'b1;
             end
             
             4'b1100:                        
             begin
              if (INP_VALID == 2'b11) 
                begin
                    if (|OPB[(N-1):(N/2)])
                    begin
                     ERR <= 1'b1;
                     RES <= {{N{1'b0}},(OPA << OPB[$clog2(N)-1:0]) | (OPA >> (N - OPB[$clog2(N)-1:0]))};
                    end
                    else
                      RES <= {{N{1'b0}},(OPA << OPB[$clog2(N)-1:0]) | (OPA >> (N - OPB[$clog2(N)-1:0]))};
                 end
                else 
                  ERR <= 1'b1;
             end
             
             4'b1101:                         
             begin
              if (INP_VALID == 2'b11) 
                begin
                    if (|OPB[(N-1):(N/2)])
                    begin
                     ERR <= 1'b1;
                     RES <= {{N{1'b0}},(OPA >> OPB[$clog2(N)-1:0]) | (OPA << (N - OPB[$clog2(N)-1:0]))};
                    end
                    else
                      RES <= {{N{1'b0}},(OPA >> OPB[$clog2(N)-1:0]) | (OPA << (N - OPB[$clog2(N)-1:0]))};
                 end
                else 
                  ERR <= 1'b1;
             end
             
             default:    
               begin
               RES<=9'b0;
               COUT<=1'b0;
               OFLOW<=1'b0;
               G<=1'b0;
               E<=1'b0;
               L<=1'b0;
               ERR<=1'b0;
               end
          endcase
     end
    end
   end
endmodule

