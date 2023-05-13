class UPI {
  final String baseUrl;
  final String pa;
  final String? pn;
  final String? cu;
  final String? tn;
  final String? tr;
  final String? mc;
  final String? url;
  final String mode;
  String? am;
  Map<String, String>? mp;

  UPI(
      {required this.baseUrl,
      required this.pa,
      this.am,
      this.pn,
      this.cu,
      this.tn,
      this.tr,
      this.mc,
      this.mode = "02",
      this.url,
      this.mp});

  factory UPI.fromString(String s) {
    final parsed = Uri.parse(s).toString();
    final s1 = parsed.split('?');
    final base = s1[0];
    final _mp = <String, String>{};
    List<String> pts =
        List.of(["pa", "pn", "cu", "tn", "tr", "mc", "mode", "url", "am"]);
    for (String p in pts) {
      if (s1[1].contains(p)) {
        final idx = s1[1].indexOf(p);
        final rem = s1[1].substring(idx + p.length + 1);
        final idx2 = rem.indexOf('&');
        final sub2 = idx2 != -1
            ? rem.substring(0, idx2).replaceAll(RegExp('%20'), ' ')
            : rem.replaceAll('%20', ' ');
        _mp[p] = sub2;
      }
    }
    if (!_mp.containsKey('mode')) {
      _mp['mode'] = "02";
    }

    return UPI(
        baseUrl: base,
        pa: _mp['pa']!,
        am: _mp['am'],
        pn: _mp['pn'],
        cu: _mp['cn'],
        tn: _mp['tn'],
        tr: _mp['tr'],
        mc: _mp['mc'],
        mode: _mp['mode'] ?? "02",
        url: _mp['url'],
        mp: _mp);
  }

  void setAmount(String amt) {
    am = amt;
    mp!['am'] = amt;
  }

  String getEncodedUrl() {
    var ret = "$baseUrl?";
    for (final e in mp!.entries) {
      ret = "$ret${e.key}=${e.value}&";
    }
    ret = ret.substring(0, ret.length - 1);
    return Uri.encodeFull(ret);
  }
}
