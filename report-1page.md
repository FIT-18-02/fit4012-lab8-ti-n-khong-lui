# Lab 8 - Báo cáo 1 trang

## 1. Mục tiêu

Xây dựng chương trình truyền dữ liệu an toàn qua socket bằng mô hình mã hóa lai (hybrid encryption), kết hợp DES-CBC, SHA-256 và RSA-OAEP.

---

## 2. Trao đổi key DES qua đường truyền bằng RSA

### Vấn đề đặt ra

Hai bên cần có chung một key DES để mã hóa dữ liệu. Nhưng nếu gửi key này trực tiếp qua mạng, kẻ nghe lén sẽ chặn được và giải mã toàn bộ nội dung.

**Giải pháp**: dùng RSA để bọc (mã hóa) key DES trước khi truyền — gọi là **mô hình mã hóa lai**.

> RSA chỉ bảo vệ key đối xứng khi truyền; DES mã hóa dữ liệu thật vì nhanh hơn RSA hàng nghìn lần.

### Các bước thực hiện

**Bước 1 — Receiver sinh cặp khóa RSA** (`keygen.py`)

Receiver tạo cặp khóa 2048-bit gồm Public key và Private key.
- `receiver_public.pem` → chia sẻ công khai cho Sender (không cần kênh bí mật).
- `receiver_private.pem` → giữ kín tuyệt đối tại máy Receiver.

```python
key = RSA.generate(2048)
private_path.write_bytes(key.export_key())
public_path.write_bytes(key.publickey().export_key())
```

**Bước 2 — Sender sinh key DES ngẫu nhiên** (`secure_transfer_utils.py:24`)

```python
des_key = os.urandom(8)   # 8 byte, sinh ngẫu nhiên mỗi phiên
iv      = os.urandom(8)
```

**Bước 3 — Sender mã hóa key DES bằng RSA public key của Receiver** (`secure_transfer_utils.py:95`)

```python
rsa_cipher = PKCS1_OAEP.new(receiver_public_key)
encrypted_des_key = rsa_cipher.encrypt(des_key)
```

Kết quả là 256 byte đã được "khóa" — chỉ Private key tương ứng mới mở được.

**Bước 4 — Sender gửi gói tin qua TCP socket** (`sender.py:39`)

Packet được đóng gói theo thứ tự:

```
[len_key: 4 byte] [encrypted_des_key: 256 byte]
[len_cipher: 4 byte] [IV(8) + ciphertext]
[sha256_hash: 32 byte]
```

Dù kẻ tấn công chặn được packet, không có Private key nên không giải mã được key DES.

**Bước 5 — Receiver giải mã key DES bằng RSA private key** (`secure_transfer_utils.py:103`)

```python
rsa_cipher = PKCS1_OAEP.new(receiver_private_key)
des_key = rsa_cipher.decrypt(encrypted_des_key)
```

Sau bước này Receiver có lại đúng key DES mà Sender đã sinh ra.

**Bước 6 — Cả hai bên dùng chung key DES để giải mã nội dung**

```python
iv = ciphertext_with_iv[:8]
body = ciphertext_with_iv[8:]
cipher = DES.new(des_key, DES.MODE_CBC, iv)
plaintext = unpad(cipher.decrypt(body), 8)
```

Cuối cùng, SHA-256 được tính lại trên plaintext và so sánh với hash trong packet để xác nhận dữ liệu không bị thay đổi trên đường truyền.

---

## 3. Luồng tổng hợp

```
RECEIVER                                    SENDER
keygen.py → public.pem ──────────────────→ load_public_key()
                                            sinh des_key, iv
                                            DES-CBC encrypt(plaintext)
                                            RSA-OAEP encrypt(des_key)  ← dùng public.pem
                                            build packet + gửi socket ───────────────→
recv socket                              ←─────────────────────────────────────────────
RSA-OAEP decrypt(enc_key) ← dùng private.pem
DES-CBC decrypt(ciphertext)
SHA-256 verify → OK / FAIL
```

---

## 4. Kết quả minh chứng

- File log Sender: `logs/sender_success.log`
- File log Receiver: `logs/receiver_success.log`
- File đầu ra: `sample_output.txt`

---

## 5. Nhận xét

RSA-OAEP đảm bảo key DES không bao giờ lộ trên đường truyền. SHA-256 phát hiện dữ liệu bị thay đổi sau giải mã. Hạn chế: DES có key 56-bit hiệu dụng, không còn an toàn cho hệ thống thật — nên thay bằng AES-GCM để vừa mã hóa vừa xác thực tích hợp.
