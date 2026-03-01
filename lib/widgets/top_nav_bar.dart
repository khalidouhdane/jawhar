import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'animated_svg_icon.dart';

class TopNavBar extends StatelessWidget {
  final String readMode;
  final ValueChanged<String> onReadModeChanged;

  const TopNavBar({
    super.key,
    required this.readMode,
    required this.onReadModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top > 0 
              ? MediaQuery.paddingOf(context).top + 16 
              : 16,
          bottom: 16,
          left: 16,
          right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF3F5),
                  shape: BoxShape.circle,
                ),
                child: GestureDetector(
                  onTap: () {},
                  child: const Icon(LucideIcons.chevronLeft, size: 18, color: Color(0xFF172A30)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    _buildModeToggle(
                      svgPath: 'M11.4375 0H2.8125C0.999 0 0 0.999 0 2.8125V11.8125C0 13.4948 1.13025 14.625 2.8125 14.625H11.4375C12.3675 14.625 13.125 13.8683 13.125 12.9375V8.4375V6.5625V1.6875C13.125 0.75675 12.3675 0 11.4375 0ZM2.8125 1.125H11.4375C11.7472 1.125 12 1.377 12 1.6875V6.5625V8.4375C12 8.748 11.7472 9 11.4375 9H2.8125C2.15175 9 1.58025 9.17922 1.125 9.49347V2.8125C1.125 1.62975 1.62975 1.125 2.8125 1.125ZM11.4375 13.5H2.8125C1.75575 13.5 1.125 12.8693 1.125 11.8125C1.125 10.7557 1.75575 10.125 2.8125 10.125H11.4375C11.6355 10.125 11.823 10.0845 12 10.0215V12.9375C12 13.248 11.7472 13.5 11.4375 13.5ZM3.75 3.5625C3.75 3.252 4.002 3 4.3125 3H8.8125C9.123 3 9.375 3.252 9.375 3.5625C9.375 3.873 9.123 4.125 8.8125 4.125H4.3125C4.002 4.125 3.75 3.873 3.75 3.5625ZM3.75 5.8125C3.75 5.502 4.002 5.25 4.3125 5.25H7.3125C7.623 5.25 7.875 5.502 7.875 5.8125C7.875 6.123 7.623 6.375 7.3125 6.375H4.3125C4.002 6.375 3.75 6.123 3.75 5.8125Z',
                      viewBounds: const Rect.fromLTWH(0, 0, 13.125, 14.625),
                      label: 'Read',
                      mode: 'read',
                    ),
                    _buildModeToggle(
                      svgPath: 'M14.0894 0.697801C14.0887 0.697801 14.0887 0.697819 14.088 0.697069C12.8122 0.0918185 11.397 -0.120445 9.88129 0.0648053C8.79079 0.199055 7.86825 0.822268 7.3125 1.69527C6.756 0.823018 5.83423 0.199055 4.74298 0.0648053C3.22573 -0.120445 1.8128 0.0918185 0.537048 0.697069C0.537048 0.697069 0.537066 0.697069 0.536316 0.697069C0.210816 0.851569 0 1.18676 0 1.55126V11.305C0 11.6005 0.134922 11.8713 0.370422 12.0491C0.605172 12.2268 0.915823 12.2845 1.20007 12.2028C3.38182 11.5833 5.22376 11.8458 6.99976 13.0286C7.00726 13.0338 7.01624 13.0353 7.02374 13.0398C7.03199 13.0443 7.038 13.0518 7.047 13.0563C7.05525 13.0608 7.06493 13.0585 7.07318 13.063C7.14893 13.099 7.22927 13.1231 7.31177 13.1231C7.39427 13.1231 7.47442 13.099 7.55017 13.063C7.55842 13.0593 7.56829 13.0608 7.57654 13.0563C7.58479 13.0518 7.59156 13.045 7.59906 13.0398C7.60656 13.0353 7.61555 13.0338 7.62305 13.0286C9.3968 11.8458 11.2395 11.5833 13.4227 12.2028C13.7062 12.283 14.0174 12.2268 14.2522 12.0491C14.4877 11.8713 14.6228 11.5998 14.6228 11.305V1.55126C14.6251 1.18826 14.4149 0.853051 14.0894 0.697801ZM3.36292 10.7568C2.64217 10.7568 1.8975 10.8573 1.125 11.0583V1.66451C2.18925 1.18301 3.32858 1.02407 4.60583 1.18157C5.82833 1.33157 6.75 2.37402 6.75 3.60552V11.5788C5.67375 11.0298 4.55092 10.7568 3.36292 10.7568ZM13.5 11.0583C11.4555 10.5265 9.60525 10.696 7.875 11.5788V3.60552C7.875 2.37327 8.79668 1.33157 10.0184 1.18157C10.3349 1.14257 10.6433 1.12306 10.944 1.12306C11.8553 1.12306 12.699 1.30226 13.4993 1.66451V11.0583H13.5Z',
                      viewBounds: const Rect.fromLTWH(0, 0, 14.6228, 13.1231),
                      label: 'Tafsir',
                      mode: 'tafsir',
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: const Icon(LucideIcons.slidersHorizontal, size: 24, color: Color(0xFF172A30)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {},
                child: const Icon(LucideIcons.search, size: 24, color: Color(0xFF172A30)),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.only(left: 10, right: 6, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Text(
                      'FR', 
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF172A30), height: 1.085)
                    ),
                    SizedBox(width: 3),
                    Icon(LucideIcons.arrowRightLeft, size: 20, color: Color(0xFF172A30)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildModeToggle({
    required String svgPath, 
    required Rect viewBounds, 
    required String label, 
    required String mode
  }) {
    final bool isSelected = readMode == mode;
    return GestureDetector(
      onTap: () => onReadModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 36,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1C4F5F), Color(0xFF102E37)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSvgIcon(
              svgPath: svgPath,
              viewBounds: viewBounds,
              width: 18,
              height: 18,
              isSelected: isSelected,
              color: isSelected ? Colors.white : const Color(0xFF172A30),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected 
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF172A30),
                          height: 1.085,
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
