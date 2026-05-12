USE RikkeiClinicDB;

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
