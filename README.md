# ObjectiveC_DDoS_Agent

> **⚠️ TUYÊN BỐ MIỄN TRỪ TRÁCH NHIỆM & CẢNH BÁO PHÁP LÝ ⚠️**
>
> Dự án này được cung cấp **chỉ cho mục đích giáo dục và nghiên cứu**. Nó minh họa các khái niệm liên quan đến việc gửi yêu cầu mạng (network requests) và quản lý vòng đời ứng dụng trên iOS.
>
> **TUYỆT ĐỐI KHÔNG SỬ DỤNG mã nguồn này để tấn công các mục tiêu mà bạn không có sự cho phép rõ ràng bằng văn bản để kiểm thử.** Việc thực hiện các cuộc tấn công từ chối dịch vụ (DoS) hoặc từ chối dịch vụ phân tán (DDoS) chống lại các mạng hoặc dịch vụ mà không được phép là **VI PHẠM PHÁP LUẬT** và **GÂY HẠI NGHIÊM TRỌNG**.
>
> Tác giả của dự án này **KHÔNG CHỊU BẤT KỲ TRÁCH NHIỆM PHÁP LÝ NÀO** và **KHÔNG CHỊU TRÁCH NHIỆM** cho bất kỳ việc sử dụng sai mục đích hoặc thiệt hại nào do mã nguồn này gây ra. Bạn hoàn toàn chịu trách nhiệm về hành động của mình. Hãy sử dụng mã này một cách có đạo đức và hợp pháp, chỉ trong các môi trường được kiểm soát (ví dụ: kiểm thử cơ sở hạ tầng của riêng bạn).

## Giới thiệu

Repository này chứa mã nguồn Objective-C cho một thành phần ứng dụng iOS cơ bản, được thiết kế để hoạt động như một client ("agent" hay "bot") trong kịch bản tấn công Từ chối dịch vụ phân tán (DDoS) mô phỏng. Nó đóng vai trò là Bằng chứng Khái niệm (Proof of Concept - POC) để khám phá các khía cạnh sau:

*   Thực hiện các yêu cầu HTTP đồng thời từ ứng dụng iOS.
*   Quản lý trạng thái ứng dụng qua các chuyển đổi nền/tiền cảnh (background/foreground).
*   Xử lý các lệnh điều khiển từ xa được lấy về qua HTTP.
*   Sử dụng `NSOperationQueue` để thực hiện đa luồng.
*   Xác định thiết bị cơ bản bằng `identifierForVendor`.
*   Lưu trữ và khôi phục trạng thái ứng dụng bằng `NSUserDefaults`.
*   Xử lý các vòng đời ứng dụng và tác vụ nền.

**Đây KHÔNG phải là một công cụ hoàn chỉnh cho môi trường sản xuất và chỉ dành cho mục đích học tập và kiểm thử có đạo đức.**

## Cách hoạt động chi tiết

Dự án bao gồm các thành phần chính sau:

### 1. Lớp `DDOS` (`DDOS.m` và `DDOS.h`)

Đây là thành phần cốt lõi, chịu trách nhiệm thực hiện logic chính.

*   **Khởi tạo Singleton (`sharedClient`):**
    *   Sử dụng `dispatch_once` để đảm bảo chỉ có một thực thể (instance) duy nhất của lớp `DDOS` tồn tại trong suốt vòng đời ứng dụng. Điều này ngăn chặn việc tạo ra nhiều bộ điều khiển tấn công.
*   **Khởi tạo (`init`):**
    *   Thiết lập các trình quan sát vòng đời ứng dụng (`setupAppLifecycleObservers`) để xử lý việc vào nền và quay lại tiền cảnh.
    *   Khôi phục trạng thái trước đó (nếu có) từ `NSUserDefaults` (`restoreState`).
    *   Thiết lập khả năng chạy nền cơ bản (`setupBackgroundNotification`, `startBackgroundTask`).
    *   Lấy link máy chủ điều khiển (C&C) ban đầu (nếu được cung cấp) (`getLink`).
    *   Tạo hoặc lấy UUID định danh duy nhất cho thiết bị (`generateAndStoreUUID`).
*   **Định danh Thiết bị (`generateAndStoreUUID`, `getUUID`):**
    *   Lấy `identifierForVendor` của thiết bị, một UUID duy nhất cho mỗi nhà cung cấp ứng dụng trên một thiết bị cụ thể.
    *   Lưu trữ UUID này vào `NSUserDefaults` để nó tồn tại qua các lần khởi chạy lại ứng dụng.
    *   UUID này được gửi đến máy chủ điều khiển để định danh client.
*   **Lấy Lệnh từ Máy chủ Điều khiển (`checkURL`, `getLink`, `setLink`):**
    *   Một `NSTimer` được thiết lập để gọi phương thức `checkURL` định kỳ (mặc định là 20 giây).
    *   `checkURL` gửi một yêu cầu POST đến URL máy chủ điều khiển (được cấu hình thông qua `setLink`). Yêu cầu này chứa `deviceUUID` của client.
    *   Nó mong đợi nhận được phản hồi JSON từ máy chủ chứa các hướng dẫn.
*   **Xử lý Lệnh (`handleJSONResponse`):**
    *   Phân tích cú pháp (parse) phản hồi JSON từ máy chủ. Các trường mong đợi bao gồm:
        *   `url`: URL mục tiêu để tấn công (Phải là `https://`).
        *   `start`: Cờ điều khiển (1 = bắt đầu/tiếp tục, 0 = dừng).
        *   `threads`: (Tùy chọn) Số luồng đồng thời để gửi yêu cầu (mặc định là 10 nếu không có hoặc không hợp lệ).
        *   `delay`: (Tùy chọn) Thời gian trễ (giây, dạng số thập phân) giữa các yêu cầu trên mỗi luồng (mặc định là 0.001 nếu không có hoặc không hợp lệ).
        *   `req`: (Tùy chọn) Loại yêu cầu cần gửi (ví dụ: `"get"`, `"post"`, `"get,post"`). Nếu không có, loại yêu cầu trước đó sẽ được giữ lại.
        *   `textnoti`: (Tùy chọn) Nội dung thông báo để hiển thị cho người dùng.
        *   `linknoti`: (Tùy chọn) URL để mở khi người dùng nhấn OK trên thông báo.
        *   `exit`: (Tùy chọn) Cờ yêu cầu ứng dụng thoát (1 = thoát).
    *   Cập nhật cấu hình `threads`, `delay`, và `requestType` nếu được cung cấp.
    *   Dựa trên giá trị `start` và `url`, quyết định bắt đầu (`startDDOSming`) hoặc dừng (`stopDDOSming`) quá trình gửi yêu cầu.
    *   Hiển thị cảnh báo (`showAlertWithText`) nếu `textnoti` được cung cấp. Sau khi đóng cảnh báo (hoặc mở link), ứng dụng sẽ thoát.
    *   Thoát ứng dụng ngay lập tức nếu `exit` là 1.

*   **Ví dụ Phản hồi JSON từ Máy chủ Điều khiển:**

    *   **Bắt đầu tấn công GET đến `example.com` với 50 luồng, độ trễ 0.01s:**
        ```json
        {
          "url": "https://example.com",
          "start": 1,
          "threads": 50,
          "delay": 0.01,
          "req": "get"
        }
        ```
    *   **Bắt đầu tấn công POST (với các loại ngẫu nhiên) đến `test-server.net` với 20 luồng:**
        ```json
        {
          "url": "https://test-server.net",
          "start": 1,
          "threads": 20,
          "req": "post"
        }
        ```
    *   **Bắt đầu tấn công cả GET và POST đến `test.org` (sử dụng threads và delay mặc định hoặc đã cấu hình trước đó):**
        ```json
        {
          "url": "https://test.org",
          "start": 1,
          "req": "get,post"
        }
        ```
    *   **Dừng mọi hoạt động tấn công:**
        ```json
        {
          "start": 0
        }
        ```
        *(Lưu ý: Không cần `url` khi dừng)*
    *   **Hiển thị thông báo và thoát ứng dụng:**
        ```json
        {
          "start": 0, // Thường nên dừng tấn công trước khi hiển thị thông báo
          "textnoti": "Cập nhật quan trọng đã hoàn tất. Vui lòng khởi động lại ứng dụng sau.",
          "exit": 0 // Sẽ tự thoát sau khi đóng alert
        }
        ```
    *   **Hiển thị thông báo, mở link và thoát:**
        ```json
        {
          "start": 0,
          "textnoti": "Đã có phiên bản mới! Nhấn OK để cập nhật.",
          "linknoti": "https://your-update-link.com",
          "exit": 0 // Sẽ tự thoát sau khi đóng alert/mở link
        }
        ```
    *   **Buộc ứng dụng thoát ngay lập tức:**
         ```json
        {
          "exit": 1
        }
        ```

*   **Thực hiện Gửi Yêu cầu (`startDDOSming`, `stopDDOSming`, các phương thức `send...Request`):**
    *   Nếu lệnh là `start`:
        *   Sử dụng `NSOperationQueue` với số lượng luồng (`maxConcurrentOperationCount`) được chỉ định.
        *   Thêm các `NSBlockOperation` vào hàng đợi. Mỗi operation chạy một vòng lặp `while` miễn là cờ `isDDOSming` là `YES` và `currentURL` hợp lệ.
        *   Trong vòng lặp, dựa trên cấu hình `requestType` (`req` từ JSON):
            *   Nếu chứa `"get"`, gửi yêu cầu GET (`sendGetRequestToURL`).
            *   Nếu chứa `"post"`, gửi yêu cầu POST với các loại dữ liệu và Content-Type ngẫu nhiên (`sendRandomPostRequestToURL`): `x-www-form-urlencoded`, `multipart/form-data`, `json`, `xml`, `text/plain`, `octet-stream`.
        *   Sử dụng User-Agent ngẫu nhiên (`randomUserAgent`) cho mỗi yêu cầu.
        *   Thêm độ trễ `delay` giữa các yêu cầu trên cùng một luồng bằng `[NSThread sleepForTimeInterval:]`.
    *   Nếu lệnh là `stop`, hủy tất cả các operation đang chạy trong `operationQueue`.
*   **Xử lý Vòng đời Ứng dụng (`appDidEnterBackground`, `appWillEnterForeground`, `saveState`, `restoreState`):**
    *   Khi ứng dụng vào nền: Lưu trạng thái (`isDDOSming`, `currentURL`, `requestType`) vào `NSUserDefaults` (`saveState`), dừng `NSTimer` kiểm tra lệnh, và yêu cầu thời gian chạy nền hạn chế (`startBackgroundTask`).
    *   Khi ứng dụng quay lại tiền cảnh: Khôi phục trạng thái (`restoreState`), khởi động lại `NSTimer` (`setupTimer`), dừng tác vụ nền (nếu có) (`stopBackgroundTask`), và tiếp tục tấn công nếu trạng thái được khôi phục là đang tấn công.
*   **Hiển thị Thông báo (`showAlertWithText`):**
    *   Hiển thị `UIAlertController`. Mở `linknoti` nếu có khi nhấn OK. Ứng dụng sẽ thoát sau khi alert bị đóng.

### 2. `.mm` nó tự khỏi chạy mã khi người dùng vào app (ờ tôi lười viết quá bạn tự check)

**Nhắc lại: Chỉ nhắm mục tiêu vào các máy chủ mà bạn sở hữu hoặc có quyền kiểm thử rõ ràng.**
