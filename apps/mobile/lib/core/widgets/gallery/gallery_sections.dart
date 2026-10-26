import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.g.dart';
import '../amount_keypad.dart';
import '../freeva_button.dart';
import '../freeva_chip.dart';
import '../freeva_icon_button.dart';
import '../freeva_pill_field.dart';
import '../freeva_segmented.dart';
import '../freeva_text_field.dart';
import '../money_display.dart';
import '../selectable_card.dart';
import '../settings_group.dart';

// Debug gallery sections. Fixture text only.

class GalleryButtons extends StatelessWidget {
  const GalleryButtons({super.key});

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: FreevaSpace.s2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Buttons'),
        FreevaButton(label: 'Lưu khoản chi', onPressed: () {}, expand: true),
        gap,
        FreevaButton(
          label: 'Tiếp tục',
          variant: FreevaButtonVariant.ink,
          onPressed: () {},
          expand: true,
        ),
        gap,
        FreevaButton(
          label: 'Huỷ',
          variant: FreevaButtonVariant.secondary,
          onPressed: () {},
          expand: true,
        ),
        gap,
        FreevaButton(
          label: 'Xoá giao dịch',
          variant: FreevaButtonVariant.destructive,
          onPressed: () {},
          expand: true,
        ),
        gap,
        const FreevaButton(label: 'Đang khoá', onPressed: null, expand: true),
        gap,
        FreevaButton(
          label: 'Đang lưu',
          onPressed: () {},
          loading: true,
          expand: true,
        ),
        gap,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FreevaButton(
              label: 'S · 44',
              size: FreevaButtonSize.s,
              onPressed: () {},
            ),
            FreevaButton(
              label: 'XS · 40',
              icon: LucideIcons.plus,
              size: FreevaButtonSize.xs,
              variant: FreevaButtonVariant.ink,
              onPressed: () {},
            ),
            FreevaButton(
              label: 'Xem tất cả',
              variant: FreevaButtonVariant.text,
              onPressed: () {},
            ),
            FreevaIconButton(
              icon: LucideIcons.search,
              label: 'Tìm kiếm',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class GalleryInputs extends StatelessWidget {
  const GalleryInputs({super.key});

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: FreevaSpace.s3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Inputs'),
        const FreevaTextField(label: 'Tên ví', hint: 'Ví dụ: Vietcombank'),
        gap,
        const FreevaTextField(
          label: 'Số dư ban đầu',
          error: 'Nhập số nguyên, không dùng dấu phẩy.',
        ),
        gap,
        const FreevaTextField(label: 'Tiền tệ', hint: 'VND', locked: true),
        gap,
        const FreevaPillField(label: 'Email', icon: LucideIcons.mail),
        gap,
        const FreevaPillField(
          label: 'Mật khẩu',
          icon: LucideIcons.lock,
          obscure: true,
        ),
        gap,
        Center(
          child: MoneyDisplay(minor: BigInt.from(65000), currency: 'VND'),
        ),
        gap,
        AmountKeypad(onDigits: (_) {}, onDelete: () {}),
      ],
    );
  }
}

class GallerySelection extends StatefulWidget {
  const GallerySelection({super.key});

  @override
  State<GallerySelection> createState() => _GallerySelectionState();
}

class _GallerySelectionState extends State<GallerySelection> {
  var _type = 0;
  var _chip = 0;
  var _card = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Selection'),
        FreevaSegmented<int>(
          segments: const [
            FreevaSegment(0, 'Chi'),
            FreevaSegment(1, 'Thu'),
            FreevaSegment(2, 'Chuyển'),
          ],
          selected: _type,
          onChanged: (v) => setState(() => _type = v),
        ),
        const SizedBox(height: FreevaSpace.s3),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, label) in ['Ăn uống', 'Đi lại', 'Hoá đơn'].indexed)
              FreevaChip(
                label: label,
                selected: _chip == i,
                onTap: () => setState(() => _chip = i),
              ),
            FreevaChip(
              label: 'Tất cả',
              selected: true,
              kind: FreevaChipKind.filter,
              onTap: () {},
            ),
            FreevaChip(
              label: 'Tháng 10',
              selected: false,
              kind: FreevaChipKind.filter,
              trailingIcon: LucideIcons.chevronDown,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: FreevaSpace.s3),
        SelectableCard(
          label: 'Theo dõi chi tiêu',
          icon: LucideIcons.receipt,
          selected: _card,
          onTap: () => setState(() => _card = !_card),
        ),
        const SizedBox(height: FreevaSpace.s2),
        SelectableCard(
          label: 'Quản lý khoản nợ',
          icon: LucideIcons.creditCard,
          selected: false,
          enabled: false,
          onTap: () {},
        ),
      ],
    );
  }
}
