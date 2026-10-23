import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/theme_context.dart';
import '../../theme/tokens.g.dart';
import '../allocation_bar.dart';
import '../balance_card.dart';
import '../empty_state.dart';
import '../error_retry.dart';
import '../freeva_banner.dart';
import '../freeva_bottom_nav.dart';
import '../freeva_button.dart';
import '../freeva_card.dart';
import '../freeva_dialog.dart';
import '../freeva_sheet.dart';
import '../freeva_toast.dart';
import '../money_display.dart';
import '../progress_bar.dart';
import '../settings_group.dart';
import '../settings_row.dart';
import '../skeleton.dart';
import '../transaction_row.dart';

// Debug gallery sections. Fixture text only.

class GalleryCards extends StatelessWidget {
  const GalleryCards({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Cards'),
        WashSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng số dư · 4 ví',
                style: FreevaTypography.bodyS.copyWith(color: c.balanceCardFg),
              ),
              MoneyDisplay(minor: BigInt.from(48250000), currency: 'VND'),
              const SizedBox(height: FreevaSpace.s4),
              Row(
                children: [
                  Expanded(
                    child: WashStatTile(
                      label: 'Thu',
                      value: MoneyDisplay(
                        minor: BigInt.from(18500000),
                        currency: 'VND',
                        tone: MoneyTone.income,
                        style: FreevaTypography.titleM,
                        showCurrency: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: FreevaSpace.s2),
                  Expanded(
                    child: WashStatTile(
                      label: 'Chi',
                      value: MoneyDisplay(
                        minor: BigInt.from(9320000),
                        currency: 'VND',
                        tone: MoneyTone.expense,
                        style: FreevaTypography.titleM,
                        showCurrency: false,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        FreevaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Thẻ tín dụng TCB'),
              const SizedBox(height: FreevaSpace.s2),
              FreevaProgressBar(value: .31, color: c.actionInk),
              const SizedBox(height: FreevaSpace.s4),
              AllocationBar(
                parts: [
                  AllocationPart(38, c.data1),
                  AllocationPart(24, c.data2),
                  AllocationPart(18, c.data3),
                  AllocationPart(20, c.dataMuted),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GalleryLists extends StatelessWidget {
  const GalleryLists({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Lists'),
        FreevaCard(
          list: true,
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
          child: Column(
            children: [
              TransactionRow(
                icon: LucideIcons.utensils,
                title: 'Phở Thìn',
                subtitle: 'Tiền mặt',
                tags: const ['#đi-làm'],
                semanticsLabel: 'trừ 65 nghìn đồng, Phở Thìn',
                amount: MoneyDisplay(
                  minor: BigInt.from(65000),
                  currency: 'VND',
                  tone: MoneyTone.expense,
                  style: FreevaTypography.titleM,
                  showCurrency: false,
                ),
              ),
              TransactionRow(
                icon: LucideIcons.banknote,
                title: 'Lương tháng 10',
                subtitle: 'Thu nhập · Vietcombank',
                tone: MoneyTone.income,
                semanticsLabel: 'cộng 18 triệu 500 nghìn đồng',
                amount: MoneyDisplay(
                  minor: BigInt.from(18500000),
                  currency: 'VND',
                  tone: MoneyTone.income,
                  style: FreevaTypography.titleM,
                  showCurrency: false,
                ),
              ),
            ],
          ),
        ),
        SettingsGroup(
          title: 'Ứng dụng',
          children: [
            SettingsRow.toggle(
              icon: LucideIcons.eyeOff,
              title: 'Ẩn số dư',
              on: true,
              onChanged: (_) {},
            ),
            SettingsRow(
              icon: LucideIcons.languages,
              title: 'Ngôn ngữ',
              value: 'Tiếng Việt',
              onTap: () {},
            ),
            SettingsRow(
              icon: LucideIcons.logOut,
              title: 'Đăng xuất',
              destructive: true,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class GalleryFeedback extends StatelessWidget {
  const GalleryFeedback({super.key});

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: FreevaSpace.s3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Feedback'),
        const FreevaBanner(
          message: 'Đang ngoại tuyến · Số liệu lúc 09:30',
          detail: 'Vẫn ghi chi được.',
          icon: LucideIcons.cloudOff,
        ),
        gap,
        const FreevaBanner(
          message: 'Có đăng nhập mới trên thiết bị khác',
          icon: LucideIcons.shieldAlert,
          tone: FreevaBannerTone.warning,
        ),
        gap,
        const FreevaCard(
          child: EmptyState(
            title: 'Chưa có giao dịch',
            message: 'Ghi khoản chi đầu tiên chỉ mất vài giây.',
            actionLabel: 'Ghi khoản chi',
          ),
        ),
        gap,
        const FreevaCard(list: true, child: SkeletonRows(count: 2)),
        gap,
        ErrorRetry(
          title: 'Không tải được ví',
          message: 'Kiểm tra kết nối rồi thử lại',
          onRetry: () {},
        ),
        gap,
        Wrap(
          spacing: 8,
          children: [
            FreevaButton(
              label: 'Toast',
              size: FreevaButtonSize.xs,
              variant: FreevaButtonVariant.secondary,
              onPressed: () => showFreevaToast(
                context,
                message: 'Đã lưu khoản chi 65.000 ₫',
                icon: LucideIcons.circleCheck,
                actionLabel: 'Hoàn tác',
                onAction: () {},
                aboveNav: false,
              ),
            ),
            FreevaButton(
              label: 'Dialog',
              size: FreevaButtonSize.xs,
              variant: FreevaButtonVariant.secondary,
              onPressed: () => showFreevaConfirm(
                context: context,
                title: 'Xoá giao dịch này?',
                message: 'Có thể khôi phục trong mục Đã xoá.',
                cancelLabel: 'Huỷ',
                confirmLabel: 'Xoá',
                destructive: true,
              ),
            ),
            FreevaButton(
              label: 'Sheet',
              size: FreevaButtonSize.xs,
              variant: FreevaButtonVariant.secondary,
              onPressed: () => showFreevaSheet<void>(
                context: context,
                title: 'Chọn ví',
                subtitle: 'Khoản chi sẽ trừ vào ví này',
                builder: (_) => const SizedBox(height: 160),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class GalleryNav extends StatelessWidget {
  const GalleryNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Navigation'),
        FreevaBottomNav(
          currentIndex: 0,
          onSelect: (_) {},
          onAdd: () {},
          addLabel: 'Ghi giao dịch',
          items: const [
            FreevaNavItem(icon: LucideIcons.house, label: 'Tổng quan'),
            FreevaNavItem(icon: LucideIcons.list, label: 'Giao dịch'),
            FreevaNavItem(icon: LucideIcons.chartPie, label: 'Báo cáo'),
            FreevaNavItem(icon: LucideIcons.user, label: 'Cá nhân'),
          ],
        ),
      ],
    );
  }
}
