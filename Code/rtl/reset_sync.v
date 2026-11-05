// =========================================================================
// Verison 13//10/26
// =========================================================================
 
module reset_sync (
    input wire clk,       
    input wire rstn,      
    output reg rstn_sync 
);
    reg rstn_meta;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rstn_meta <= 1'b0;
            rstn_sync <= 1'b0;
        end else begin
            rstn_meta <= 1'b1; // Chân D của FF1 luôn = 1
            rstn_sync <= rstn_meta; // Chân D của FF2 nhận giá trị từ Q của FF1
        end
    end

endmodule