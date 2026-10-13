import 'package:flutter/material.dart';

// ============================================================
// КОНСТАНТЫ ПРИЛОЖЕНИЯ (меняются в одном месте, подхватываются везде)
// ============================================================
const String nazvanieProekta = 'УчВерсии';
const String podzagolovok = 'Версии учебных проектов и история изменений';
const Color osnovnoyCvet = Color(0xFF3F51B5);
const IconData znachokPrilozheniya = Icons.history_edu;
const String imyaObyekta = 'проект';
const String imyaObyektovMnozhestvo = 'Проекты';
const String frazaGlavnoy =
    'Создавайте учебные проекты, фиксируйте версии с комментариями '
    'и смотрите, как менялась ваша работа.';

void main() => runApp(const PrilozhenieKorn());

// ============================================================
// МОДЕЛИ
// ============================================================
class Polzovatel {
  final String imya;
  final String pochta;
  final String parol;
  final String gruppa; // своё поле 1
  final int kurs; // своё поле 2
  const Polzovatel({
    required this.imya,
    required this.pochta,
    required this.parol,
    required this.gruppa,
    required this.kurs,
  });
}

class Versiya {
  final String soobshchenie;
  final DateTime vremya;
  Versiya(this.soobshchenie) : vremya = DateTime.now();
}

class Zapis {
  final String vladelec; // почта автора
  final String nazvanie;
  final String opisanie;
  String status; // 'в работе' или 'выполнен'
  final List<Versiya> versii = [];
  Zapis(this.vladelec, this.nazvanie, this.opisanie, {this.status = 'в работе'});
}

// ============================================================
// ХРАНИЛИЩЕ (только в памяти, пока приложение открыто)
// ============================================================
class Opoveshchatel extends ChangeNotifier {
  void soobshchit() => notifyListeners();
}

class Hranilishe {
  static final List<Polzovatel> _polzovateli = [];
  static final List<Zapis> _vse = [];
  static final Opoveshchatel izmeneniya = Opoveshchatel();

  /// Здесь хранится вошедший пользователь.
  static Polzovatel? tekushiy;

  /// Ищет ТОЛЬКО по почте (пароль проверяется отдельно).
  static Polzovatel? naytiPoPochte(String pochta) {
    final p = pochta.trim().toLowerCase();
    for (final u in _polzovateli) {
      if (u.pochta == p) return u;
    }
    return null;
  }

  static void zaregistrirovat({
    required String imya,
    required String pochta,
    required String parol,
    required String gruppa,
    required int kurs,
  }) {
    _polzovateli.add(Polzovatel(
      imya: imya.trim(),
      pochta: pochta.trim().toLowerCase(),
      parol: parol,
      gruppa: gruppa.trim(),
      kurs: kurs,
    ));
  }

  /// Записи ТОЛЬКО вошедшего пользователя: у второго аккаунта список свой.
  static List<Zapis> get zapisi =>
      _vse.where((z) => z.vladelec == tekushiy?.pochta).toList();

  static void dobavitZapis(String nazvanie, String opisanie) {
    final z = Zapis(tekushiy!.pochta, nazvanie.trim(), opisanie.trim());
    z.versii.add(Versiya('Первоначальная версия'));
    _vse.add(z);
    izmeneniya.soobshchit();
  }

  static void dobavitVersiyu(Zapis z, String soobshchenie) {
    z.versii.add(Versiya(soobshchenie.trim()));
    izmeneniya.soobshchit();
  }

  static void smenitStatus(Zapis z) {
    z.status = z.status == 'выполнен' ? 'в работе' : 'выполнен';
    izmeneniya.soobshchit();
  }
}

String formatVremeni(DateTime t) {
  String d(int n) => n.toString().padLeft(2, '0');
  return '${d(t.day)}.${d(t.month)}.${t.year} ${d(t.hour)}:${d(t.minute)}';
}

// ============================================================
// КОРЕНЬ ПРИЛОЖЕНИЯ
// ============================================================
class PrilozhenieKorn extends StatelessWidget {
  const PrilozhenieKorn({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nazvanieProekta,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: osnovnoyCvet),
        useMaterial3: true,
      ),
      home: const VhodEkran(),
    );
  }
}

// ============================================================
// ЭКРАН ВХОДА
// ============================================================
class VhodEkran extends StatefulWidget {
  const VhodEkran({super.key});

  @override
  State<VhodEkran> createState() => _VhodEkranState();
}

class _VhodEkranState extends State<VhodEkran> {
  final _forma = GlobalKey<FormState>();
  final _pochta = TextEditingController();
  final _parol = TextEditingController();
  String? _oshibkaVhoda;

  @override
  void dispose() {
    _pochta.dispose();
    _parol.dispose();
    super.dispose();
  }

  void _voyti() {
    setState(() => _oshibkaVhoda = null);
    if (!_forma.currentState!.validate()) return;

    // Проверка 1: есть ли пользователь с такой почтой
    final u = Hranilishe.naytiPoPochte(_pochta.text);
    if (u == null) {
      setState(() =>
          _oshibkaVhoda = 'Пользователь с такой почтой не зарегистрирован');
      return;
    }
    // Проверка 2: совпадает ли пароль
    if (u.parol != _parol.text) {
      setState(() => _oshibkaVhoda = 'Неверный пароль');
      return;
    }
    // Обе прошли: запоминаем вошедшего и идём на главную
    Hranilishe.tekushiy = u;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GlavnyyEkran()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _forma,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(znachokPrilozheniya, size: 72, color: cs.primary),
                    const SizedBox(height: 8),
                    Text(nazvanieProekta,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(podzagolovok, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _pochta,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Почта', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Введите почту'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _parol,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Пароль', border: OutlineInputBorder()),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Введите пароль' : null,
                    ),
                    if (_oshibkaVhoda != null) ...[
                      const SizedBox(height: 12),
                      Text(_oshibkaVhoda!, style: TextStyle(color: cs.error)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: _voyti, child: const Text('Войти')),
                    ),
                    TextButton(
                      onPressed: () async {
                        final pochta = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                              builder: (_) => const RegistraciyaEkran()),
                        );
                        if (pochta != null) {
                          setState(() {
                            _pochta.text = pochta;
                            _parol.clear();
                            _oshibkaVhoda = null;
                          });
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Регистрация выполнена. Войдите.')),
                          );
                        }
                      },
                      child: const Text('Нет аккаунта? Зарегистрироваться'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ЭКРАН РЕГИСТРАЦИИ
// Каждое своё поле живёт в четырёх местах:
// 1) TextEditingController  2) TextFormField + validator
// 3) класс Polzovatel       4) вызов Hranilishe.zaregistrirovat
// ============================================================
class RegistraciyaEkran extends StatefulWidget {
  const RegistraciyaEkran({super.key});

  @override
  State<RegistraciyaEkran> createState() => _RegistraciyaEkranState();
}

class _RegistraciyaEkranState extends State<RegistraciyaEkran> {
  final _forma = GlobalKey<FormState>();
  final _imya = TextEditingController();
  final _pochta = TextEditingController();
  final _parol = TextEditingController();
  final _gruppa = TextEditingController(); // своё поле 1
  final _kurs = TextEditingController(); // своё поле 2
  String? _oshibka;

  @override
  void dispose() {
    for (final c in [_imya, _pochta, _parol, _gruppa, _kurs]) {
      c.dispose();
    }
    super.dispose();
  }

  void _zaregistrirovatsya() {
    setState(() => _oshibka = null);
    if (!_forma.currentState!.validate()) return;
    if (Hranilishe.naytiPoPochte(_pochta.text) != null) {
      setState(() => _oshibka = 'Пользователь с такой почтой уже есть');
      return;
    }
    Hranilishe.zaregistrirovat(
      imya: _imya.text,
      pochta: _pochta.text,
      parol: _parol.text,
      gruppa: _gruppa.text,
      kurs: int.parse(_kurs.text.trim()),
    );
    Navigator.of(context).pop(_pochta.text.trim().toLowerCase());
  }

  Widget _pole(TextEditingController c, String metka,
      String? Function(String?) validator,
      {bool skryt = false, TextInputType? tip}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: skryt,
        keyboardType: tip,
        decoration:
            InputDecoration(labelText: metka, border: const OutlineInputBorder()),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _forma,
                child: Column(
                  children: [
                    _pole(_imya, 'Имя',
                        (v) => (v == null || v.trim().isEmpty) ? 'Введите имя' : null),
                    _pole(_pochta, 'Почта', (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите почту';
                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(v.trim());
                      return ok ? null : 'Введите почту в виде name@mail.ru';
                    }, tip: TextInputType.emailAddress),
                    _pole(_gruppa, 'Учебная группа (например, ИС-21)', (v) {
                      return (v == null || v.trim().isEmpty)
                          ? 'Введите учебную группу'
                          : null;
                    }),
                    _pole(_kurs, 'Курс (1–6)', (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите курс';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1 || n > 6) {
                        return 'Курс — целое число от 1 до 6';
                      }
                      return null;
                    }, tip: TextInputType.number),
                    _pole(_parol, 'Пароль (не короче 4 символов)', (v) {
                      return (v == null || v.length < 4)
                          ? 'Пароль не короче 4 символов'
                          : null;
                    }, skryt: true),
                    if (_oshibka != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_oshibka!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: _zaregistrirovatsya,
                          child: const Text('Зарегистрироваться')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ГЛАВНЫЙ ЭКРАН С НИЖНЕЙ НАВИГАЦИЕЙ
// ============================================================
class GlavnyyEkran extends StatefulWidget {
  const GlavnyyEkran({super.key});

  @override
  State<GlavnyyEkran> createState() => _GlavnyyEkranState();
}

class _GlavnyyEkranState extends State<GlavnyyEkran> {
  int _tekushiy = 0;

  static const _stranicy = [
    GlavnayaStranica(),
    SpisokStranica(),
    ProfilStranica(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(nazvanieProekta),
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(index: _tekushiy, children: _stranicy),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tekushiy,
        onTap: (i) => setState(() => _tekushiy = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Обзор',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open_outlined),
            activeIcon: Icon(Icons.folder),
            label: imyaObyektovMnozhestvo,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Студент',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// СТРАНИЦА 1: ОБЗОР (показатели считаются из данных)
// ============================================================
class GlavnayaStranica extends StatelessWidget {
  const GlavnayaStranica({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Hranilishe.izmeneniya,
      builder: (context, _) {
        final vsego = Hranilishe.zapisi.length;
        final vypolneno =
            Hranilishe.zapisi.where((z) => z.status == 'выполнен').length;
        final vRabote = vsego - vypolneno;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Здравствуйте, ${Hranilishe.tekushiy!.imya}!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(frazaGlavnoy),
            const SizedBox(height: 16),
            Row(
              children: [
                _Plitka(znachenie: vsego, podpis: 'Всего проектов'),
                _Plitka(znachenie: vRabote, podpis: 'В работе'),
                _Plitka(znachenie: vypolneno, podpis: 'Выполнено'),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(vsego == 0
                    ? 'Первое действие'
                    : 'Следующее действие'),
                subtitle: Text(vsego == 0
                    ? 'Откройте раздел «$imyaObyektovMnozhestvo» и создайте '
                        'первый $imyaObyekta, например «Курсовая по базам данных».'
                    : 'Откройте $imyaObyekta и зафиксируйте новую версию '
                        'с комментарием о том, что изменилось.'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Plitka extends StatelessWidget {
  final int znachenie;
  final String podpis;
  const _Plitka({required this.znachenie, required this.podpis});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text('$znachenie',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(podpis, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// СТРАНИЦА 2: ПРОЕКТЫ (список, добавление)
// ============================================================
class SpisokStranica extends StatelessWidget {
  const SpisokStranica({super.key});

  Future<void> _dobavit(BuildContext context) async {
    final nazv = TextEditingController();
    final opis = TextEditingController();
    final forma = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый проект'),
        content: Form(
          key: forma,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nazv,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Введите название проекта'
                    : null,
              ),
              TextFormField(
                controller: opis,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () {
                if (forma.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Создать')),
        ],
      ),
    );
    if (ok == true) Hranilishe.dobavitZapis(nazv.text, opis.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: Hranilishe.izmeneniya,
        builder: (context, _) {
          final spisok = Hranilishe.zapisi;
          if (spisok.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'Проектов пока нет. Нажмите «+», чтобы создать первый.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: spisok.length,
            itemBuilder: (context, i) {
              final z = spisok[i];
              return Card(
                child: ListTile(
                  leading: Icon(z.status == 'выполнен'
                      ? Icons.check_circle
                      : Icons.edit_note),
                  title: Text(z.nazvanie),
                  subtitle:
                      Text('Версий: ${z.versii.length} · ${z.status}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ZapisEkran(zapis: z)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _dobavit(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// ЭКРАН ПРОЕКТА: история версий, фиксация, смена статуса
// ============================================================
class ZapisEkran extends StatelessWidget {
  final Zapis zapis;
  const ZapisEkran({super.key, required this.zapis});

  Future<void> _novayaVersiya(BuildContext context) async {
    final c = TextEditingController();
    final forma = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Зафиксировать версию'),
        content: Form(
          key: forma,
          child: TextFormField(
            controller: c,
            decoration:
                const InputDecoration(labelText: 'Что изменилось?'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Опишите изменения, это обязательно'
                : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () {
                if (forma.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok == true) Hranilishe.dobavitVersiyu(zapis, c.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(zapis.nazvanie)),
      body: ListenableBuilder(
        listenable: Hranilishe.izmeneniya,
        builder: (context, _) {
          final istoriya = zapis.versii.reversed.toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (zapis.opisanie.isNotEmpty) Text(zapis.opisanie),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(label: Text(zapis.status)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Hranilishe.smenitStatus(zapis),
                    child: Text(zapis.status == 'выполнен'
                        ? 'Вернуть в работу'
                        : 'Отметить выполненным'),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text('История изменений',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < istoriya.length; i++)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text('${istoriya.length - i}')),
                    title: Text(istoriya[i].soobshchenie),
                    subtitle: Text(formatVremeni(istoriya[i].vremya)),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _novayaVersiya(context),
        icon: const Icon(Icons.save),
        label: const Text('Новая версия'),
      ),
    );
  }
}

// ============================================================
// СТРАНИЦА 3: ПРОФИЛЬ
// ============================================================
class ProfilStranica extends StatelessWidget {
  const ProfilStranica({super.key});

  Widget _karta(IconData znachok, String podpis, String znachenie) => Card(
        child: ListTile(
          leading: Icon(znachok),
          title: Text(znachenie),
          subtitle: Text(podpis),
        ),
      );

  void _vyyti(BuildContext context) {
    Hranilishe.tekushiy = null;
    // Очищаем весь стек, поэтому кнопка «назад» не вернёт в приложение
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const VhodEkran()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = Hranilishe.tekushiy!;
    return ListenableBuilder(
      listenable: Hranilishe.izmeneniya,
      builder: (context, _) {
        final zapisi = Hranilishe.zapisi;
        final versiy =
            zapisi.fold<int>(0, (summa, z) => summa + z.versii.length);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _karta(Icons.person, 'Имя', u.imya),
            _karta(Icons.email_outlined, 'Почта', u.pochta),
            _karta(Icons.groups_outlined, 'Учебная группа', u.gruppa),
            _karta(Icons.school_outlined, 'Курс', '${u.kurs}'),
            _karta(Icons.history, 'Показатель работы',
                'Проектов: ${zapisi.length}, зафиксировано версий: $versiy'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _vyyti(context),
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
            ),
          ],
        );
      },
    );
  }
}
