/// Whether a host is a private LAN / homelab target (safe to offer SSL trust).
abstract final class HomelabHostPolicy {
  HomelabHostPolicy._();

  static bool isPrivateLan(String host) {
    final h = host.trim().toLowerCase();
    if (h.isEmpty) return false;
    if (h == 'localhost' || h.endsWith('.local')) return true;
    // Tailscale MagicDNS (Serve / Funnel HTTPS hostname).
    if (h.endsWith('.ts.net')) return true;

    final parts = h.split('.');
    if (parts.length != 4) return false;
    final octets = <int>[];
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
      octets.add(n);
    }
    final a = octets[0];
    final b = octets[1];
    if (a == 10) return true;
    if (a == 192 && b == 168) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    // Tailscale / CGNAT (e.g. 100.97.x.x) — homelab over VPN.
    if (a == 100 && b >= 64 && b <= 127) return true;
    return false;
  }

  /// Tailscale wire IP (100.64–127.x) — HTTPS is rarely terminated on app ports.
  static bool isTailscaleWireIp(String host) {
    final h = host.trim().toLowerCase();
    final parts = h.split('.');
    if (parts.length != 4) return false;
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    return a == 100 && b != null && b >= 64 && b <= 127;
  }
}
