// =========================================================================
// Verison 07//10/26
// =========================================================================
 
module reset_sync (
    input wire clk,       
    input wire rstn,      
    output reg rstn_sync 
);
    reg ff1_q;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ff1_q <= 1'b0;
            rstn_sync <= 1'b0;
        end else begin
            ff1_q <= 1'b1; // Chân D của FF1 luôn = 1
            rstn_sync <= ff1_q; // Chân D của FF2 nhận giá trị từ Q của FF1
        end
    end

endmodule