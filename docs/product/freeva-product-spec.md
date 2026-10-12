# Freeva --- Personal Finance Platform

> Ứng dụng quản lý tài chính cá nhân dành cho người Việt, tập trung vào
> việc giúp người dùng hiểu tiền của mình, kiểm soát chi tiêu và tiến
> tới tự do tài chính.

**Document:** Product & Application Specification\
**Product:** Freeva\
**Version:** 0.1\
**Status:** Draft

------------------------------------------------------------------------

## 1. Product Vision

Freeva là một ứng dụng quản lý tài chính cá nhân được thiết kế cho thói
quen tài chính của người Việt.

Mục tiêu không chỉ là ghi chép thu chi mà là tạo một hệ thống tài chính
cá nhân hoàn chỉnh:

-   Biết mình đang có bao nhiêu tiền.
-   Biết tiền đang nằm ở đâu.
-   Biết tiền đang được chi cho việc gì.
-   Biết mỗi tháng có thể tiết kiệm bao nhiêu.
-   Theo dõi ngân sách và các mục tiêu tài chính.
-   Theo dõi tài sản, nợ và giá trị tài sản ròng.
-   Dùng AI để phân tích và đưa ra insight dễ hiểu.
-   Từng bước giúp người dùng tiến tới tự do tài chính.

### Product principle

> **Track → Understand → Control → Improve → Achieve**

------------------------------------------------------------------------

# 2. Target Users

## 2.1 Primary users

Người Việt từ khoảng 18--40 tuổi:

-   Sinh viên mới đi làm.
-   Nhân viên văn phòng.
-   Developer / freelancer.
-   Người có nhiều tài khoản ngân hàng.
-   Người sử dụng ví điện tử.
-   Người bắt đầu lập ngân sách.
-   Người muốn tiết kiệm cho một mục tiêu lớn.
-   Người muốn xây dựng tài sản dài hạn.

## 2.2 User problems

### Problem 1 --- Không biết tiền đang đi đâu

Người dùng có nhiều giao dịch nhỏ:

-   Ăn uống.
-   Grab.
-   Shopee.
-   Cà phê.
-   Subscription.
-   Mua sắm.

Nhưng cuối tháng không biết tổng chi tiêu thực tế là bao nhiêu.

### Problem 2 --- Có nhiều tài khoản

Một người có thể sử dụng:

-   Tiền mặt.
-   Vietcombank.
-   Techcombank.
-   MB Bank.
-   MoMo.
-   ZaloPay.
-   Thẻ tín dụng.

Khó nhìn được tổng tài sản tại một thời điểm.

### Problem 3 --- Ghi chép tài chính quá mất thời gian

Nếu mỗi giao dịch phải nhập quá nhiều trường, người dùng sẽ bỏ cuộc.

### Problem 4 --- Biết mình tiêu nhiều nhưng không biết nên cải thiện thế nào

App cần chuyển dữ liệu thành insight và hành động.

### Problem 5 --- Thiếu mục tiêu dài hạn

Người dùng muốn:

-   Mua nhà.
-   Mua xe.
-   Du lịch.
-   Quỹ khẩn cấp.
-   Nghỉ hưu sớm.

nhưng không biết cần tiết kiệm bao nhiêu mỗi tháng.

------------------------------------------------------------------------

# 3. Product Goals

## MVP Goals

Freeva v1 phải giải quyết được 5 câu hỏi:

1.  Tôi đang có bao nhiêu tiền?
2.  Tiền của tôi đang nằm ở đâu?
3.  Tháng này tôi đã tiêu bao nhiêu?
4.  Tôi đang tiêu tiền vào đâu?
5.  Tôi có đang tiến gần hơn tới mục tiêu tài chính không?

## Non-goals của MVP

Chưa cần triển khai ngay:

-   Giao dịch ngân hàng trực tiếp.
-   Trading.
-   Crypto.
-   Tư vấn đầu tư cá nhân hóa có tính chất tài chính chuyên nghiệp.
-   Cho vay.
-   Thanh toán.
-   Marketplace.

------------------------------------------------------------------------

# 4. Core User Journey

## First-time user

``` text
Install App
    ↓
Create Account
    ↓
Select Currency / Locale
    ↓
Create First Account
    ↓
Add Initial Balance
    ↓
Select / Create Categories
    ↓
Set Monthly Budget (optional)
    ↓
Create Financial Goal (optional)
    ↓
Home Dashboard
```

## Daily usage

``` text
Open App
    ↓
Tap "+"
    ↓
Expense / Income / Transfer
    ↓
Enter Amount
    ↓
Select Category
    ↓
Select Account
    ↓
Save
    ↓
Dashboard updates
```

## Monthly review

``` text
Monthly Review
    ↓
Income
    ↓
Expenses
    ↓
Savings
    ↓
Budget
    ↓
Net Worth
    ↓
AI Insights
    ↓
Action
```

------------------------------------------------------------------------

# 5. Information Architecture

``` text
Freeva
│
├── Home
│
├── Transactions
│   ├── All
│   ├── Income
│   ├── Expense
│   └── Transfer
│
├── Add Transaction
│   ├── Expense
│   ├── Income
│   ├── Transfer
│   └── Scan Receipt
│
├── Accounts
│   ├── Cash
│   ├── Bank
│   ├── E-wallet
│   ├── Credit Card
│   ├── Saving
│   └── Investment
│
├── Budget
│
├── Goals
│
├── Reports
│
├── AI
│   ├── Insights
│   ├── Ask Freeva
│   ├── Forecast
│   └── What-if
│
└── Settings
```

------------------------------------------------------------------------

# 6. Home Dashboard

Home là màn hình quan trọng nhất.

## 6.1 Financial overview

Hiển thị:

-   Tổng tiền hiện có.
-   Tổng tài sản.
-   Tổng nợ.
-   Net worth.
-   Thay đổi so với tháng trước.

Ví dụ:

``` text
Tài sản ròng

125.500.000đ

+4,2% so với tháng trước
```

## 6.2 Monthly cash flow

``` text
Thu nhập       30.000.000đ
Chi tiêu       18.200.000đ
Tiết kiệm      11.800.000đ
```

## 6.3 Budget summary

``` text
Ngân sách tháng

18.200.000 / 22.000.000đ

██████████████░░ 83%
```

## 6.4 Goal summary

``` text
Quỹ dự phòng

45.000.000 / 60.000.000đ

75%
```

## 6.5 Recent transactions

Hiển thị 5--10 giao dịch gần nhất.

## 6.6 AI insight

Hiển thị insight có giá trị hành động.

Ví dụ:

> Chi tiêu ăn uống tháng này cao hơn 18% so với tháng trước.

CTA:

> Xem phân tích

------------------------------------------------------------------------

# 7. Transaction Management

Transaction là core feature.

## 7.1 Transaction types

### Expense

``` text
amount > 0
type = EXPENSE
```

### Income

``` text
amount > 0
type = INCOME
```

### Transfer

Chuyển tiền giữa hai account.

Transfer không được tính là income hoặc expense.

------------------------------------------------------------------------

# 8. Create Transaction

## Expense

Required:

-   Amount
-   Account
-   Category
-   Date

Optional:

-   Note
-   Merchant
-   Location
-   Attachment
-   Tags

## Income

Required:

-   Amount
-   Account
-   Category
-   Date

Optional:

-   Source
-   Note
-   Attachment

## Transfer

Required:

-   From account
-   To account
-   Amount
-   Date

Optional:

-   Note

------------------------------------------------------------------------

# 9. Quick Add UX

Đây là interaction quan trọng nhất.

Tap `+`:

``` text
+ Giao dịch

[ Chi tiêu ]

[ Thu nhập ]

[ Chuyển tiền ]

[ Scan hóa đơn ]
```

Mục tiêu:

> Người dùng có thể ghi một giao dịch thông thường trong dưới 10 giây.

------------------------------------------------------------------------

# 10. Categories

Freeva cung cấp category mặc định dành cho người Việt.

## Expense categories

-   Ăn uống
-   Cà phê
-   Mua sắm
-   Đi lại
-   Nhà ở
-   Điện nước
-   Internet
-   Điện thoại
-   Sức khỏe
-   Giáo dục
-   Giải trí
-   Du lịch
-   Gia đình
-   Quà tặng
-   Subscription
-   Bảo hiểm
-   Thuế / phí
-   Khác

## Income categories

-   Lương
-   Thưởng
-   Freelance
-   Kinh doanh
-   Đầu tư
-   Quà tặng
-   Hoàn tiền
-   Khác

## Custom categories

User có thể:

-   Create.
-   Rename.
-   Archive.
-   Change icon.
-   Change color.
-   Create subcategory.

------------------------------------------------------------------------

# 11. Accounts

Account đại diện cho nơi tiền đang tồn tại.

## Account types

``` text
Cash
Bank
E-wallet
Credit Card
Saving
Investment
Other
```

## Account properties

-   Name.
-   Type.
-   Currency.
-   Initial balance.
-   Current balance.
-   Account number hint (optional, masked).
-   Color/icon.
-   Archived status.

## Example

``` text
Tiền mặt          2.000.000đ
Techcombank      35.000.000đ
Vietcombank      12.000.000đ
MoMo              1.500.000đ
Savings          80.000.000đ
Credit Card      -8.500.000đ
```

------------------------------------------------------------------------

# 12. Balance Rules

Account balance phải được tính từ transaction ledger.

Concept:

``` text
Initial Balance
+
Income
-
Expense
+
Transfer In
-
Transfer Out
=
Current Balance
```

Không nên để client tự quyết định balance.

Backend là source of truth.

------------------------------------------------------------------------

# 13. Transfer

Transfer là một transaction đặc biệt.

Ví dụ:

``` text
Techcombank
-5.000.000đ
       ↓
Savings
+5.000.000đ
```

Không tính 5 triệu này vào expense.

------------------------------------------------------------------------

# 14. Recurring Transactions

Cho phép tạo giao dịch định kỳ.

Ví dụ:

-   Tiền thuê nhà.
-   Netflix.
-   Spotify.
-   Internet.
-   Điện thoại.
-   Lương.
-   Tiền trả nợ.

## Frequency

-   Daily.
-   Weekly.
-   Monthly.
-   Yearly.
-   Custom.

## Fields

-   Amount.
-   Account.
-   Category.
-   Frequency.
-   Start date.
-   End date.
-   Next execution date.
-   Active/inactive.

------------------------------------------------------------------------

# 15. Budget

Budget giúp người dùng kiểm soát chi tiêu.

## Budget types

### Monthly overall budget

Ví dụ:

``` text
22.000.000đ / tháng
```

### Category budget

``` text
Ăn uống       4.000.000đ
Mua sắm       2.000.000đ
Đi lại        1.500.000đ
Giải trí      1.000.000đ
```

## Budget states

``` text
< 70%     Healthy
70–90%    Warning
> 90%     Critical
> 100%    Over budget
```

## Alerts

-   70%.
-   80%.
-   90%.
-   100%.

Người dùng có thể tùy chỉnh threshold.

------------------------------------------------------------------------

# 16. Financial Goals

Goal giúp biến tiết kiệm thành mục tiêu cụ thể.

## Default goals

-   Quỹ khẩn cấp.
-   Mua nhà.
-   Mua xe.
-   Du lịch.
-   Học tập.
-   Đám cưới.
-   Nghỉ hưu.

## Goal properties

-   Name.
-   Target amount.
-   Current amount.
-   Target date.
-   Account.
-   Monthly contribution.
-   Icon.
-   Color.

## Goal calculation

Ví dụ:

``` text
Mục tiêu: 120.000.000đ
Hiện tại: 40.000.000đ
Còn thiếu: 80.000.000đ
Còn: 10 tháng

Cần tiết kiệm:
8.000.000đ / tháng
```

------------------------------------------------------------------------

# 17. Debt Management

Theo dõi các khoản nợ.

## Debt types

-   Credit card.
-   Personal loan.
-   Mortgage.
-   Borrowed from person.
-   Other.

## Fields

-   Name.
-   Principal.
-   Remaining principal.
-   Interest rate.
-   Payment amount.
-   Payment frequency.
-   Due date.
-   Start date.
-   End date.

## Debt dashboard

``` text
Tổng nợ
85.000.000đ

Đã trả
35.000.000đ

Còn lại
50.000.000đ
```

------------------------------------------------------------------------

# 18. Credit Card

Credit card cần được xử lý riêng vì:

-   Có available credit.
-   Có outstanding balance.
-   Có statement cycle.
-   Có payment due date.

## Data

``` text
Credit Limit
Available Credit
Outstanding
Statement Date
Payment Due Date
Minimum Payment
```

## Alert

-   Sắp đến ngày thanh toán.
-   Outstanding cao.
-   Sắp vượt credit limit.

------------------------------------------------------------------------

# 19. Net Worth

Net worth:

``` text
Total Assets
-
Total Liabilities
=
Net Worth
```

## Assets

-   Cash.
-   Bank.
-   Savings.
-   Investment.
-   Other assets.

## Liabilities

-   Credit card.
-   Loans.
-   Mortgage.
-   Other debts.

## History

Tạo snapshot theo ngày/tháng để hiển thị:

``` text
Jan   80M
Feb   85M
Mar   91M
Apr   97M
May  105M
Jun  112M
```

------------------------------------------------------------------------

# 20. Reports

## Income report

-   Total income.
-   Income by category.
-   Income trend.

## Expense report

-   Total expense.
-   Expense by category.
-   Expense trend.
-   Top merchants.

## Cash flow

``` text
Income
Expense
Savings
```

## Savings rate

``` text
Savings Rate =
Savings / Income × 100
```

## Net worth trend

Chart theo:

-   7 days.
-   30 days.
-   3 months.
-   6 months.
-   1 year.
-   All time.

------------------------------------------------------------------------

# 21. Monthly Financial Review

Cuối tháng Freeva tạo một báo cáo:

``` text
Tháng 8

Thu nhập       30M
Chi tiêu       18.2M
Tiết kiệm      11.8M

Savings rate   39.3%

Top category
1. Nhà ở       7M
2. Ăn uống     3.2M
3. Đi lại      1.5M
```

Sau đó đưa ra AI insights.

------------------------------------------------------------------------

# 22. AI Features

AI không phải một chatbot độc lập.

AI phải được xây trên financial data của user.

## 22.1 Automatic transaction categorization

Ví dụ:

``` text
"GrabFood 85.000"
```

AI đề xuất:

``` text
Category: Ăn uống
Confidence: 97%
```

User có thể sửa.

Hệ thống học mapping merchant → category.

------------------------------------------------------------------------

# 23. Receipt OCR

User chụp hóa đơn.

``` text
Camera
  ↓
OCR
  ↓
Merchant
Date
Items
Total
  ↓
AI classification
  ↓
Transaction draft
```

Ví dụ:

``` text
Merchant: WinMart
Total: 356.000đ
Date: 12/08/2026
Category: Mua sắm
```

User phải xác nhận trước khi tạo transaction.

------------------------------------------------------------------------

# 24. AI Insights

AI phân tích:

-   Spending trend.
-   Category changes.
-   Budget risk.
-   Savings rate.
-   Recurring expenses.
-   Unusual transactions.
-   Goal progress.
-   Debt progress.

Ví dụ:

> Chi tiêu mua sắm tháng này tăng 32% so với mức trung bình 3 tháng gần
> đây.

------------------------------------------------------------------------

# 25. AI Chat --- Ask Freeva

User có thể hỏi:

> Tháng này tôi tiêu bao nhiêu cho ăn uống?

> Tôi đang tiết kiệm bao nhiêu phần trăm thu nhập?

> Nếu mỗi tháng tiết kiệm 10 triệu thì bao lâu mua được căn nhà 2 tỷ?

> Khoản chi nào tăng nhiều nhất tháng này?

> Tôi có đang đi đúng tiến độ quỹ khẩn cấp không?

AI phải lấy số liệu từ Finance Query Service trước khi trả lời.

LLM không được tự tính hoặc tự nhớ financial facts.

------------------------------------------------------------------------

# 26. AI Forecast

Dự đoán:

-   Chi tiêu cuối tháng.
-   Cash flow.
-   Goal completion date.
-   Savings trajectory.

Ví dụ:

``` text
Nếu giữ mức chi tiêu hiện tại:

Dự kiến cuối tháng:
Expense ≈ 20.4M

Budget:
22M

Risk:
Medium
```

Forecast phải ghi rõ đây là dự đoán, không phải dữ liệu chắc chắn.

------------------------------------------------------------------------

# 27. AI What-if

Cho phép mô phỏng.

Ví dụ:

> Nếu tôi giảm ăn uống 1 triệu/tháng?

Output:

``` text
Tiết kiệm thêm:
1.000.000đ / tháng

Một năm:
+12.000.000đ

Quỹ mua nhà:
Đạt sớm hơn khoảng 1,5 tháng
```

------------------------------------------------------------------------

# 28. AI Safety Principles

AI không được:

-   Bịa số liệu.
-   Tự tạo transaction.
-   Tự thay đổi budget.
-   Tự chuyển tiền.
-   Tự thay đổi goal.
-   Đưa ra lời khuyên đầu tư mang tính chắc chắn.
-   Giả định dữ liệu không tồn tại.

Mọi action có tác động đến financial data phải yêu cầu user
confirmation.

------------------------------------------------------------------------

# 29. Search & Filter

Transaction search hỗ trợ:

-   Keyword.
-   Category.
-   Account.
-   Amount.
-   Date.
-   Type.
-   Merchant.
-   Tag.

Ví dụ:

``` text
Ăn uống
+ Techcombank
+ 01/08 → 31/08
```

------------------------------------------------------------------------

# 30. Tags

User có thể tạo tag:

-   Work.
-   Personal.
-   Family.
-   Travel.
-   Business.

Một transaction có thể có nhiều tags.

------------------------------------------------------------------------

# 31. Attachments

Transaction có thể đính kèm:

-   Receipt.
-   Invoice.
-   Screenshot.
-   Document.

Storage:

``` text
Object Storage
```

Database chỉ lưu metadata/reference.

------------------------------------------------------------------------

# 32. Notifications

Notification types:

## Financial

-   Budget 80%.
-   Budget exceeded.
-   Goal contribution reminder.
-   Debt due.
-   Credit card payment due.
-   Recurring transaction upcoming.

## AI

-   Monthly review available.
-   New insight.

## Product

-   Security alert.
-   New feature.
-   Account activity.

User có thể bật/tắt từng loại.

------------------------------------------------------------------------

# 33. Offline Support

Mobile nên hỗ trợ offline ở mức cơ bản.

Khi mất mạng:

``` text
Create transaction
      ↓
Local database
      ↓
Pending sync
      ↓
Internet returns
      ↓
Backend sync
```

Transaction local cần có:

-   UUID.
-   Sync status.
-   Created locally timestamp.
-   Server timestamp.
-   Retry count.

------------------------------------------------------------------------

# 34. Data Export

User có thể export:

-   CSV.
-   JSON.

Ví dụ CSV:

``` text
date,type,amount,category,account,note
2026-08-12,expense,85000,Ăn uống,Techcombank,GrabFood
```

------------------------------------------------------------------------

# 35. Account Security

Authentication:

-   Email/password.
-   Google Sign-In.
-   Apple Sign-In.

Security:

-   Biometric lock.
-   PIN.
-   Secure token storage.
-   Session management.

------------------------------------------------------------------------

# 36. Privacy

User có quyền:

-   Export data.
-   Delete account.
-   Delete transactions.
-   Disable AI features.
-   Manage analytics consent.
-   Manage notifications.

Financial data phải được coi là sensitive data.

------------------------------------------------------------------------

# 37. Subscription

Freeva có thể dùng freemium.

## Free

-   Basic transaction tracking.
-   Accounts.
-   Categories.
-   Basic budget.
-   Basic reports.

## Premium

-   AI insights.
-   AI chat.
-   OCR.
-   Advanced reports.
-   Forecast.
-   What-if.
-   Advanced goals.
-   Unlimited recurring transactions.

Không nên paywall các chức năng core như ghi chép thu chi cơ bản.

------------------------------------------------------------------------

# 38. Admin Web

Admin phục vụ vận hành sản phẩm.

## Dashboard

Metrics:

-   Total users.
-   Active users.
-   New users.
-   Transactions.
-   AI requests.
-   OCR requests.
-   Crash/error rate.

## User management

-   Search.
-   View account status.
-   Disable.
-   Delete.
-   Subscription.
-   Support access.

Admin không được mặc định xem toàn bộ financial data của user.

------------------------------------------------------------------------

# 39. Feature Flags

Các feature có thể bật/tắt từ server:

``` text
ai_chat
ai_insights
ocr
forecast
investment
family
bank_import
```

Có thể rollout theo:

-   Percentage.
-   User group.
-   Environment.

------------------------------------------------------------------------

# 40. Analytics

Theo dõi product events:

``` text
app_open
sign_up
account_created
transaction_created
transaction_updated
budget_created
goal_created
receipt_scanned
ai_question_asked
report_viewed
subscription_started
```

Không đưa raw financial values vào analytics events nếu không cần thiết.

------------------------------------------------------------------------

# 41. Backend Architecture

``` text
NestJS
│
├── Auth
├── Users
├── Accounts
├── Transactions
├── Categories
├── Budgets
├── Goals
├── Debts
├── Reports
├── Notifications
├── AI
├── Receipts
└── Subscriptions
```

Infrastructure:

``` text
PostgreSQL
Redis
Object Storage
Queue
FCM/APNs
AI Provider
```

------------------------------------------------------------------------

# 42. Database Core Entities

``` text
users

accounts

categories

transactions

transaction_tags

tags

recurring_transactions

budgets

budget_categories

goals

goal_contributions

debts

debt_payments

net_worth_snapshots

attachments

notifications

ai_conversations

ai_messages

ai_insights

subscriptions

audit_logs
```

------------------------------------------------------------------------

# 43. Money Representation

Không dùng floating point cho financial amount.

Nên dùng:

``` text
BIGINT
```

với đơn vị nhỏ nhất.

Ví dụ:

``` text
12.500.000 VND
→ 12500000
```

Currency:

``` text
VND
USD
...
```

Mọi financial calculation phải được thực hiện ở backend với logic
deterministic.

------------------------------------------------------------------------

# 44. API Principles

API:

``` text
REST
JSON
HTTPS
```

Ví dụ:

``` text
GET    /v1/accounts
POST   /v1/accounts

GET    /v1/transactions
POST   /v1/transactions
PATCH  /v1/transactions/:id
DELETE /v1/transactions/:id

GET    /v1/budgets
POST   /v1/budgets

GET    /v1/goals
POST   /v1/goals

GET    /v1/reports/monthly
GET    /v1/net-worth
```

Versioning:

``` text
/v1/...
```

------------------------------------------------------------------------

# 45. Mobile Architecture

Flutter:

``` text
lib/
│
├── app/
├── core/
├── design_system/
│
└── features/
    ├── auth/
    ├── home/
    ├── transactions/
    ├── accounts/
    ├── budgets/
    ├── goals/
    ├── debts/
    ├── reports/
    ├── ai/
    └── settings/
```

Architecture:

``` text
Presentation
     ↓
Domain
     ↓
Data
     ↓
Infrastructure
```

MVVM + Clean Architecture + feature-based structure.

------------------------------------------------------------------------

# 46. Design System

## Design principles

1.  Clear.
2.  Trustworthy.
3.  Calm.
4.  Minimal.
5.  Data-first.
6.  Actionable.

## Color semantics

``` text
Primary
Success / Income
Danger / Expense
Warning
Neutral
```

Không hard-code màu trực tiếp trong feature.

## Typography

-   Inter / Noto Sans.
-   Clear hierarchy.
-   Large financial numbers.

## Spacing

``` text
4
8
12
16
20
24
32
40
48
64
```

## Radius

``` text
8
12
16
20
999
```

------------------------------------------------------------------------

# 47. Core UI Components

``` text
Button
IconButton
TextField
AmountField
SelectField
Card
BottomSheet
Dialog
Chip
TabBar
AppBar
Avatar
Progress
Skeleton
EmptyState
ErrorState
```

## Finance components

``` text
MoneyAmount
BalanceCard
AccountCard
TransactionItem
TransactionGroup
CategoryIcon
BudgetProgress
GoalProgress
NetWorthCard
CashFlowChart
ExpenseChart
FinancialInsightCard
AIMessage
```

------------------------------------------------------------------------

# 48. Main Navigation

Recommended:

``` text
Home
Transactions
+
Insights
More
```

`+` là action chính.

Quick add:

``` text
Expense
Income
Transfer
Scan Receipt
```

------------------------------------------------------------------------

# 49. Error & Empty States

Mọi feature phải có:

-   Loading state.
-   Empty state.
-   Error state.
-   Offline state.
-   Success state.

Ví dụ transaction empty:

> Chưa có giao dịch nào.

CTA:

> -   Ghi giao dịch đầu tiên

Không chỉ hiển thị một màn hình trắng.

------------------------------------------------------------------------

# 50. Production Requirements

Trước khi launch cần có:

## Infrastructure

-   Development.
-   Staging.
-   Production.
-   Database backup.
-   Monitoring.
-   Error tracking.
-   Logging.

## Security

-   TLS.
-   Secure token storage.
-   Rate limiting.
-   Input validation.
-   RBAC.
-   Audit log.
-   Secret management.

## Mobile

-   Crash reporting.
-   Analytics.
-   App version management.
-   Remote config / feature flags.

## Backend

-   Unit tests.
-   Integration tests.
-   E2E tests.
-   Database migrations.
-   Health checks.

------------------------------------------------------------------------

# 51. MVP Scope

MVP nên tập trung vào:

### Authentication

-   Email.
-   Google.
-   Apple.
-   Biometric lock.

### Accounts

-   Create account.
-   Edit account.
-   Archive account.
-   Balance.

### Categories

-   Default categories.
-   Custom categories.

### Transactions

-   Expense.
-   Income.
-   Transfer.
-   Search.
-   Filter.
-   Edit.
-   Delete.

### Dashboard

-   Balance.
-   Income.
-   Expense.
-   Savings.
-   Recent transactions.

### Budget

-   Monthly budget.
-   Category budget.
-   Budget progress.

### Goals

-   Create goal.
-   Add contribution.
-   Goal progress.

### Reports

-   Income.
-   Expense.
-   Category.
-   Cash flow.

### Basic AI

-   Automatic categorization.
-   Basic insights.

------------------------------------------------------------------------

# 52. Post-MVP

Sau MVP:

``` text
Phase 2
├── Recurring transactions
├── Debt
├── Credit card
├── Net worth
├── Monthly review
└── Advanced reports

Phase 3
├── OCR
├── AI Chat
├── Forecast
├── What-if
└── AI financial coach

Phase 4
├── Bank statement import
├── Investment tracking
├── Family finance
└── Advanced automation
```

------------------------------------------------------------------------

# 53. Vietnam-specific Features

Freeva nên ưu tiên các hành vi phổ biến tại Việt Nam.

## Currency

Default:

``` text
VND
```

Format:

``` text
12.500.000đ
```

## Merchant recognition

Nhận diện:

``` text
Grab
Shopee
Lazada
WinMart
Circle K
Highlands
The Coffee House
```

và tự đề xuất category.

## Vietnamese categories

Category mặc định phải phản ánh hành vi tiêu dùng tại Việt Nam.

## Bank statement import

Giai đoạn sau có thể hỗ trợ import:

-   CSV.
-   Excel.
-   PDF bank statement.

Không cần kết nối ngân hàng trực tiếp ngay từ MVP.

------------------------------------------------------------------------

# 54. Success Metrics

## Activation

-   \% user tạo account đầu tiên.
-   \% user tạo transaction đầu tiên.

## Engagement

-   Transactions/user/month.
-   Active users.
-   Monthly review usage.

## Retention

-   D1.
-   D7.
-   D30.

## Financial behavior

-   \% users tạo budget.
-   \% users tạo goal.
-   \% users xem reports.

## AI

-   AI requests/user.
-   AI acceptance rate.
-   AI correction rate.
-   OCR success rate.

------------------------------------------------------------------------

# 55. Product Quality Principles

Freeva không chỉ cần "nhiều feature".

Ưu tiên:

``` text
Correctness
>
Trust
>
Usability
>
Performance
>
Features
```

Đặc biệt:

> Một app tài chính thà thiếu 10 tính năng còn hơn tính sai số dư 1 lần.

------------------------------------------------------------------------

# 56. Recommended Development Order

``` text
1. Project foundation
2. Design System
3. Authentication
4. Database
5. Accounts
6. Categories
7. Transactions
8. Transfer
9. Home Dashboard
10. Budget
11. Goals
12. Reports
13. Recurring transactions
14. Debt / Credit Card
15. Net Worth
16. AI categorization
17. AI insights
18. OCR
19. AI Chat
20. Forecast / What-if
21. Admin
22. Analytics
23. Security hardening
24. Subscription
25. Store launch
```

------------------------------------------------------------------------

# 57. Definition of a Successful v1

Freeva v1 được xem là thành công khi một người dùng mới có thể:

``` text
Sign up
   ↓
Tạo các tài khoản
   ↓
Nhập số dư
   ↓
Ghi giao dịch
   ↓
Theo dõi chi tiêu
   ↓
Tạo ngân sách
   ↓
Tạo mục tiêu
   ↓
Xem báo cáo
   ↓
Hiểu tình hình tài chính
   ↓
Nhận insight
```

và có thể sử dụng app liên tục trong nhiều tháng mà không cảm thấy:

-   Quá phức tạp.
-   Phải nhập liệu quá nhiều.
-   Không hiểu số liệu.
-   Không tin tưởng kết quả.

------------------------------------------------------------------------

# 58. Product North Star

Freeva không nên được định vị đơn giản là:

> "Ứng dụng ghi chép chi tiêu."

Mà nên hướng tới:

> **"Your personal financial operating system."**

Một hệ thống giúp người dùng:

``` text
Know your money
       ↓
Control your spending
       ↓
Build your savings
       ↓
Grow your assets
       ↓
Reach financial freedom
```

------------------------------------------------------------------------

## Final Product Structure

``` text
FREEVA
│
├── 📱 Mobile App
│   ├── Home
│   ├── Transactions
│   ├── Accounts
│   ├── Budget
│   ├── Goals
│   ├── Reports
│   ├── AI
│   └── Settings
│
├── 🖥️ Admin
│   ├── Users
│   ├── Analytics
│   ├── AI Monitoring
│   ├── Feature Flags
│   └── Audit Logs
│
├── ⚙️ Backend
│   ├── Finance Engine
│   ├── AI Engine
│   ├── Notification
│   ├── Authentication
│   └── Subscription
│
└── 🗄️ Infrastructure
    ├── PostgreSQL
    ├── Redis
    ├── Object Storage
    ├── Queue
    └── Monitoring
```

**Core philosophy:**

> Freeva should make personal finance **simple enough to use every day,
> accurate enough to trust, and intelligent enough to help users make
> better financial decisions.**
