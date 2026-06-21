import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/data/auth_repository.dart';
import '../delivery_models.dart';
import '../delivery_repository.dart';

class MyDeliveryTripsScreen extends StatefulWidget {
  const MyDeliveryTripsScreen({super.key});

  @override
  State<MyDeliveryTripsScreen> createState() => _MyDeliveryTripsScreenState();
}

class _MyDeliveryTripsScreenState extends State<MyDeliveryTripsScreen> {
  final _deliveryRepository = DeliveryRepository();
  final _authRepository = AuthRepository();

  late Future<List<DeliveryTrip>> _tripsFuture;
  String? _busyActionId;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _deliveryRepository.listMyTrips();
  }

  void _reload() {
    setState(() {
      _tripsFuture = _deliveryRepository.listMyTrips();
    });
  }

  Future<void> _logout() async {
    await _authRepository.logout();

    if (!mounted) return;

    context.go('/login');
  }

  Future<void> _startTrip(DeliveryTrip trip) async {
    await _runAction(
      actionId: 'start-${trip.id}',
      successMessage: 'Reys boshlandi',
      action: () => _deliveryRepository.startTrip(trip.id),
    );
  }

  Future<void> _deliverStop(DeliveryStop stop) async {
    await _runAction(
      actionId: 'deliver-${stop.id}',
      successMessage: 'Zakaz yetkazildi',
      action: () => _deliveryRepository.deliverStop(stop.id),
    );
  }

  Future<void> _runAction({
    required String actionId,
    required String successMessage,
    required Future<DeliveryTrip> Function() action,
  }) async {
    if (_busyActionId != null) return;

    setState(() {
      _busyActionId = actionId;
    });

    try {
      await action();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      _reload();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyActionId = null;
        });
      }
    }
  }

  String _tripStatusLabel(String status) {
    return switch (status) {
      'PLANNED' => 'Rejada',
      'IN_PROGRESS' => 'Yo‘lda',
      'COMPLETED' => 'Yakunlandi',
      _ => status,
    };
  }

  String _stopStatusLabel(String status) {
    return switch (status) {
      'PENDING' => 'Kutilmoqda',
      'DELIVERED' => 'Yetkazildi',
      'FAILED' => 'Muammo',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'PLANNED' => const Color(0xFFD97706),
      'IN_PROGRESS' => const Color(0xFF2563EB),
      'COMPLETED' => const Color(0xFF059669),
      'DELIVERED' => const Color(0xFF059669),
      'FAILED' => const Color(0xFFDC2626),
      _ => const Color(0xFF64748B),
    };
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'Sana yo‘q';

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    return '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mening reyslarim'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<DeliveryTrip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final trips = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const _DeliveryIntroCard(),
                const SizedBox(height: 12),
                if (trips.isEmpty)
                  const _EmptyTripsCard()
                else
                  ...trips.map((trip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TripCard(
                        trip: trip,
                        busyActionId: _busyActionId,
                        tripStatusLabel: _tripStatusLabel,
                        stopStatusLabel: _stopStatusLabel,
                        statusColor: _statusColor,
                        formatDate: _formatDate,
                        onStartTrip: () => _startTrip(trip),
                        onDeliverStop: _deliverStop,
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeliveryIntroCard extends StatelessWidget {
  const _DeliveryIntroCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sizga biriktirilgan reyslar. Reysni boshlang va har bir manzil yetkazilgach tasdiqlang.',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTripsCard extends StatelessWidget {
  const _EmptyTripsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Hozircha sizga biriktirilgan reys yo‘q',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.busyActionId,
    required this.tripStatusLabel,
    required this.stopStatusLabel,
    required this.statusColor,
    required this.formatDate,
    required this.onStartTrip,
    required this.onDeliverStop,
  });

  final DeliveryTrip trip;
  final String? busyActionId;
  final String Function(String status) tripStatusLabel;
  final String Function(String status) stopStatusLabel;
  final Color Function(String status) statusColor;
  final String Function(String? value) formatDate;
  final VoidCallback onStartTrip;
  final void Function(DeliveryStop stop) onDeliverStop;

  @override
  Widget build(BuildContext context) {
    final isStarting = busyActionId == 'start-${trip.id}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reys #${trip.id.substring(0, 8)}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusPill(
                  label: tripStatusLabel(trip.status),
                  color: statusColor(trip.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Yaratilgan: ${formatDate(trip.createdAt)} • ${trip.deliveredStopsCount}/${trip.stops.length} manzil',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trip.status == 'PLANNED') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busyActionId == null ? onStartTrip : null,
                  icon: isStarting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    isStarting ? 'Boshlanmoqda...' : 'Reysni boshlash',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...trip.stops.map((stop) {
              final canDeliver =
                  trip.status == 'IN_PROGRESS' && stop.status == 'PENDING';
              final isDelivering = busyActionId == 'deliver-${stop.id}';

              return _StopTile(
                stop: stop,
                canDeliver: canDeliver,
                isDelivering: isDelivering,
                stopStatusLabel: stopStatusLabel,
                statusColor: statusColor,
                onDeliver: () => onDeliverStop(stop),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.canDeliver,
    required this.isDelivering,
    required this.stopStatusLabel,
    required this.statusColor,
    required this.onDeliver,
  });

  final DeliveryStop stop;
  final bool canDeliver;
  final bool isDelivering;
  final String Function(String status) stopStatusLabel;
  final Color Function(String status) statusColor;
  final VoidCallback onDeliver;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE2E8F0),
                child: Text(
                  stop.sortOrder.toString(),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stop.order.customer.name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(
                label: stopStatusLabel(stop.status),
                color: statusColor(stop.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stop.order.customer.phone ?? 'Telefon yo‘q',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stop.order.customer.address ?? 'Manzil yo‘q',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (stop.order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: stop.order.items.map((item) {
                return Chip(
                  label: Text('${item.productName} × ${item.quantity}'),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
          ],
          if (canDeliver) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isDelivering ? null : onDeliver,
                icon: isDelivering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(isDelivering ? 'Tasdiqlanmoqda...' : 'Yetkazildi'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
