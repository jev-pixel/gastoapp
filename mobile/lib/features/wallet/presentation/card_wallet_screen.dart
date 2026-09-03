import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/bank_deeplink_service.dart';
import '../domain/card_wallet_model.dart';
import '../domain/qr_model.dart';
import '../domain/wallet_model.dart';
import 'card_action_sheet.dart';
import 'card_transfer_sheet.dart';
import 'card_wallet_provider.dart';
import 'qr_confirm_settlement_sheet.dart';
import 'qr_generator_sheet.dart';
import 'qr_scanner_sheet.dart';
import 'wallet_theme.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class CardWalletScreen extends StatefulWidget {
  final String cardWalletId;
  const CardWalletScreen({super.key, required this.cardWalletId});

  @override
  State<CardWalletScreen> createState() => _CardWalletScreenState();
}

class _CardWalletScreenState extends State<CardWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CardWalletProvider>();
      // Ensures this screen can recover on its own (deep link, hot
      // restart, provider reset, etc.) instead of relying on WalletScreen
      // having already populated the list.
      if (provider.byId(widget.cardWalletId) == null) {
        provider.loadCardWallets();
      }
      provider.loadTransactions(widget.cardWalletId);
    });
  }

  void _openAction(bool isSpend) {
    showWalletSheet(
      context: context,
      builder: (_) => CardActionSheet(cardWalletId: widget.cardWalletId, isSpend: isSpend),
    );
  }

  // No BuildContext parameter here on purpose — taking one in as an
  // argument shadows the State's own `context`, so the analyzer can no
  // longer prove a later `mounted` check actually guards *that* context.
  // Using the State's own `context` throughout keeps the guard verifiable.
  Future<void> _openScanner() async {
    final reservation = await Navigator.of(context).push<QrReservation>(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: WalletMotion.standard,
        reverseTransitionDuration: WalletMotion.standard,
        pageBuilder: (_, _, _) => QrScannerSheet(cardWalletId: widget.cardWalletId),
        // A soft fade+scale for the camera page instead of a hard material
        // slide — reads closer to how iOS presents a full-screen scanner.
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(parent: animation, curve: WalletMotion.settle);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(curved), child: child),
          );
        },
      ),
    );
    if (reservation == null || !mounted) return;

    await BankDeepLinkService.stageAndLaunch(
      provider: reservation.provider,
      clipboardText:
          '${reservation.destinationAccount ?? ''} ${reservation.amount.toStringAsFixed(2)}',
    );
    if (!mounted) return;

    // Give the user a way to confirm once they've completed the payment
    // in their banking app.
    showWalletSheet(
      context: context,
      isDismissible: false, // force an explicit confirm/cancel choice
      builder: (_) => QrConfirmSettlementSheet(reservation: reservation),
    );
  }

  void _openTransfer(CardWalletProvider provider) {
    showWalletSheet(
      context: context,
      builder: (_) => CardTransferSheet(
        cardWallets: provider.cardWallets,
        initialCardWalletId: widget.cardWalletId,
      ),
    );
  }

  void _openReceive(CardWallet wallet) {
    showWalletSheet(
      context: context,
      builder: (_) => QrGeneratorSheet(wallet: wallet),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardWalletProvider>();
    final wallet = provider.byId(widget.cardWalletId);
    final transactions = provider.transactionsByWallet[widget.cardWalletId] ?? const [];
    final style = wallet != null ? CardProviderPalette.of(wallet.provider) : null;

    return WalletFontScope(
      child: Scaffold(
        backgroundColor: WalletPalette.canvasBottom,
        appBar: AppBar(
          title: Text(wallet?.name ?? 'Card Wallet'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Wallet Dashboard',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            final cardProvider = context.read<CardWalletProvider>();
            await cardProvider.loadCardWallets();
            await cardProvider.loadTransactions(widget.cardWalletId);
          },
          child: wallet == null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : Stack(
                  children: [
                    const Positioned.fill(child: WalletAmbientBackground()),
                    WalletResponsivePage(
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          FadeSlideIn(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: WalletBreakpoints.isTablet(context) ? 420 : double.infinity,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1.586, // standard ID-1 bank card ratio
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: style!.gradient,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: style.gradient.first.withValues(alpha: 0.35),
                                          blurRadius: 26,
                                          offset: const Offset(0, 14),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Faint corner watermark of the provider's initial,
                                        // the way physical bank cards print a ghost logo.
                                        Positioned(
                                          right: -10,
                                          bottom: -26,
                                          child: Text(
                                            wallet.provider.substring(0, 1).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 140,
                                              fontWeight: FontWeight.w900,
                                              color: style.textColor.withValues(alpha: 0.08),
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    wallet.provider.toUpperCase(),
                                                    style: TextStyle(
                                                      color: style.subTextColor,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                  AtmContactlessIcon(color: style.textColor.withValues(alpha: 0.85)),
                                                ],
                                              ),
                                              const SizedBox(height: 14),
                                              const AtmChip(),
                                              const Spacer(),
                                              MaskedCardNumber(
                                                lastFour: maskedCardDigits(wallet.id),
                                                color: style.textColor.withValues(alpha: 0.92),
                                                fontSize: 17,
                                              ),
                                              const SizedBox(height: 14),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'CARD LABEL',
                                                          style: TextStyle(
                                                            color: style.subTextColor,
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 0.8,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          wallet.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: style.textColor,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'BALANCE',
                                                        style: TextStyle(
                                                          color: style.subTextColor,
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.w700,
                                                          letterSpacing: 0.8,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _currency.format(wallet.currentBalance),
                                                        style: TextStyle(
                                                          color: style.textColor,
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.w800,
                                                          fontFeatures: const [FontFeature.tabularFigures()],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        GlassSheen(radius: BorderRadius.circular(22)),
                                        // One-shot light sweep played once when the card
                                        // first appears — the Apple Wallet "wake up" beat.
                                        OneShotSheen(radius: BorderRadius.circular(22)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 70),
                            child: Row(
                              children: [
                                Expanded(
                                  child: WalletToolbarAction(
                                    icon: Icons.add_rounded,
                                    label: 'Add',
                                    tint: WalletPalette.primaryEnd,
                                    onTap: () => _openAction(false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: WalletToolbarAction(
                                    icon: Icons.remove_rounded,
                                    label: 'Spend',
                                    tint: WalletPalette.danger,
                                    onTap: () => _openAction(true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: WalletToolbarAction(
                                    icon: Icons.swap_horiz_rounded,
                                    label: 'Transfer',
                                    tint: WalletPalette.accentBlueStart,
                                    onTap: () => _openTransfer(provider),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: WalletToolbarAction(
                                    icon: Icons.qr_code_scanner_rounded,
                                    label: 'Scan',
                                    tint: WalletPalette.tealStart,
                                    onTap: _openScanner,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: WalletToolbarAction(
                                    icon: Icons.qr_code_2_rounded,
                                    label: 'Receive',
                                    tint: WalletPalette.amberStart,
                                    onTap: () => _openReceive(wallet),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 110),
                            child: const Text('Recent Transactions',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(height: 10),
                          if (transactions.isEmpty)
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 140),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text('No transactions yet.', style: TextStyle(color: WalletPalette.textMuted)),
                                ),
                              ),
                            )
                          else
                            ...transactions.asMap().entries.map((entry) {
                              final index = entry.key;
                              final t = entry.value;
                              final isCredit = t.type == WalletTransactionType.cardAllowance ||
                                  (t.type == WalletTransactionType.transfer && t.toCardWalletId == wallet.id);
                              final tint = isCredit ? WalletPalette.primaryStart : WalletPalette.danger;
                              return FadeSlideIn(
                                // Cap the stagger so a long history doesn't leave the
                                // last rows waiting several seconds to appear.
                                delay: Duration(milliseconds: 140 + (index.clamp(0, 8) * 28)),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: WalletPalette.glassBorder),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: tint.withValues(alpha: 0.14),
                                      child: Icon(
                                        isCredit ? Icons.add_rounded : Icons.remove_rounded,
                                        color: tint,
                                      ),
                                    ),
                                    title: Text(t.type.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text(t.description ?? DateFormat.yMMMd().add_jm().format(t.createdAt)),
                                    trailing: Text(
                                      _currency.format(t.amount),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: tint),
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}