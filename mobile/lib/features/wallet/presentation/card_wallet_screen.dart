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

    return Scaffold(
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
                  ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                    Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: style!.gradient,
                            ),
                          ),
                                            padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(wallet.provider.toUpperCase(),
                                      style: TextStyle(color: style.subTextColor, fontSize: 12, fontWeight: FontWeight.w700)),
                                  // little chip accent, mirrors the balance bento card
                                  Container(
                                    width: 30, height: 21,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: style.accent.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_currency.format(wallet.currentBalance),
                                  style: TextStyle(color: style.textColor, fontSize: 30, fontWeight: FontWeight.w800)),
                            ],
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
                        ...transactions.map((t) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(t.type.label),
                                subtitle: Text(t.description ?? DateFormat.yMMMd().add_jm().format(t.createdAt)),
                                trailing: Text(_currency.format(t.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            )),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}