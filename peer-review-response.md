# Lab 8 - Peer review response

## Nhóm được review

- Tên nhóm: Đặng Quang Tiến và Nguyễn Hoàng
- Người review: Thành viên nhóm khác trong lớp CNTT18-02

## Góp ý nhận được

1. Nên bổ sung kiểm tra trường hợp packet bị cắt ngắn (truncated) khi nhận qua socket.
2. Log Receiver chưa in ra độ dài DES key và encrypted key để tiện đối chiếu với log Sender.
3. Chưa có mô tả rõ ràng về lý do chọn PKCS#7 padding thay vì padding thủ công.

## Phản hồi và chỉnh sửa

| Góp ý | Phản hồi của nhóm | File/commit đã sửa |
|---|---|---|
| Packet bị cắt ngắn | Hàm `recv_exact` trong `secure_transfer_utils.py` đã xử lý: lặp nhận đủ `n` byte, ném `ConnectionError` nếu kết nối đóng sớm. Thêm test `test_recv_secure_packet_over_local_socket` kiểm tra qua `socket.socketpair()`. | `secure_transfer_utils.py`, `tests/test_lab8_socket_helpers.py` |
| Log Receiver thiếu thông tin key | Đã bổ sung log in độ dài encrypted DES key và xác nhận toàn vẹn SHA-256 vào `receiver.py`. | `receiver.py` |
| Giải thích PKCS#7 padding | PKCS#7 được dùng vì DES-CBC yêu cầu plaintext là bội số của 8 byte; `pycryptodome` cung cấp sẵn `pad/unpad` chuẩn, tránh lỗi tự cài đặt padding. Đã ghi rõ trong báo cáo. | `report-1page.md` |

## Tự đánh giá sau chỉnh sửa

- Chương trình chạy được demo Sender/Receiver: Có
- Có kiểm tra SHA-256: Có
- Có mã hóa DES key bằng RSA-OAEP: Có
- Có test cho packet/tamper: Có
- Có log minh chứng: Có
