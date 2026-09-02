import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'card_action_sheet.dart';
import 'card_transfer_sheet.dart';
import 'card_wallet_provider.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardActionSheet(cardWalletId: widget.cardWalletId, isSpend: isSpend),
    );
  }

  void _openTransfer(CardWalletProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardTransferSheet(
        cardWallets: provider.cardWallets,
        initialCardWalletId: widget.cardWalletId,
      ),
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
                    Align(
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
                              color: style.gradient.first.withOpacity(0.35),
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
                                  color: style.textColor.withOpacity(0.08),
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
                                      AtmContactlessIcon(color: style.textColor.withOpacity(0.85)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const AtmChip(),
                                  const Spacer(),
                                  MaskedCardNumber(
                                    lastFour: maskedCardDigits(wallet.id),
                                    color: style.textColor.withOpacity(0.92),
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
                          ],
                        ),
                      ),
                    ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openAction(false),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openAction(true),
                              icon: const Icon(Icons.remove_rounded),
                              label: const Text('Spend'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openTransfer(provider),
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: const Text('Transfer'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Recent Transactions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      if (transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No transactions yet.', style: TextStyle(color: WalletPalette.textMuted))),
                        )
                      else
                        ...transactions.map((t) {
                          final isCredit = t.type == WalletTransactionType.cardAllowance ||
                              (t.type == WalletTransactionType.transfer && t.toCardWalletId == wallet.id);
                          final tint = isCredit ? WalletPalette.primaryStart : WalletPalette.danger;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: WalletPalette.glassBorder),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: tint.withOpacity(0.14),
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