USE RikkeiClinicDB;
-- DỮ LIỆU ĐẦU VÀO 
/*

p_patient_id INT  MÃ BỆNH NHÂN 
p_medicine_id INT MÃ THUỐC 
p_quantity SỐ LƯỢNG CẤP PHÁT 

Dữ liệu đầu ra
	p_message  VARCHAR(255)  Thông báo trạng thái
	
*/
-- 2.GIẢI PHÁP 
/*
Quy trình cấp phát thuốc gồm 2 thao tác:
Trừ tồn kho thuốc
Cộng tiền vào công nợ bệnh nhân

Hai bước này phải chạy cùng nhau.

Nếu:
số lượng yêu cầu > tồn kho
hoặc có lỗi hệ thống
=> phải ROLLBACK.
Bước 1
Bắt đầu transaction
START TRANSACTION;
Bước 2
Kiểm tra tồn kho thuốc
Nếu không đủ:
rollback
trả thông báo lỗi
Bước 3
Trừ tồn kho
Bước 4
Tính tiền thuốc
thành tiền = số lượng × đơn giá
Bước 5
Cộng vào công nợ bệnh nhân
Bước 6
COMMIT transaction

*/
DELIMITER //

CREATE PROCEDURE DispenseMedicine(
    IN p_patient_id INT,
    IN p_medicine_id INT,
    IN p_quantity INT,
    OUT p_message VARCHAR(255)
)
BEGIN

    DECLARE v_stock INT;
    DECLARE v_price DECIMAL(18,2);

    -- Bắt lỗi hệ thống
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;

        SET p_message = 'Loi: He thong gap su co';
    END;

    START TRANSACTION;

    -- Lấy tồn kho và đơn giá
    SELECT stock, price
    INTO v_stock, v_price
    FROM Medicines
    WHERE medicine_id = p_medicine_id;

    -- Kiểm tra tồn kho
    IF v_stock < p_quantity THEN

        ROLLBACK;

        SET p_message = 'Loi: So luong ton kho khong du';

    ELSE

        -- Trừ kho
        UPDATE Medicines
        SET stock = stock - p_quantity
        WHERE medicine_id = p_medicine_id;

        -- Cộng công nợ
        UPDATE Patient_Invoices
        SET total_due = total_due + (p_quantity * v_price)
        WHERE patient_id = p_patient_id;

        COMMIT;
 
        SET p_message = 'Da cap phat thanh cong';

    END IF;

END //

DELIMITER ;
CALL DispenseMedicine(1, 2, 2, @msg);

SELECT @msg;