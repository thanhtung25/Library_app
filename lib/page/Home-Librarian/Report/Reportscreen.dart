import 'dart:io';
import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';
import 'package:library_app/model/user_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ─── Report type model ────────────────────────────────────────────────────────
enum _SF { none, opType, overdueStatus, serviceType }

class _RT {
  final String key, label;
  final _SF sf;
  const _RT(this.key, this.label, this.sf);
  @override bool operator ==(o) => o is _RT && o.key == key;
  @override int get hashCode => key.hashCode;
}

const _rTypes = [
  _RT('loans',       'Отчёт по операциям выдачи и возврата', _SF.opType),
  _RT('overdue',     'Отчёт о просроченных возвратах',       _SF.overdueStatus),
  _RT('users',       'Отчёт по активности пользователей',    _SF.none),
  _RT('payments',    'Отчёт по платным услугам',             _SF.serviceType),
  _RT('payment_doc', 'Платёжные документы библиотеки',       _SF.none),
];

const _opTypes    = ['Все операции', 'Выдачи', 'Возвраты'];
const _ovStatuses = ['Все', '1–7 дней', '7–30 дней', 'Более 30 дней'];
const _svcTypes   = ['Все услуги', 'Штрафы', 'Прочее'];

List<String> _sfOpts(_SF sf) => switch (sf) {
  _SF.opType        => _opTypes,
  _SF.overdueStatus => _ovStatuses,
  _SF.serviceType   => _svcTypes,
  _SF.none          => [],
};

// ─── Screen ───────────────────────────────────────────────────────────────────
class ReportScreen extends StatefulWidget {
  final UserModel user;
  const ReportScreen({super.key, required this.user});
  @override State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const _orange    = Color(0xffFF9E74);
  static const _bg        = Color(0xffFBEEE4);
  static const _hdrClr    = Color(0xffF5C5A8);

  _RT       _sel  = _rTypes.first;
  DateTime? _from, _to;
  String    _sf   = _opTypes.first;

  bool _genL = false, _expL = false, _dlL = false;
  List<String>        _cols    = [];
  List<List<String>>  _rows    = [];
  Map<String, String> _docMeta = {};

  // ── Date helpers ────────────────────────────────────────────────────────────
  Future<void> _pickDate(bool isFrom) async {
    final init = isFrom
        ? (_from ?? DateTime.now().subtract(const Duration(days: 30)))
        : (_to   ?? DateTime.now());
    final p = await showDatePicker(
      context: context, initialDate: init,
      firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _orange)),
        child: child!,
      ),
    );
    if (p != null) setState(() => isFrom ? _from = p : _to = p);
  }

  String _fmtD(DateTime? d) => d == null
      ? 'дд.мм.гггг'
      : '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';

  bool _inRange(String? s) {
    if (_from == null && _to == null) return true;
    if (s == null || s.isEmpty) return true;
    try {
      final d = DateTime.parse(s);
      if (_from != null && d.isBefore(_from!)) return false;
      if (_to   != null && d.isAfter(_to!.add(const Duration(days: 1)))) return false;
    } catch (_) {}
    return true;
  }

  List<Map<String,dynamic>> _ml(dynamic raw) =>
      (raw is List ? raw : <dynamic>[]).whereType<Map<String,dynamic>>().toList();

  String _tr(String? s) => const {
    'borrowed': 'Выдано', 'returned': 'Возвращено', 'overdue': 'Просрочено',
    'paid': 'Оплачено', 'unpaid': 'Не оплачено', 'pending': 'Ожидание',
  }[s] ?? (s ?? '');

  // ── Generate ─────────────────────────────────────────────────────────────────
  Future<void> _generate() async {
    setState(() { _genL = true; _cols = []; _rows = []; _docMeta = {}; });
    try {
      switch (_sel.key) {
        case 'loans':       await _doLoans();    break;
        case 'overdue':     await _doOverdue();  break;
        case 'users':       await _doUsers();    break;
        case 'payments':    await _doPay();      break;
        case 'payment_doc': await _doPayDoc();   break;
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _genL = false);
    }
  }

  Future<void> _doLoans() async {
    final raw = await ApiService.get('/loans-management/loan');
    var list  = _ml(raw).where((e) => _inRange(e['loan_date']?.toString())).toList();
    if (_sf == 'Выдачи')   list = list.where((e) => ['borrowed','overdue'].contains(e['status'])).toList();
    if (_sf == 'Возвраты') list = list.where((e) => e['status'] == 'returned').toList();
    if (!mounted) return;
    setState(() {
      _cols = ['№','ID займа','ID польз.','ID копии','Дата выдачи','Дата возврата','Статус'];
      _rows = list.asMap().entries.map((en) {
        final e = en.value;
        return ['${en.key+1}','${e['id_loan']??''}','${e['id_user']??''}','${e['id_copy']??''}',
          '${e['loan_date']??''}','${e['return_date']??''}', _tr(e['status']?.toString())];
      }).toList();
    });
  }

  Future<void> _doOverdue() async {
    final raw  = await ApiService.get('/loans-management/loan');
    var list   = _ml(raw).where((e) => e['status']?.toString() == 'overdue').toList();
    if (_sf != 'Все') {
      final now = DateTime.now();
      list = list.where((e) {
        final s = e['return_date']?.toString() ?? '';
        try {
          final days = now.difference(DateTime.parse(s)).inDays;
          if (_sf == '1–7 дней')      return days >= 1  && days <= 7;
          if (_sf == '7–30 дней')     return days > 7   && days <= 30;
          if (_sf == 'Более 30 дней') return days > 30;
        } catch (_) {}
        return true;
      }).toList();
    }
    if (!mounted) return;
    setState(() {
      _cols = ['№','ID займа','ID польз.','ID копии','Срок возврата','Дней просрочки','Статус'];
      _rows = list.asMap().entries.map((en) {
        final e   = en.value;
        final ret = e['return_date']?.toString() ?? '';
        int days  = 0;
        try { days = DateTime.now().difference(DateTime.parse(ret)).inDays; } catch (_) {}
        return ['${en.key+1}','${e['id_loan']??''}','${e['id_user']??''}','${e['id_copy']??''}',
          ret, '$days', 'Просрочено'];
      }).toList();
    });
  }

  Future<void> _doUsers() async {
    final results  = await Future.wait([
      ApiService.get('/loans-management/loan'),
      ApiService.get('/users-management/users'),
    ]);
    final loans    = _ml(results[0]);
    final readers  = _ml(results[1]).where((u) => u['role'] == 'reader').toList();
    final userMap  = { for (final u in readers) (u['id_user'] as int? ?? 0) : u };

    final cnt = <int, Map<String,int>>{};
    for (final l in loans) {
      if (!_inRange(l['loan_date']?.toString())) continue;
      final uid = l['id_user'] as int? ?? 0;
      cnt.putIfAbsent(uid, () => {'t':0,'i':0,'r':0});
      cnt[uid]!['t'] = cnt[uid]!['t']! + 1;
      if (['borrowed','overdue'].contains(l['status'])) cnt[uid]!['i'] = cnt[uid]!['i']! + 1;
      if (l['status'] == 'returned') cnt[uid]!['r'] = cnt[uid]!['r']! + 1;
    }

    final rows = <List<String>>[];
    var i = 1;
    cnt.forEach((uid, c) {
      final u    = userMap[uid];
      final name = u != null
          ? (u['full_name'] ?? u['username'] ?? 'ID $uid').toString()
          : 'ID $uid';
      rows.add(['${i++}', name, '${c['t']}', '${c['i']}', '${c['r']}']);
    });

    if (!mounted) return;
    setState(() {
      _cols = ['№','Пользователь','Операций','Выдачи','Возвраты'];
      _rows = rows;
    });
  }

  Future<void> _doPay() async {
    final raw  = await ApiService.get('/fines-management/fines');
    var list   = _ml(raw).where((e) => _inRange((e['payment_date'] ?? e['created_at'])?.toString())).toList();
    if (_sf == 'Штрафы') {
      list = list.where((e) {
        final t = (e['fine_type'] ?? e['reason'] ?? '').toString().toLowerCase();
        return t.contains('штраф') || t.contains('fine');
      }).toList();
    }
    if (!mounted) return;
    setState(() {
      _cols = ['№','ID штрафа','ID займа','Сумма','Статус','Дата оплаты'];
      _rows = list.asMap().entries.map((en) {
        final e = en.value;
        return ['${en.key+1}','${e['id_fine']??''}','${e['id_loan']??''}',
          '${e['amount']??'0'}', _tr(e['status']?.toString()), '${e['payment_date']??''}'];
      }).toList();
    });
  }

  Future<void> _doPayDoc() async {
    final raw   = await ApiService.get('/fines-management/fines');
    final list  = _ml(raw).where((e) => e['status'] == 'paid').toList();
    final total = list.fold<double>(0, (s, e) => s + (e['amount'] as num? ?? 0).toDouble());
    if (!mounted) return;
    setState(() {
      _cols = ['№','Услуга','ID польз.','Стоимость','Дата оплаты','Статус'];
      _rows = list.asMap().entries.map((en) {
        final e = en.value;
        return ['${en.key+1}', e['fine_type']?.toString() ?? 'Штраф',
          '${e['id_user'] ?? e['id_loan'] ?? ''}',
          '${e['amount'] ?? '0'}', '${e['payment_date'] ?? ''}', 'Оплачено'];
      }).toList();
      _docMeta = {
        'total': total.toStringAsFixed(2),
        'num':   DateTime.now().millisecondsSinceEpoch.toString().substring(8),
      };
    });
  }

  // ── CSV export ──────────────────────────────────────────────────────────────
  String _csv() {
    final b = StringBuffer()..write('\uFEFF');
    b.writeln(_cols.map(_ce).join(','));
    for (final r in _rows) b.writeln(r.map(_ce).join(','));
    return b.toString();
  }

  String _ce(String v) =>
      (v.contains(',') || v.contains('"') || v.contains('\n'))
          ? '"${v.replaceAll('"', '""')}"'
          : v;

  Future<String> _saveFile() async {
    final dir = await getTemporaryDirectory();
    final f   = File('${dir.path}/${_sel.key}_${DateTime.now().millisecondsSinceEpoch}.csv');
    await f.writeAsString(_csv(), flush: true);
    return f.path;
  }

  Future<void> _share(String? extraText) async {
    final path = await _saveFile();
    if (!mounted) return;
    await Share.shareXFiles(
      [XFile(path, mimeType: 'text/csv')],
      subject: _sel.label,
      text: extraText,
    );
  }

  Future<void> _export() async {
    if (_rows.isEmpty) { _snack('Сначала сформируйте отчёт', isError: true); return; }
    setState(() => _expL = true);
    try { await _share(null); }
    catch (e) { if (mounted) _snack(e.toString(), isError: true); }
    finally { if (mounted) setState(() => _expL = false); }
  }

  Future<void> _download() async {
    if (_rows.isEmpty) { _snack('Сначала сформируйте отчёт', isError: true); return; }
    setState(() => _dlL = true);
    try { await _share('Сохранить CSV файл'); }
    catch (e) { if (mounted) _snack(e.toString(), isError: true); }
    finally { if (mounted) setState(() => _dlL = false); }
  }

  void _snack(String m, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sfOptions = _sfOpts(_sel.sf);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Отчёты и документы',
            style: TextStyle(fontFamily: 'Times New Roman', fontWeight: FontWeight.bold,
                color: _orange, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Dropdown ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_RT>(
                isExpanded: true, value: _sel,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                selectedItemBuilder: (ctx) => _rTypes
                    .map((t) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(t.label,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13,
                          fontFamily: 'Times New Roman')),
                ))
                    .toList(),
                onChanged: (v) {
                  final opts = _sfOpts(v!.sf);
                  setState(() {
                    _sel = v; _cols = []; _rows = []; _docMeta = {};
                    _sf  = opts.isNotEmpty ? opts.first : '';
                  });
                },
                items: _rTypes
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.label, style: const TextStyle(fontSize: 13)),
                ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Date range ────────────────────────────────────────────────────
          Row(children: [
            const Text('С даты:',  style: TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Expanded(child: _dateChip(true)),
            const SizedBox(width: 12),
            const Text('До даты:', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Expanded(child: _dateChip(false)),
          ]),

          const SizedBox(height: 10),

          // ── Sub-filter ────────────────────────────────────────────────────
          if (sfOptions.isNotEmpty) ...[
            _subFilter(sfOptions),
            const SizedBox(height: 10),
          ],

          // ── Buttons ───────────────────────────────────────────────────────
          Row(children: [
            Expanded(child: _btn('Сформировать', _genL ? null : _generate, _orange, loading: _genL)),
            const SizedBox(width: 8),
            Expanded(child: _btn('Экспорт', (_rows.isEmpty || _expL) ? null : _export,
                Colors.green.shade600, loading: _expL)),
            const SizedBox(width: 8),
            Expanded(child: _btn('Скачать', (_rows.isEmpty || _dlL) ? null : _download,
                Colors.blue.shade600, loading: _dlL)),
          ]),

          const SizedBox(height: 20),

          if (_rows.isNotEmpty)
            _sel.key == 'payment_doc' ? _payDocView() : _tableView(),
        ]),
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────
  Widget _dateChip(bool isFrom) {
    final d = isFrom ? _from : _to;
    return GestureDetector(
      onTap: () => _pickDate(isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today, color: _orange, size: 14),
          const SizedBox(width: 4),
          Expanded(child: Text(_fmtD(d), style: const TextStyle(fontSize: 12))),
        ]),
      ),
    );
  }

  Widget _subFilter(List<String> opts) {
    final label = switch (_sel.sf) {
      _SF.opType        => 'Тип операции:',
      _SF.overdueStatus => 'Статус просрочки:',
      _SF.serviceType   => 'Вид услуги:',
      _SF.none          => '',
    };
    return Row(children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true, value: _sf,
              icon: const Icon(Icons.arrow_drop_down, color: _orange, size: 18),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              onChanged: (v) => setState(() => _sf = v!),
              items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _btn(String label, VoidCallback? onTap, Color color, {bool loading = false}) {
    final dis = onTap == null;
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: dis ? Colors.grey.shade300 : color,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: dis ? 0 : 1,
        ),
        onPressed: onTap,
        child: loading
            ? const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: dis ? Colors.grey : Colors.white,
                  fontFamily: 'Times New Roman')),
        ),
      ),
    );
  }

  Widget _tableView() {
    final preview = _rows.length > 50 ? _rows.sublist(0, 50) : _rows;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(_sel.label,
              style: const TextStyle(fontFamily: 'Times New Roman',
                  fontWeight: FontWeight.bold, fontSize: 14, color: _orange)),
        ),
        Text('${_rows.length} зап.', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
      if (_rows.length > 50)
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Text('Показаны первые 50 записей. Используйте «Экспорт» для всех данных.',
              style: TextStyle(fontSize: 10, color: Colors.grey)),
        ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(_hdrClr),
            columnSpacing: 12,
            dataRowMinHeight: 36, dataRowMaxHeight: 48,
            columns: _cols
                .map((c) => DataColumn(
              label: Text(c,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.white)),
            ))
                .toList(),
            rows: preview
                .map((row) => DataRow(
              cells: row
                  .map((cell) =>
                  DataCell(Text(cell, style: const TextStyle(fontSize: 11))))
                  .toList(),
            ))
                .toList(),
          ),
        ),
      ),
    ]);
  }

  Widget _payDocView() {
    final num = _docMeta['num'] ?? '';
    final tot = _docMeta['total'] ?? '0.00';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Text(
            'Платёжный документ на оплату\nдополнительных услуг библиотеки №$num',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Юношеская библиотека    Дата составления: ${_fmtD(DateTime.now())}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Настоящий платёжный документ подтверждает начисление к/или оплату '
              'дополнительных услуг библиотеки. Содержит сведения о виде услуги, '
              'стоимости, дате оплаты и статусе платежа.',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(_hdrClr),
            columnSpacing: 10,
            dataRowMinHeight: 30, dataRowMaxHeight: 38,
            columns: _cols
                .map((c) => DataColumn(
              label: Text(c,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white)),
            ))
                .toList(),
            rows: _rows
                .map((row) => DataRow(
              cells: row
                  .map((cell) =>
                  DataCell(Text(cell, style: const TextStyle(fontSize: 10))))
                  .toList(),
            ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _infoLine('Итого к оплате:',    '$tot руб.'),
        _infoLine('Оплаченная сумма:',  '$tot руб.'),
        _infoLine('Статус документа:',  'Оплачено'),
        _infoLine('Назначение платежа:', 'Дополнительные услуги библиотеки'),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sign('Исполнитель документа'),
            _sign('Кассир / библиотекарь'),
            _sign('Плательщик'),
          ],
        ),
      ]),
    );
  }

  Widget _infoLine(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(width: 8),
      Text(v, style: const TextStyle(fontSize: 12, color: _orange, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _sign(String title) => Column(children: [
    Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
    const SizedBox(height: 18),
    Container(width: 75, height: 1, color: Colors.black),
    const SizedBox(height: 2),
    Text('ФИО и подпись', style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
  ]);
}
