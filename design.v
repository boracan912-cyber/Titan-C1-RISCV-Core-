// =================================================================
// MARKA: TITAN SILICON TECHNOLOGIES
// AMİRAL GEMİSİ: TITAN C1 (RAM Bellek Kapılı ve Yapay Zeka Destekli)
// =================================================================

module titan_c1_core(
    input clk,                         // Sistem Saati
    input rst,                         // Sıfırlama Sinyali
    input [31:0] instr_in,             // Bellekten gelen 32-bit komut
    input [31:0] mem_data_in,          // Harici RAM bellekten okunan veri (Load)
    output reg [31:0] pc,              // Program Sayacı
    output reg [31:0] mem_addr_out,    // RAM belleğe gönderilen adres çizgisi
    output reg [31:0] mem_data_out,   // RAM belleğe yazılacak veri (Store)
    output reg mem_write_en,           // RAM Yazma İzni (1: RAM'e Yaz, 0: RAM'den Oku)
    output reg [31:0] titan_out        // Titan C1 Ana Çıktı Hattı
);

    // Titan C1 İç Hafızası (32 adet 32-bit Yazmaç)
    reg [31:0] register_file [0:31];

    // RISC-V Standart Komut Çözücü Çizgileri
    wire [6:0] opcode = instr_in[6:0];
    wire [4:0] rd     = instr_in[11:7];   
    wire [4:0] rs1    = instr_in[19:15];  
    wire [4:0] rs2    = instr_in[24:20];  
    wire [11:0] imm   = instr_in[31:20];  

    integer i;

    // Titan C1 Çalışma Döngüsü
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'b0;
            mem_addr_out <= 32'b0;
            mem_data_out <= 32'b0;
            mem_write_en <= 1'b0;
            titan_out <= 32'b0;
            for (i = 0; i < 32; i = i + 1) begin
                register_file[i] <= 32'b0;
            end
        end else begin
            pc <= pc + 4; 
            mem_write_en <= 1'b0; // Varsayılan olarak RAM'e yazmayı kapat

            case(opcode)
                // TİCARİ Standart Komut: Sabit Sayı Ekleme (ADDI)
                7'b0010011: begin 
                    register_file[rd] <= register_file[rs1] + {{20{imm}}, imm};
                    titan_out <= register_file[rs1] + {{20{imm}}, imm};
                end

                // KRİTİK BELLEK KAPISI 1: RAM Bellekten Veri Yükle (LW - Load Word)
                7'b0000011: begin
                    mem_addr_out <= register_file[rs1] + {{20{imm}}, imm}; // RAM adresini hesapla
                    register_file[rd] <= mem_data_in;                      // RAM'den gelen veriyi iç hafızaya al
                    titan_out <= mem_data_in;
                end

                // KRİTİK BELLEK KAPISI 2: RAM Belleğe Veri Kaydet (SW - Store Word)
                // Bu komut sayesinde Titan C1 yapay zeka sonuçlarını telefonun RAM'ine yazar!
                7'b0100011: begin
                    mem_addr_out <= register_file[rs1] + {{20{imm}}, imm}; // RAM adresini hesapla
                    mem_data_out <= register_file[rs2];                    // İç hafızadaki veriyi RAM'e gönder
                    mem_write_en <= 1'b1;                                  // RAM Yazma çizgisini aktif et (Elektrik gönder)
                    titan_out <= 32'h10AD_D02E;                            // "LOADED" modunu belirten özel çıktı
                end

                // PATENTLİ TITAN C1 ÖZEL YAPAY ZEKA KOMUTU
                7'b1111111: begin
                    register_file[rd] <= (register_file[rs1] * register_file[rs2]);
                    titan_out <= (register_file[rs1] * register_file[rs2]);
                end

                default: begin
                    titan_out <= 32'b0;
                end
            endcase
        end
    end
endmodule
